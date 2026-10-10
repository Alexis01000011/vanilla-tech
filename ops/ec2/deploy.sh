#!/bin/bash
# deploy.sh — Despliega una release publicada e inmutable en el servidor Vanilla Tech.
#
#   deploy.sh VERSION SHA256 [--kick-players] [--allow-downgrade] [--allow-loader-change]
#
# VERSION y SHA256 identifican el .mrpack de $VT_RELEASE_URL/releases/VERSION/; el SHA256 viene del
# pipeline (no del mismo servidor web), así que una descarga alterada se rechaza.
# Orden: preparar (sin tocar el server) -> lock de mantenimiento -> jugadores -> detener -> backup
# verificado -> activar el pack -> arrancar -> healthcheck -> registrar. Si algo falla después de
# activar el pack, restaura el backup completo (mundo + archivos + pack anterior) y vuelve a arrancar.
#
# Códigos de salida: 0 ok/ya activo · 1 error sin cambios en el server · 2 falló y se revirtió ·
# 3 falló y la reversión también (intervención manual) · 10 hay jugadores · 11 lock ocupado ·
# 12 cambio de Minecraft/NeoForge sin autorización · 13 downgrade sin --allow-downgrade
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

V=${1:-}; SHA=${2:-}; shift 2 || true
KICK=0; ALLOW_DOWN=0; ALLOW_LOADER=0
for a in "$@"; do
  case "$a" in
    --kick-players) KICK=1 ;; --allow-downgrade) ALLOW_DOWN=1 ;; --allow-loader-change) ALLOW_LOADER=1 ;;
    *) die "opción desconocida: $a" ;;
  esac
done
[[ "$V" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-(alpha|beta|rc)\.[0-9]+)?$ ]] || die "versión inválida: '$V'"
[[ "$SHA" =~ ^[0-9a-f]{64}$ ]] || die "sha256 inválido"
[ -n "$VT_RELEASE_URL" ] || die "VT_RELEASE_URL no está configurado en $VT_CONF"

mkdir -p "$VT_LOG_DIR" "$VT_STATE/releases"
LOG="$VT_LOG_DIR/$(date -u +%Y%m%dT%H%M%SZ)-deploy-$V.log"
exec > >(tee -a "$LOG") 2>&1
T0=$(now); PHASE=init; SNAP=; PREV=$(current_pack_version); WAS_RUNNING=0; HEALTH=
log "deploy $V (sha256 $SHA) — activo: $PREV — log: $LOG"

# ---------------------------------------------------------------- 1. preparar (sin efectos en el server)
if [ -f "$VT_MODPACK" ] && [ "$(sha256_of "$VT_MODPACK")" = "$SHA" ]; then
  log "$V ya es la release activa (mismo sha256); nada que hacer"; exit 0
fi
REL="$VT_STATE/releases/$V"; MR="$REL/vanilla-tech-$V.mrpack"; mkdir -p "$REL"
if [ ! -f "$MR" ] || [ "$(sha256_of "$MR")" != "$SHA" ]; then
  proto='=https'; [ "${VT_ALLOW_HTTP:-0}" = 1 ] && proto='=https,http'
  curl -fsSL --proto "$proto" --retry 4 --retry-delay 3 --max-time 300 \
    -o "$MR.part" "$VT_RELEASE_URL/releases/$V/vanilla-tech-$V.mrpack" || die "no pude descargar la release $V"
  [ "$(sha256_of "$MR.part")" = "$SHA" ] || { rm -f "$MR.part"; die "el sha256 descargado no coincide con el del pipeline"; }
  mv -f "$MR.part" "$MR"
fi
loader_opt=(--expect-neoforge "$(current_neoforge 2>/dev/null || echo none)")
{ [ "$ALLOW_LOADER" = 1 ] || [ ! -f "$VT_MODPACK" ]; } && loader_opt=()
$PY mrpack-info "$MR" --expect-version "$V" "${loader_opt[@]}" || exit $?
if [ "$PREV" != unknown ]; then
  c=$($PY vercmp "$V" "$PREV")
  [ "$c" = 0 ] && die "la versión $V ya está activa con otro contenido: las releases son inmutables, revisa el sitio"
  [ "$c" = -1 ] && [ "$ALLOW_DOWN" = 0 ] && die "$V es anterior a $PREV: usa rollback.sh, o --allow-downgrade si sabes que el mundo lo tolera" 13
