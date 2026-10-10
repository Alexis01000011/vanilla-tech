#!/bin/bash
# e2e-local.sh — Prueba de punta a punta de ops/ec2 (deploy, reversión automática, rollback, backups)
# contra un NeoForge real con el modpack real, sin AWS, sin docker y sin root.
#
#   e2e-local.sh WORKDIR MIH_BIN EXCLUDES_JSON R1_ROOT R1_MRPACK R2_DIR R3_DIR OLD_ROOT OLD_MRPACK
#
# R1 = release "en producción"; R2 = cambio de servidor (config + mod quitado); R3 = release rota
# (falta una dependencia: NeoForge no carga); OLD = release anterior (para el rechazo de downgrade).
# R2_DIR/R3_DIR vienen de scripts/tests/make-variant.py (tree/ + .mrpack).
set -uo pipefail
W=$1 MIH=$2 EXCLUDES=$3 R1_ROOT=$4 R1_MR=$5 R2=$6 R3=$7 OLD_ROOT=$8 OLD_MR=$9
REPO=$(cd -- "$(dirname -- "$0")/../.." && pwd)
rm -rf "$W"; mkdir -p "$W/opt/modpacks" "$W/opt/data" "$W/run" "$W/log"
RESULTS=$W/results.txt; : > "$RESULTS"
pass() { echo "PASS $*" | tee -a "$RESULTS"; }
fail() { echo "FAIL $*" | tee -a "$RESULTS"; }
check() { local n=$1; shift; if "$@"; then pass "$n"; else fail "$n"; fi; }
expect_rc() { local want=$1 n=$2; shift 2; "$@" > "$W/last.out" 2>&1; local rc=$?
  if [ "$rc" = "$want" ]; then pass "$n (exit $rc)"; else fail "$n (exit $rc, esperado $want)"; tail -n 25 "$W/last.out"; fi; }

# ---------------------------------------------------------------- sitio de releases
SITE=$W/site
python3 "$REPO/scripts/release.py" publish --site "$SITE" --root "$R1_ROOT" --mrpack "$R1_MR" --commit e2e >/dev/null
python3 "$REPO/scripts/release.py" publish --site "$SITE" --root "$OLD_ROOT" --mrpack "$OLD_MR" --commit e2e >/dev/null
for r in "$R2" "$R3"; do
  python3 "$REPO/scripts/release.py" publish --site "$SITE" --root "$r/tree" --mrpack "$(ls "$r"/*.mrpack)" --commit e2e >/dev/null
