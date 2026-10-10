#!/bin/bash
# local-runtime.sh — runtime de PRUEBA para los scripts de ops/ec2 (se carga con VT_RUNTIME_HOOKS).
# Emula vanilla-tech.service + itzg sin docker ni root: fake-container.sh instala el .mrpack con
# mc-image-helper (el mismo instalador que usa la imagen itzg) y arranca NeoForge en 127.0.0.1.
# Requiere: VT_TEST_DIR, MIH (bin/mc-image-helper), VT_TEST_RCON_PORT, VT_TEST_RCON_PW.
RUNDIR=$VT_TEST_DIR/run; mkdir -p "$RUNDIR"
_pid() { cat "$RUNDIR/container.pid" 2>/dev/null; }
_alive() { local p; p=$(_pid) && [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }
rt_start() {
  _alive && return 0
  : > "$RUNDIR/console.log"
  VT_DATA=$VT_DATA VT_MODPACK=$VT_MODPACK VT_PORT=$VT_PORT setsid bash "$(dirname "${BASH_SOURCE[0]}")/fake-container.sh" \
    >> "$RUNDIR/console.log" 2>&1 < /dev/null &
  echo $! > "$RUNDIR/container.pid"
}
rt_stop() {
  _alive || return 0
  local p; p=$(_pid)
  rt_rcon stop >/dev/null 2>&1 || kill -TERM "$p"
  for _ in $(seq 1 75); do kill -0 "$p" 2>/dev/null || return 0; sleep 2; done
  kill -TERM "$p" 2>/dev/null; sleep 10; kill -KILL "$p" 2>/dev/null || true
}
rt_active()  { _alive; }
rt_running() { _alive; }
rt_rcon() {
  if [ -n "${VT_TEST_FAKE_PLAYERS:-}" ] && [ "$*" = list ]; then
    echo "There are $VT_TEST_FAKE_PLAYERS of a max of 4 players online: Tester"; return 0
  fi
  python3 "$CD_DIR/mc_tools.py" rcon 127.0.0.1 "$VT_TEST_RCON_PORT" "$VT_TEST_RCON_PW" "$*"
}
rt_console_since() { cat "$RUNDIR/console.log" 2>/dev/null || true; }