fi
log "descargando y verificando los archivos de servidor de $V"
$PY prefetch "$MR" "$VT_STATE/cache" "$VT_DATA" || die "faltan archivos o hashes inválidos; el server no se tocó"

# ---------------------------------------------------------------- 2. lock + jugadores
on_exit() {
  local rc=$? out
  set +e
  if [ "$rc" -ne 0 ]; then
    case "$PHASE" in
      stopping|stopped|snapshotted)
        log "falló antes de cambiar el pack ($PHASE); el mundo no se modificó"
        if [ "$WAS_RUNNING" = 1 ]; then
          s=$(now); rt_start
          if "$CD_DIR/healthcheck.sh" --since "$s" --expect-version "$PREV"; then log "servidor anterior arrancado de nuevo"
          else log "ERROR: el servidor anterior no arrancó"; rc=3; fi
        fi ;;
      applied|started)
        log "REVERSIÓN: restaurando el backup $SNAP (mundo, archivos y pack $PREV)"
        out=$( { rt_stop; for _ in $(seq 1 90); do rt_running || break; sleep 2; done; } 2>&1 ); [ -n "$out" ] && log "$out"
        if ( snapshot_restore "$SNAP" ); then
          s=$(now); rt_start
          if "$CD_DIR/healthcheck.sh" --since "$s" --expect-version "$PREV"; then
            log "revertido a $PREV"; rc=2; record_history deploy "$V" rolled-back snapshot="$SNAP" phase="$PHASE"
          else log "ERROR: tras revertir, el servidor no está sano"; rc=3; fi
        else log "ERROR: no se pudo restaurar $SNAP"; rc=3; fi ;;
    esac
    [ "$rc" = 3 ] && record_history deploy "$V" failed-manual snapshot="$SNAP" phase="$PHASE"
    [ "$rc" = 3 ] && log "INTERVENCIÓN MANUAL: ver $LOG; backups en $VT_BACKUPS"
  fi
  [ "$PHASE" != init ] && release_lock
  log "fin: código $rc en $(( $(now) - T0 )) s"
  exit "$rc"
}
trap on_exit EXIT
acquire_lock; PHASE=locked; maintenance_on "deploy $V"

if rt_active || rt_running; then
  WAS_RUNNING=1
  if ! server_ready_now; then
    log "el servidor está arrancando; espero a que acepte comandos"
    wait_for_ready 600 || die "el servidor actual no responde por RCON; revisa antes de desplegar"
  fi
  P=$(players_online) || die "no pude consultar los jugadores"
  if [ "$P" -gt 0 ]; then
    [ "$KICK" = 1 ] || die "hay $P jugador(es) conectados; reintenta cuando salgan (o --kick-players con su acuerdo)" 10
    rt_rcon "say Actualización a $V: el servidor se reinicia en 60 s (vuelve en unos minutos)" || true
    sleep 50; rt_rcon "say Reinicio en 10 s" || true; sleep 10
  fi
fi

# ---------------------------------------------------------------- 3-4. detener + backup
PHASE=stopping; stop_server; PHASE=stopped
SNAP=$(snapshot_create "pre-deploy $V"); PHASE=snapshotted
offsite_backup

# ---------------------------------------------------------------- 5-6. activar + arrancar + salud
PHASE=applied; set_pack_pointer "$MR" "$V"
S=$(now); rt_start; PHASE=started
HEALTH=$("$CD_DIR/healthcheck.sh" --since "$S" --expect-version "$V" | tail -n1) || die "healthcheck falló: ${HEALTH:-sin salida}"
PHASE=healthy

# ---------------------------------------------------------------- 7. registrar
$PY snapshot-meta "$VT_STATE/active-release.json" version="$V" sha256="$SHA" deployed_at="$(date -u +%FT%TZ)" \
  previous_version="$PREV" snapshot_before="$SNAP" health="${HEALTH#HEALTH }" log="$LOG"
record_history deploy "$V" ok previous="$PREV" snapshot="$SNAP" seconds="$(( $(now) - T0 ))"
snapshot_prune "$SNAP"
log "OK: $PREV -> $V en $(( $(now) - T0 )) s; backup previo: $SNAP"
echo "RESULT {\"result\":\"ok\",\"version\":\"$V\",\"previous\":\"$PREV\",\"snapshot\":\"$SNAP\"}"
