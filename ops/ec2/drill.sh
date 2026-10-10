#!/bin/bash
# drill.sh — Ensayo de restauración: extrae un backup a un directorio temporal y comprueba que el mundo
# se puede leer (level.dat válido, regiones de cada dimensión, playerdata). No toca el servidor ni
# necesita detenerlo.   drill.sh [BACKUP_ID|latest]
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
ID=${1:-latest}; [ "$ID" = latest ] && ID=$(snapshot_list | tail -n1)
[ -n "$ID" ] || die "no hay backups"
[[ "$ID" =~ ^[0-9]{8}T[0-9]{6}Z-[A-Za-z0-9.+-]+$ ]] || die "id inválido: $ID"
snapshot_verify "$ID"
T=$(mktemp -d "$VT_BACKUPS/.drill-XXXXXX"); trap 'rm -rf -- "$T"' EXIT
a=$(ls "$VT_BACKUPS/$ID"/data.tar.*); t0=$(now)
case "$a" in *.zst) zstd -q -dc "$a" | tar -C "$T" -xf - ;; *.gz) tar -C "$T" -xzf "$a" ;; esac
python3 - "$T" "$ID" "$(( $(now) - t0 ))" <<'PY'
import gzip,json,pathlib,sys
t,i,secs=pathlib.Path(sys.argv[1]),sys.argv[2],int(sys.argv[3])
w=t/'world';lvl=gzip.open(w/'level.dat').read()
assert lvl[:1]==b'\x0a','level.dat is not an NBT compound'
dims={str(p.parent.parent.relative_to(w)) or '.':len(list(p.glob('*.mca'))) for p in w.rglob('region') if p.is_dir()}
out={'backup':i,'ok':True,'extract_seconds':secs,'level_dat_bytes':len(lvl),'region_files':dims,
     'playerdata':len(list((w/'playerdata').glob('*.dat'))),'mods':len(list((t/'mods').glob('*.jar'))),
     'has':{f:(t/f).exists() for f in ('server.properties','whitelist.json','ops.json','config')}}
print('DRILL '+json.dumps(out))
PY
