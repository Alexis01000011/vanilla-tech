#!/bin/bash
# drill.sh — Ensayo de restauración: extrae un backup a un directorio temporal y comprueba que el mundo
# se puede leer (level.dat válido, regiones de cada dimensión, playerdata). No toca el servidor ni
# necesita detenerlo.   drill.sh [BACKUP_ID|latest|s3]
# s3 = la copia externa del mundo (s3://$VT_BUCKET/backups/world.tar.gz, la que hace backup.sh).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
ID=${1:-latest}; [ "$ID" = latest ] && ID=$(snapshot_list | tail -n1)
[ -n "$ID" ] || die "no hay backups locales (usa: drill.sh s3)"
mkdir -p "$VT_BACKUPS"; T=$(mktemp -d "$VT_BACKUPS/.drill-XXXXXX"); trap 'rm -rf -- "$T"' EXIT; t0=$(now)
if [ "$ID" = s3 ]; then
  [ -n "$VT_BUCKET" ] || die "VT_BUCKET vacío"
  aws s3 cp "s3://$VT_BUCKET/backups/world.tar.gz" "$T/world.tar.gz" --region "$VT_REGION" --only-show-errors
  ID="s3:$(aws s3api head-object --bucket "$VT_BUCKET" --key backups/world.tar.gz --region "$VT_REGION" --query 'Metadata."taken-at"' --output text 2>/dev/null || echo ?)"
  tar -C "$T" -xzf "$T/world.tar.gz" && rm -f "$T/world.tar.gz"
else
  [[ "$ID" =~ ^[0-9]{8}T[0-9]{6}Z-[A-Za-z0-9.+-]+$ ]] || die "id inválido: $ID"
  snapshot_verify "$ID"
  a=$(ls "$VT_BACKUPS/$ID"/data.tar.*)
  case "$a" in *.zst) zstd -q -dc "$a" | tar -C "$T" -xf - ;; *.gz) tar -C "$T" -xzf "$a" ;; esac
fi
python3 - "$T" "$ID" "$(( $(now) - t0 ))" <<'PY'
import gzip,json,pathlib,sys
t,i,secs=pathlib.Path(sys.argv[1]),sys.argv[2],int(sys.argv[3])
w=t/'world';lvl=gzip.open(w/'level.dat').read()
assert lvl[:1]==b'\x0a','level.dat is not an NBT compound'
dims={str(p.parent.relative_to(w)):len(list(p.glob('*.mca'))) for p in w.rglob('region') if p.is_dir()}  # '.' = Overworld
out={'backup':i,'ok':True,'extract_seconds':secs,'level_dat_bytes':len(lvl),'region_files':dims,
     'playerdata':len(list((w/'playerdata').glob('*.dat'))),'mods':len(list((t/'mods').glob('*.jar'))),
     'has':{f:(t/f).exists() for f in ('server.properties','whitelist.json','ops.json','config')}}
print('DRILL '+json.dumps(out))
PY
