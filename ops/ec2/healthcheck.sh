#!/bin/bash
# healthcheck.sh — ¿El servidor está realmente sano? `systemctl start` exitoso no basta.
#
#   healthcheck.sh [--since EPOCH] [--expect-version V] [--timeout S]
#
# --since: espera a que un logs/latest.log escrito después de EPOCH diga "Done (" (falla rápido ante
#          un crash, un error de carga de mods o un error del instalador de itzg).
# Luego: Server List Ping real al puerto, RCON `list`, mods instalados == mods de servidor de la
# release (nombre y sha512, sin JARs de más) y versión del pack activo. Última línea: HEALTH {json}.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
SINCE=; EXPECT=; TIMEOUT=$VT_HEALTH_TIMEOUT
while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE=$2; shift 2 ;; --expect-version) EXPECT=$2; shift 2 ;; --timeout) TIMEOUT=$2; shift 2 ;;
    *) die "opción desconocida: $1" ;;
  esac
done
fail() { log "HEALTH FAIL: $1"; echo "HEALTH {\"ok\":false,\"error\":$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1")}"; exit 1; }
T0=$(now); READY='{}'

if [ -n "$SINCE" ]; then
  deadline=$(( T0 + TIMEOUT ))
  while :; do
    [ "$(now)" -lt "$deadline" ] || fail "el servidor no terminó de cargar en ${TIMEOUT}s"
    if READY=$($PY wait-ready "$VT_DATA/logs/latest.log" "$SINCE" 10 2>/dev/null); then break; fi
    case "$READY" in *'"error": "timeout"'*) ;; *) fail "crash al arrancar: $READY" ;; esac
    rt_console_since "$SINCE" | grep -qE 'Failed to install|\[init\] ERROR|mc-image-helper.*ERROR' \
      && fail "error del instalador del contenedor: $(rt_console_since "$SINCE" | grep -E 'ERROR' | tail -n2 | tr '\n' ' ')"
  done
  log "Minecraft cargó: $READY"
fi

SLP=$($PY slp 127.0.0.1 "$VT_PORT") || fail "no responde al Server List Ping en el puerto $VT_PORT: $SLP"
case "$SLP" in *'1.21.1'*) ;; *) fail "versión inesperada en el ping: $SLP" ;; esac
P=$(players_online) || fail "RCON no responde"
MODS=$($PY verify-mods "$VT_MODPACK" "$VT_DATA") || fail "los mods instalados no coinciden con la release: $MODS"
ACTIVE=$(current_pack_version)
[ -z "$EXPECT" ] || [ "$ACTIVE" = "$EXPECT" ] || fail "pack activo $ACTIVE != $EXPECT"
DRIFT=$(python3 -c 'import json,sys;print(len(json.loads(sys.argv[1])["config_drift"]))' "$MODS")
[ "$DRIFT" = 0 ] || log "aviso: $DRIFT config(s) del pack reescritas por los mods (normal en NeoForge)"
log "sano: pack $ACTIVE, $P jugadores, ping $SLP"
echo "HEALTH {\"ok\":true,\"version\":\"$ACTIVE\",\"players\":$P,\"ready\":$READY,\"ping\":$SLP,\"mods\":$MODS,\"seconds\":$(( $(now) - T0 ))}"
