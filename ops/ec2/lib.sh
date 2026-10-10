#!/bin/bash
# lib.sh — shared by deploy.sh, rollback.sh, healthcheck.sh, status.sh and drill.sh.
# Production runtime: systemd unit vanilla-tech.service running itzg/minecraft-server in docker
# (container "mc"). Local tests replace the rt_* functions through VT_RUNTIME_HOOKS.
set -euo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

CD_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VT_CONF=${VT_CONF:-$CD_DIR/cd.env}
# shellcheck source=/dev/null
[ -f "$VT_CONF" ] && . "$VT_CONF"
: "${VT_BASE:=/opt/vanilla-tech}"
: "${VT_DATA:=$VT_BASE/data}"
: "${VT_MODPACK:=$VT_BASE/modpacks/vanilla-tech.mrpack}"
: "${VT_STATE:=$VT_BASE/cd-state}"
: "${VT_BACKUPS:=$VT_BASE/backups}"
: "${VT_LOG_DIR:=/var/log/vanilla-tech-cd}"
: "${VT_SERVICE:=vanilla-tech}"
: "${VT_CONTAINER:=mc}"
: "${VT_PORT:=25565}"
: "${VT_REGION:=us-east-1}"
: "${VT_BUCKET:=}"                 # empty: do not touch S3 (local tests)
: "${VT_RELEASE_URL:=}"            # https://<owner>.github.io/<repo>
: "${VT_KEEP_SNAPSHOTS:=3}"
: "${VT_HEALTH_TIMEOUT:=900}"
: "${VT_MIN_FREE_MB:=2048}"
: "${VT_MAINT:=/var/run/vanilla-tech-maintenance}"
: "${VT_OFFSITE_BACKUP:=$VT_BASE/backup.sh}"   # existing S3 world backup; empty to skip
: "${VT_IDLE_FILES:=/var/run/vanilla-tech-idle-since /var/run/vanilla-tech-rcon-fail-since}"
PY="python3 $CD_DIR/mc_tools.py"
[ "$VT_KEEP_SNAPSHOTS" -ge 2 ] || VT_KEEP_SNAPSHOTS=2

log() { echo "$(date -u +%H:%M:%S) $*" >&2; }   # stderr: stdout is reserved for values
die() { local code=${2:-1}; log "ERROR: $1"; exit "$code"; }
now() { date +%s; }

# ---------------------------------------------------------------- runtime (production defaults)
rt_start()   { systemctl start "$VT_SERVICE"; }
rt_stop()    { systemctl stop "$VT_SERVICE"; }
rt_active()  { systemctl is-active --quiet "$VT_SERVICE"; }
rt_running() { [ -n "$(docker ps -q -f "name=^${VT_CONTAINER}\$" 2>/dev/null)" ]; }
rt_rcon()    { docker exec "$VT_CONTAINER" rcon-cli "$@"; }
# itzg/installer errors happen before Minecraft writes logs/latest.log
rt_console_since() { docker logs --since "@$1" "$VT_CONTAINER" 2>&1 || true; }
# shellcheck source=/dev/null
[ -n "${VT_RUNTIME_HOOKS:-}" ] && . "$VT_RUNTIME_HOOKS"

players_online() {   # prints count; returns 1 if the server cannot be asked
  local out
  out=$(rt_rcon list 2>/dev/null) || return 1
  $PY players "$out" 2>/dev/null
}

server_ready_now() { local p; p=$(players_online) && [ -n "$p" ]; }

wait_for_ready() {   # the server was already running (e.g. instance just booted): wait for it to settle
  local deadline=$(( $(now) + ${1:-600} ))
  while [ "$(now)" -lt "$deadline" ]; do server_ready_now && return 0; sleep 5; done
  return 1
}

stop_server() {
  log "deteniendo $VT_SERVICE"
  rt_stop
  for _ in $(seq 1 90); do rt_running || break; sleep 2; done
  rt_running && die "el servidor sigue corriendo tras detenerlo"
  $PY quiescent "$VT_DATA" 5 >/dev/null || die "algo sigue escribiendo en $VT_DATA"
  log "servidor detenido; el mundo ya no se escribe"
}

# ---------------------------------------------------------------- lock + maintenance flag
acquire_lock() {   # fails (exit 11) without side effects if another deploy/rollback holds it
  mkdir -p "$VT_STATE"
  exec 9>"$VT_STATE/lock"
  flock -n 9 || die "otro deploy/rollback está en curso" 11
}