done
v_of() { python3 -c 'import json,sys,zipfile;print(json.load(zipfile.ZipFile(sys.argv[1]).open("modrinth.index.json"))["versionId"])' "$1"; }
V1=$(v_of "$R1_MR"); V2=$(v_of "$R2"/*.mrpack); V3=$(v_of "$R3"/*.mrpack); VOLD=$(v_of "$OLD_MR")
sha() { sha256sum "$SITE/releases/$1/vanilla-tech-$1.mrpack" | cut -d' ' -f1; }
# release con otro NeoForge (debe exigir autorización)
mkdir -p "$SITE/releases/0.9.0"; python3 - "$R1_MR" "$SITE/releases/0.9.0/vanilla-tech-0.9.0.mrpack" <<'PY'
import json,sys,zipfile
src,dst=sys.argv[1:];zi=zipfile.ZipFile(src);zo=zipfile.ZipFile(dst,'w',zipfile.ZIP_DEFLATED)
for n in zi.namelist():
    b=zi.read(n)
    if n=='modrinth.index.json':
        j=json.loads(b);j['versionId']='0.9.0';j['dependencies']['neoforge']='21.1.999';b=json.dumps(j).encode()
    zo.writestr(n,b)
zo.close()
PY
python3 -u -m http.server 0 --bind 127.0.0.1 --directory "$SITE" > "$W/http.log" 2>&1 & HTTP=$!
trap 'kill $HTTP 2>/dev/null; [ -f "$W/run/container.pid" ] && kill "$(cat "$W/run/container.pid")" 2>/dev/null' EXIT
for _ in $(seq 1 50); do PORT=$(grep -oP 'port \K[0-9]+' "$W/http.log" | head -1); [ -n "$PORT" ] && break; sleep 0.2; done
[ -n "$PORT" ] || { echo "no arrancó el servidor HTTP de prueba"; exit 1; }

# ---------------------------------------------------------------- "instancia": install.sh + config de prueba
cp "$REPO/ops/tests/idle-shutdown.fixture.sh" "$W/opt/idle-shutdown.sh"
expect_rc 0 "install.sh instala y parchea idle-shutdown" \
  bash "$REPO/ops/ec2/install.sh" --release-url https://example.invalid/vt --bucket test-bucket --dest "$W/opt/cd" --base "$W/opt" --log-dir "$W/log"
check "idle-shutdown respeta el flag de mantenimiento" grep -q vanilla-tech-maintenance "$W/opt/idle-shutdown.sh"
expect_rc 0 "install.sh es idempotente" \
  bash "$REPO/ops/ec2/install.sh" --release-url https://example.invalid/vt --bucket test-bucket --dest "$W/opt/cd" --base "$W/opt" --log-dir "$W/log"
check "el parche no se duplica" test "$(grep -c vanilla-tech-maintenance "$W/opt/idle-shutdown.sh")" = 1
write_test_env() {
cat > "$W/opt/cd/cd.env" <<ENV
VT_BASE=$W/opt
VT_DATA=$W/opt/data
VT_MODPACK=$W/opt/modpacks/vanilla-tech.mrpack
VT_PORT=25599
VT_BUCKET=
VT_RELEASE_URL=http://127.0.0.1:$PORT
VT_ALLOW_HTTP=1
VT_LOG_DIR=$W/log
VT_MAINT=$W/run/vanilla-tech-maintenance
VT_IDLE_FILES="$W/run/idle-since $W/run/rcon-fail-since"
VT_OFFSITE_BACKUP=
VT_KEEP_SNAPSHOTS=3
VT_HEALTH_TIMEOUT=600
VT_RUNTIME_HOOKS=$REPO/ops/tests/local-runtime.sh
ENV
}
write_test_env
export VT_TEST_DIR=$W MIH VT_TEST_RCON_PORT=25598 VT_TEST_RCON_PW=e2e-$$ VT_TEST_EXCLUDES=$EXCLUDES
CD=$W/opt/cd
. "$CD/lib.sh"; set +e   # rt_* y helpers para las comprobaciones (lib.sh activa set -e)
rc_() { rt_rcon "$@" 2>/dev/null; }
score() { rc_ "scoreboard players get e2e vtmarker" | grep -oP 'has \K[0-9]+'; }

# ---------------------------------------------------------------- producción simulada con R1
cp "$R1_MR" "$W/opt/modpacks/vanilla-tech.mrpack"
[ -d "$REPO/../vanilla-tech/.cache/server-clean/libraries" ] && cp -r "$REPO/../vanilla-tech/.cache/server-clean/libraries" "$W/opt/data/"
rm -f "$W/opt/cd-state/active-release.json"
bash "$REPO/ops/ec2/install.sh" --release-url https://example.invalid/vt --bucket test-bucket --dest "$W/opt/cd" --base "$W/opt" --log-dir "$W/log" >/dev/null; write_test_env
S=$(now); rt_start
check "arranque inicial de R1 ($V1)" "$CD/healthcheck.sh" --since "$S" --expect-version "$V1"
rc_ "scoreboard objectives add vtmarker dummy" >/dev/null; rc_ "scoreboard players set e2e vtmarker 42" >/dev/null; rc_ "save-all flush" >/dev/null
check "marcador del mundo = 42" test "$(score)" = 42
echo '[{"uuid":"00000000-0000-0000-0000-000000000001","name":"imalexisxo","level":4,"bypassesPlayerLimit":false}]' > "$W/opt/data/ops.json"
ops_names() { python3 -c 'import json,sys;print(sorted((o["name"],o["level"]) for o in json.load(open(sys.argv[1]))))' "$W/opt/data/ops.json"; }
OPS=$(ops_names)   # Minecraft reformatea ops.json al arrancar: se compara el contenido, no los bytes

# ---------------------------------------------------------------- casos que no deben tocar nada
expect_rc 1 "sha256 distinto al del pipeline se rechaza" "$CD/deploy.sh" "$V2" "$(printf '0%.0s' $(seq 64))"
expect_rc 13 "downgrade sin autorización se rechaza" "$CD/deploy.sh" "$VOLD" "$(sha "$VOLD")"
expect_rc 12 "cambio de NeoForge sin autorización se rechaza" "$CD/deploy.sh" 0.9.0 "$(sha256sum "$SITE/releases/0.9.0/vanilla-tech-0.9.0.mrpack" | cut -d' ' -f1)"
expect_rc 1 "versión con caracteres raros se rechaza" "$CD/deploy.sh" '1.0.0;id' "$(sha "$V2")"
expect_rc 0 "desplegar la release ya activa es un no-op" "$CD/deploy.sh" "$V1" "$(sha256sum "$R1_MR" | cut -d' ' -f1)"
expect_rc 10 "con jugadores conectados no despliega" env VT_TEST_FAKE_PLAYERS=1 "$CD/deploy.sh" "$V2" "$(sha "$V2")"
check "el servidor sigue arriba con R1 tras los rechazos" "$CD/healthcheck.sh" --expect-version "$V1"
check "flag de mantenimiento liberado" test ! -f "$W/run/vanilla-tech-maintenance"
exec 8>"$W/opt/cd-state/lock"; flock -n 8
expect_rc 11 "lock ocupado: otro deploy en curso" "$CD/deploy.sh" "$V2" "$(sha "$V2")"
flock -u 8; exec 8>&-

# ---------------------------------------------------------------- deploy correcto R1 -> R2
touch "$W/run/idle-since"
expect_rc 0 "deploy $V1 -> $V2" "$CD/deploy.sh" "$V2" "$(sha "$V2")"
check "pack activo = $V2" test "$(current_pack_version)" = "$V2"
check "mod quitado (Chunky) eliminado del servidor" sh -c "! ls '$W/opt/data/mods/' | grep -qi chunky"
check "config del pack aplicada" grep -q 'e2e: server config change' "$W/opt/data/config/lithium.properties"
check "mundo conservado (marcador 42)" test "$(score)" = 42
check "ops.json conservado" test "$(ops_names)" = "$OPS"
check "contador de inactividad reiniciado" test ! -f "$W/run/idle-since"
SNAP_R2=$(active_field snapshot_before)
check "backup previo registrado ($SNAP_R2)" test -f "$W/opt/backups/$SNAP_R2/meta.json"
rc_ "scoreboard players set e2e vtmarker 43" >/dev/null; rc_ "save-all flush" >/dev/null

# ---------------------------------------------------------------- deploy roto R2 -> R3: reversión automática
expect_rc 2 "deploy roto $V3 se revierte solo" "$CD/deploy.sh" "$V3" "$(sha "$V3")"
check "pack activo vuelve a $V2" test "$(current_pack_version)" = "$V2"
check "servidor sano tras la reversión" "$CD/healthcheck.sh" --expect-version "$V2"
check "mundo intacto tras la reversión (marcador 43)" test "$(score)" = 43
check "datos fallidos apartados para diagnóstico" sh -c "ls -d '$W/opt/failed/'*replaced-by* >/dev/null"
check "historial registra la reversión" grep -q '"rolled-back"' "$W/opt/cd-state/history.jsonl"

# ---------------------------------------------------------------- rollback manual a antes de R2
expect_rc 0 "rollback previous (antes de $V2)" "$CD/rollback.sh" previous
check "pack activo = $V1" test "$(current_pack_version)" = "$V1"
check "Chunky de vuelta" sh -c "ls '$W/opt/data/mods/' | grep -qi chunky"
check "mundo del backup (marcador 42; lo jugado después queda en el backup de seguridad)" test "$(score)" = 42
SAFETY=$(active_field snapshot_before)
check "backup de seguridad del estado previo ($SAFETY)" test -f "$W/opt/backups/$SAFETY/meta.json"

# ---------------------------------------------------------------- deshacer el rollback
expect_rc 0 "deshacer el rollback (rollback a $SAFETY)" "$CD/rollback.sh" "$SAFETY"
check "de vuelta en $V2" test "$(current_pack_version)" = "$V2"
check "con el marcador 43" test "$(score)" = 43

# ---------------------------------------------------------------- backups: ensayo, retención, estado
expect_rc 0 "ensayo de restauración del último backup" "$CD/drill.sh" latest
grep DRILL "$W/last.out" | tail -1
check "retención: como máximo 3 backups + protegidos" test "$(find "$W/opt/backups" -mindepth 1 -maxdepth 1 -name '2*' | wc -l)" -le 5
expect_rc 0 "status.sh" "$CD/status.sh"
python3 -c 'import json,sys;d=json.loads(open(sys.argv[1]).read()[open(sys.argv[1]).read().index("{"):]);print("status:",d["active"]["version"],d["service"],"backups:",len(d["backups"]))' "$W/last.out"

# ---------------------------------------------------------------- idle-shutdown parcheado
mkdir -p "$W/shim"; printf '#!/bin/sh\necho "There are 0 of a max of 4 players online:"\n' > "$W/shim/docker"
printf '#!/bin/sh\necho SHUTDOWN >> %s\n' "$W/shutdown.called" > "$W/shim/shutdown"; chmod +x "$W/shim/"*
sed -e "s|/var/run/|$W/run/|g" -e "s|/opt/vanilla-tech/backup.sh|true|" -e 's|^export PATH=.*|export PATH='"$W"'/shim:$PATH|' -e 's|sleep 10|true|' \
  -e 's|UPTIME_MIN=.*|UPTIME_MIN=99|' "$W/opt/idle-shutdown.sh" > "$W/idle-test.sh"
echo $(( $(date +%s) - 3600 )) > "$W/run/vanilla-tech-idle-since"
echo "test" > "$W/run/vanilla-tech-maintenance"; bash "$W/idle-test.sh" >/dev/null 2>&1
check "idle-shutdown no apaga durante mantenimiento" test ! -f "$W/shutdown.called"
touch -d '4 hours ago' "$W/run/vanilla-tech-maintenance"; bash "$W/idle-test.sh" >/dev/null 2>&1
check "idle-shutdown ignora un flag huérfano (>3 h)" test -f "$W/shutdown.called"

rt_stop
echo; echo "$(grep -c ^PASS "$RESULTS") PASS / $(grep -c ^FAIL "$RESULTS") FAIL"
[ "$(grep -c ^FAIL "$RESULTS")" = 0 ]
