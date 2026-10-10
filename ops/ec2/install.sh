#!/bin/bash
# install.sh — Instala (o actualiza) los scripts del pipeline en la instancia. Idempotente.
#
#   install.sh --release-url URL --bucket NAME [--dest /opt/vanilla-tech/cd] [--base /opt/vanilla-tech] [--log-dir DIR]
#
# - copia deploy/rollback/healthcheck/status/drill + lib.sh + mc_tools.py a DEST (root, 755);
# - escribe DEST/cd.env (conserva VT_KEEP_SNAPSHOTS/VT_HEALTH_TIMEOUT si ya existía);
# - agrega a idle-shutdown.sh el respeto al flag de mantenimiento (copia .bak antes de editar);
# - registra la release activa actual como punto de partida si no hay registro.
# No reinicia ni detiene nada.
set -euo pipefail
SRC=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DEST=/opt/vanilla-tech/cd; URL=; BUCKET=; BASE=/opt/vanilla-tech; LOGDIR=/var/log/vanilla-tech-cd
while [ $# -gt 0 ]; do
  case "$1" in
    --release-url) URL=$2; shift 2 ;; --bucket) BUCKET=$2; shift 2 ;; --dest) DEST=$2; shift 2 ;;
    --base) BASE=$2; shift 2 ;; --log-dir) LOGDIR=$2; shift 2 ;;
    *) echo "opción desconocida: $1" >&2; exit 1 ;;
  esac
done
[[ "$URL" =~ ^https://[A-Za-z0-9.-]+(/[A-Za-z0-9._-]+)*$ ]] || { echo "--release-url https://... requerido" >&2; exit 1; }
[[ "$BUCKET" =~ ^[a-z0-9.-]{3,63}$ ]] || { echo "--bucket requerido" >&2; exit 1; }
for c in python3 curl tar flock sha256sum aws docker; do command -v "$c" >/dev/null || { echo "falta $c" >&2; exit 1; }; done
command -v zstd >/dev/null || echo "aviso: sin zstd; los backups usarán gzip (más lentos)"

install -d -m 755 "$DEST" "$BASE/cd-state" "$BASE/backups" "$LOGDIR"
if [ "$SRC" != "$DEST" ]; then
  for f in lib.sh deploy.sh rollback.sh healthcheck.sh status.sh drill.sh mc_tools.py install.sh cd.env.example; do
    install -m 755 "$SRC/$f" "$DEST/$f"
  done
fi
keep=$(grep -E '^(VT_KEEP_SNAPSHOTS|VT_HEALTH_TIMEOUT|VT_MIN_FREE_MB)=' "$DEST/cd.env" 2>/dev/null || true)
sed -e "s|^VT_BUCKET=.*|VT_BUCKET=$BUCKET|" -e "s|^VT_RELEASE_URL=.*|VT_RELEASE_URL=$URL|" -e "s|^VT_BASE=.*|VT_BASE=$BASE|" \
    -e "s|^VT_LOG_DIR=.*|VT_LOG_DIR=$LOGDIR|" -e "s|/opt/vanilla-tech/|$BASE/|g" "$DEST/cd.env.example" | sed 's/[[:space:]]*#.*$//' | grep -v '^$' > "$DEST/cd.env.new"
if [ -n "$keep" ]; then
  while IFS= read -r line; do sed -i "s|^${line%%=*}=.*|$line|" "$DEST/cd.env.new"; done <<<"$keep"
fi
chmod 644 "$DEST/cd.env.new"; mv -f "$DEST/cd.env.new" "$DEST/cd.env"

# idle-shutdown.sh: no apagar a la mitad de un deploy. Un flag de más de 3 h se ignora (lock huérfano).
IDLE=$BASE/idle-shutdown.sh
if [ -f "$IDLE" ] && ! grep -q vanilla-tech-maintenance "$IDLE"; then
  anchor='[ -f /var/run/vanilla-tech-pregen-active ] && exit 0'
  if grep -qxF "$anchor" "$IDLE"; then
    cp -p "$IDLE" "$IDLE.bak-$(date -u +%Y%m%dT%H%M%SZ)"
    python3 - "$IDLE" "$anchor" <<'PY'
import sys
f,anchor=sys.argv[1:];s=open(f).read()
add=('# Deploy/rollback del pipeline CD en curso (/opt/vanilla-tech/cd): no apagar a la mitad. Un flag de mas de 3 h se ignora.\n'
     'M=/var/run/vanilla-tech-maintenance; [ -f "$M" ] && [ $(( $(date +%s) - $(stat -c %Y "$M") )) -lt 10800 ] && exit 0\n')
open(f,'w').write(s.replace(anchor+'\n',anchor+'\n'+add,1))
PY
    bash -n "$IDLE" && echo "idle-shutdown.sh: respeta el flag de mantenimiento"
  else
    echo "AVISO: no encontré la línea ancla en $IDLE; agrega el chequeo de /var/run/vanilla-tech-maintenance a mano" >&2
  fi
fi

if [ ! -f "$BASE/cd-state/active-release.json" ] && [ -f "$BASE/modpacks/vanilla-tech.mrpack" ]; then
  python3 - "$BASE/modpacks/vanilla-tech.mrpack" "$BASE/cd-state/active-release.json" <<'PY'
import hashlib,json,sys,time,zipfile
mr,out=sys.argv[1:];v=json.load(zipfile.ZipFile(mr).open('modrinth.index.json'))['versionId']
json.dump({'version':v,'sha256':hashlib.sha256(open(mr,'rb').read()).hexdigest(),'deployed_at':None,
           'adopted_at':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'note':'release previa al pipeline, adoptada por install.sh'},
          open(out,'w'),indent=1,sort_keys=True)
print('release activa registrada:',v)
PY
fi
echo "instalado en $DEST:"; cat "$DEST/cd.env"
