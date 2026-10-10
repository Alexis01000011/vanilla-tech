#!/bin/bash
# rollback.sh — Vuelve el servidor a un backup completo tomado por deploy.sh (mundo + archivos + pack).
#
#   rollback.sh [previous|BACKUP_ID] [--kick-players]
#   rollback.sh --list
#
# previous = el backup tomado justo antes de desplegar la release activa. OJO: el mundo vuelve al
# momento de ese backup; lo jugado después se pierde. Antes de restaurar se toma un backup de seguridad
# del estado actual, así que el rollback también se puede deshacer (rollback.sh <ese id>).
# Para volver solo el pack conservando el mundo (cambios sin registros nuevos, p. ej. configs):
#   deploy.sh <versión anterior> <sha256> --allow-downgrade
# Códigos: 0 ok · 1 error sin cambios · 2 falló y se restauró el estado previo · 3 intervención manual
#          10 hay jugadores · 11 lock ocupado
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
TARGET=previous; KICK=0
for a in "$@"; do
  case "$a" in
    --kick-players) KICK=1 ;;
    --list) snapshot_list; exit 0 ;;
    previous|[0-9]*) TARGET=$a ;;
    *) die "argumento inválido: $a" ;;
  esac
done
[ "$TARGET" = previous ] && TARGET=$(active_field snapshot_before)
[ -n "$TARGET" ] || die "no hay backup 'previous' registrado; usa rollback.sh --list"
[[ "$TARGET" =~ ^[0-9]{8}T[0-9]{6}Z-[A-Za-z0-9.+-]+$ ]] || die "id de backup inválido: $TARGET"
snapshot_verify "$TARGET"
TV=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["pack_version"])' "$VT_BACKUPS/$TARGET/meta.json")

mkdir -p "$VT_LOG_DIR"
LOG="$VT_LOG_DIR/$(date -u +%Y%m%dT%H%M%SZ)-rollback-$TARGET.log"
exec > >(tee -a "$LOG") 2>&1
T0=$(now); PHASE=init; SAFETY=; CUR=$(current_pack_version); WAS_RUNNING=0
log "rollback a $TARGET (pack $TV) — activo: $CUR"

on_exit() {
  local rc=$?
  set +e
  if [ "$rc" -ne 0 ] && { [ "$PHASE" = restored ] || [ "$PHASE" = restoring ]; }; then
    log "el estado restaurado no está sano; vuelvo al backup de seguridad $SAFETY"
    { rt_stop; for _ in $(seq 1 90); do rt_running || break; sleep 2; done; }
    if ( snapshot_restore "$SAFETY" ); then
      s=$(now); rt_start
      if "$CD_DIR/healthcheck.sh" --since "$s" --expect-version "$CUR"; then rc=2; else rc=3; fi
    else rc=3; fi
  elif [ "$rc" -ne 0 ] && [ "$PHASE" = stopped ] && [ "$WAS_RUNNING" = 1 ]; then
    s=$(now); rt_start; "$CD_DIR/healthcheck.sh" --since "$s" >/dev/null || rc=3
  fi
  [ "$rc" -ne 0 ] && record_history rollback "$TV" "failed-rc$rc" target="$TARGET" safety="$SAFETY"
  [ "$rc" = 3 ] && log "INTERVENCIÓN MANUAL: ver $LOG; backups en $VT_BACKUPS"
  [ "$PHASE" != init ] && release_lock
  log "fin: código $rc en $(( $(now) - T0 )) s"; exit "$rc"
}
trap on_exit EXIT
acquire_lock; PHASE=locked; maintenance_on "rollback $TARGET"
if rt_active || rt_running; then
  WAS_RUNNING=1
  server_ready_now || wait_for_ready 60 || log "aviso: el servidor actual no responde (se restaura igual)"
  P=$(players_online || echo 0)
  if [ "$P" -gt 0 ]; then
    [ "$KICK" = 1 ] || die "hay $P jugador(es) conectados; reintenta cuando salgan (o --kick-players con su acuerdo)" 10
    rt_rcon "say Mantenimiento: el servidor se reinicia en 60 s" || true; sleep 60
  fi
fi
stop_server; PHASE=stopped
SAFETY=$(snapshot_create "pre-rollback a $TARGET")
offsite_backup
PHASE=restoring; snapshot_restore "$TARGET"; PHASE=restored
S=$(now); rt_start
HEALTH=$("$CD_DIR/healthcheck.sh" --since "$S" --expect-version "$TV" | tail -n1) || die "healthcheck falló tras restaurar: ${HEALTH:-sin salida}"
$PY snapshot-meta "$VT_STATE/active-release.json" version="$TV" sha256="$(sha256_of "$VT_MODPACK")" deployed_at="$(date -u +%FT%TZ)" \
  previous_version="$CUR" snapshot_before="$SAFETY" restored_from="$TARGET" health="${HEALTH#HEALTH }" log="$LOG"
record_history rollback "$TV" ok target="$TARGET" safety="$SAFETY" seconds="$(( $(now) - T0 ))"
PHASE=finished; snapshot_prune "$TARGET" "$SAFETY"
log "OK: $CUR -> $TV (backup $TARGET). Para deshacer: rollback.sh $SAFETY"
echo "RESULT {\"result\":\"ok\",\"version\":\"$TV\",\"previous\":\"$CUR\",\"restored\":\"$TARGET\",\"safety\":\"$SAFETY\"}"