maintenance_on() {   # idle-shutdown.sh skips its cycle while $VT_MAINT exists (and is < 3 h old)
  mkdir -p "$(dirname "$VT_MAINT")"
  echo "$$ ${1:-cd} $(date -u +%FT%TZ)" > "$VT_MAINT"
  # An idle shutdown that already started would race with us: wait for it, abort if the box is going down.
  for _ in $(seq 1 60); do
    pgrep -f "$VT_BASE/(backup|idle-shutdown)\.sh" >/dev/null 2>&1 || break; sleep 5
  done
  if command -v systemctl >/dev/null && [ "$(systemctl is-system-running 2>/dev/null || true)" = stopping ]; then
    die "la instancia se está apagando"
  fi
}

release_lock() {
  rm -f "$VT_MAINT"
  # Restart the idle countdown so players get the full 10 minutes to join after a deploy.
  local f; for f in $VT_IDLE_FILES; do rm -f "$f"; done
  flock -u 9 2>/dev/null || true
}

# ---------------------------------------------------------------- active release record
active_field() { python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get(sys.argv[2]) or "")' "$VT_STATE/active-release.json" "$1" 2>/dev/null || true; }
current_pack_version() { python3 -c 'import json,sys,zipfile;print(json.load(zipfile.ZipFile(sys.argv[1]).open("modrinth.index.json"))["versionId"])' "$VT_MODPACK" 2>/dev/null || echo unknown; }
current_neoforge() { python3 -c 'import json,sys,zipfile;print(json.load(zipfile.ZipFile(sys.argv[1]).open("modrinth.index.json"))["dependencies"]["neoforge"])' "$VT_MODPACK"; }
sha256_of() { sha256sum "$1" | cut -d' ' -f1; }

record_history() {   # record_history ACTION VERSION RESULT [k=v...]
  local action=$1 version=$2 result=$3; shift 3
  python3 - "$VT_STATE/history.jsonl" "$action" "$version" "$result" "$@" <<'PY'
import json,sys,time
f,action,version,result=sys.argv[1:5];e={"at":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()),"action":action,"version":version,"result":result}
for kv in sys.argv[5:]:
    k,_,v=kv.partition("=")
    try:e[k]=json.loads(v)
    except ValueError:e[k]=v
open(f,"a").write(json.dumps(e,sort_keys=True)+"\n")
PY
}

# ---------------------------------------------------------------- modpack pointer (local + S3)
# vanilla-tech.service runs sync-modpack.sh before every start, which copies the S3 "current" object over
# the local file. Both must therefore point at the same release, or the next boot would switch packs.
set_pack_pointer() {   # set_pack_pointer FILE VERSION
  local f=$1 v=$2 sha; sha=$(sha256_of "$f")
  if [ -n "$VT_BUCKET" ]; then
    aws s3 cp "$f" "s3://$VT_BUCKET/modpack/releases/vanilla-tech-$v.mrpack" --region "$VT_REGION" --only-show-errors
    aws s3 cp "$f" "s3://$VT_BUCKET/modpack/vanilla-tech.mrpack" --region "$VT_REGION" --only-show-errors \
      --metadata "pack-version=$v,sha256=$sha"
  fi
  install -m 644 "$f" "$VT_MODPACK.new" && mv -f "$VT_MODPACK.new" "$VT_MODPACK"
  log "pack activo -> $v ($sha)"
}

# ---------------------------------------------------------------- snapshots
compressor() { if command -v zstd >/dev/null; then echo zst; else echo gz; fi; }

snapshot_create() {   # snapshot_create REASON -> prints snapshot id
  local reason=$1 ver id dir ext need avail t0
  ver=$(current_pack_version); id="$(date -u +%Y%m%dT%H%M%SZ)-$ver"; dir="$VT_BACKUPS/$id"
  mkdir -p "$VT_BACKUPS"; t0=$(now)
  need=$(du -sm --exclude=logs --exclude=crash-reports "$VT_DATA" | cut -f1)
  avail=$(df -Pm "$VT_BACKUPS" | awk 'NR==2{print $4}')
  [ "$avail" -gt $(( need + VT_MIN_FREE_MB )) ] || die "espacio insuficiente para el backup: ${avail} MiB libres, se necesitan $((need + VT_MIN_FREE_MB))"
  ext=$(compressor); mkdir -p "$dir.partial"
  if [ "$ext" = zst ]; then
    tar -C "$VT_DATA" --exclude=./logs --exclude=./crash-reports -cf - . | zstd -q -T0 -3 -o "$dir.partial/data.tar.zst"
    zstd -q -t "$dir.partial/data.tar.zst"
  else
    tar -C "$VT_DATA" --exclude=./logs --exclude=./crash-reports -czf "$dir.partial/data.tar.gz" .
    gzip -t "$dir.partial/data.tar.gz"
  fi
  [ -f "$VT_MODPACK" ] && cp -p "$VT_MODPACK" "$dir.partial/modpack.mrpack"
  ( cd "$dir.partial" && sha256sum -- * > SHA256SUMS )
  $PY snapshot-meta "$dir.partial/meta.json" id="$id" reason="$reason" pack_version="$ver" \
    created_at="$(date -u +%FT%TZ)" data_mb="$need" seconds="$(( $(now) - t0 ))" \
    archive="data.tar.$ext" archive_sha256="$(sha256_of "$dir.partial/data.tar.$ext")"
  mv "$dir.partial" "$dir"
  log "backup $id listo ($(du -sh "$dir" | cut -f1), $(( $(now) - t0 )) s)"
  echo "$id"
}

