#!/bin/bash
# status.sh — Estado del pipeline en la instancia (solo lectura): release activa, servicio, jugadores,
# backups, espacio, lock y últimas operaciones. Salida JSON en la última línea.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
svc=$(rt_active && echo active || echo inactive)
players=null; ping=null
if rt_running; then players=$(players_online || echo null); ping=$($PY slp 127.0.0.1 "$VT_PORT" 2>/dev/null || echo null); fi
lock=free; [ -f "$VT_MAINT" ] && lock="$(cat "$VT_MAINT")"
python3 - "$VT_STATE" "$VT_BACKUPS" "$svc" "$players" "$ping" "$lock" "$(current_pack_version)" "$(df -Pm "$VT_BASE" | awk 'NR==2{print $4}')" <<'PY'
import json,pathlib,sys
st,bk,svc,players,ping,lock,pack,free=sys.argv[1:]
st,bk=pathlib.Path(st),pathlib.Path(bk)
active=json.loads((st/'active-release.json').read_text()) if (st/'active-release.json').exists() else None
snaps=[]
for d in sorted(bk.glob('2*')) if bk.exists() else []:
    if d.is_dir() and (d/'meta.json').exists():
        m=json.loads((d/'meta.json').read_text());snaps.append({k:m.get(k) for k in ('id','pack_version','reason','created_at','data_mb')})
hist=[json.loads(l) for l in (st/'history.jsonl').read_text().splitlines()[-5:]] if (st/'history.jsonl').exists() else []
out={'pack_file_version':pack,'active':active and {k:active.get(k) for k in ('version','sha256','deployed_at','previous_version','snapshot_before')},
     'service':svc,'players':json.loads(players),'ping':json.loads(ping),'maintenance':lock,'free_mb':int(free),'backups':snaps,'history':hist}
print(json.dumps(out,indent=1))
PY