snapshot_verify() {   # integrity of a snapshot directory (checksums + archive test + level.dat present)
  local dir="$VT_BACKUPS/$1" a
  [ -f "$dir/meta.json" ] || die "no existe el backup $1"
  ( cd "$dir" && sha256sum -c --quiet SHA256SUMS ) || die "checksums inválidos en $1"
  a=$(ls "$dir"/data.tar.*)
  # grep -c reads the whole listing: grep -q would close the pipe early and, under pipefail, the
  # SIGPIPE'd tar would turn a good archive into a failed check.
  # The archive bytes were already checked against SHA256SUMS above.
  local n
  case "$a" in
    *.zst) n=$(zstd -q -dc "$a" | tar -tf - | grep -cx './world/level.dat' || true) ;;
    *.gz)  n=$(tar -tzf "$a" | grep -cx './world/level.dat' || true) ;;
  esac
  [ "${n:-0}" -ge 1 ] || die "el backup $1 no contiene world/level.dat (o no se pudo listar)"
}

snapshot_restore() {   # snapshot_restore ID: moves the live data dir aside and extracts the snapshot
  local id=$1 dir="$VT_BACKUPS/$1" aside a
  snapshot_verify "$id"
  rt_running && die "no se restaura con el servidor corriendo"
  aside="$VT_BASE/failed/$(date -u +%Y%m%dT%H%M%SZ)-replaced-by-$id"
  mkdir -p "$VT_BASE/failed"
  mv "$VT_DATA" "$aside"
  install -d -m "$(stat -c %a "$aside")" -o "$(stat -c %u "$aside")" -g "$(stat -c %g "$aside")" "$VT_DATA"
  a=$(ls "$dir"/data.tar.*)
  case "$a" in
    *.zst) zstd -q -dc "$a" | tar -C "$VT_DATA" -xpf - ;;
    *.gz)  tar -C "$VT_DATA" -xzpf "$a" ;;
  esac
  set_pack_pointer "$dir/modpack.mrpack" "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["pack_version"])' "$dir/meta.json")"
  log "restaurado $id; los datos reemplazados quedaron en $aside"
}

snapshot_list() {   # complete snapshots, oldest first (ids sort by time)
  local d
  for d in "$VT_BACKUPS"/[0-9]*T[0-9]*Z-*; do
    if [ -f "$d/meta.json" ] && [[ "${d##*/}" =~ ^[0-9]{8}T[0-9]{6}Z-[A-Za-z0-9.+-]+$ ]]; then echo "${d##*/}"; fi
  done | sort
}

snapshot_prune() {   # keep the newest VT_KEEP_SNAPSHOTS plus any id passed as argument
  local keep=" $* " id
  for id in $(snapshot_list | head -n -"$VT_KEEP_SNAPSHOTS"); do
    case "$keep" in *" $id "*) continue ;; esac
    [[ "$id" =~ ^[0-9]{8}T[0-9]{6}Z-[A-Za-z0-9.+-]+$ ]] || continue
    rm -rf -- "${VT_BACKUPS:?}/$id"; log "backup antiguo eliminado: $id"
  done
  # Data dirs moved aside by failed deploys/rollbacks: keep the two newest for diagnosis.
  for id in $(ls -1 "$VT_BASE/failed" 2>/dev/null | sort | head -n -2); do
    [[ "$id" =~ ^[0-9]{8}T[0-9]{6}Z- ]] && rm -rf -- "${VT_BASE:?}/failed/$id"
  done
  rm -rf -- "${VT_BACKUPS:?}"/*.partial 2>/dev/null || true
}

offsite_backup() {   # existing S3 world backup (versioned bucket); never fatal
  [ -n "$VT_OFFSITE_BACKUP" ] && [ -x "$VT_OFFSITE_BACKUP" ] || return 0
  "$VT_OFFSITE_BACKUP" || log "AVISO: falló la copia externa a S3 (el backup local sí existe)"
}
