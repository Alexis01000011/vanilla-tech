#!/usr/bin/env bash
# impact.sh RELEASE.json — compara contra lo publicado: server/ (lo que corre la EC2) y stable/ (clientes).
# Sin sitio configurado o sin publicaciones previas, asume que hay que desplegar el servidor.
# Si el .mrpack nuevo está a mano (releases/<archivo>), revisa también los IDs del quest book.
set -euo pipefail
tools=$(cd -- "$(dirname -- "$0")/.." && pwd)
new=$1; site=${PACK_SITE_URL:-}; out=${GITHUB_OUTPUT:-/dev/null}; sum=${GITHUB_STEP_SUMMARY:-/dev/null}
full() {   # full ALIAS -> releases/<versión del alias>/release.json como impact-base-ALIAS.json
  local v; v=$(curl -fsSL --max-time 30 "$site/$1/release.json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["version"])') || return 1
  curl -fsSL --max-time 30 -o "impact-base-$1.json" "$site/releases/$v/release.json"
}
if [ -n "$site" ] && full server; then
  python3 "$tools/release.py" impact impact-base-server.json "$new" --github-output "$out" --summary "$sum" > impact-server.json
else
  echo "::notice::Sin release publicada del servidor (PACK_SITE_URL='${site}'): se asume despliegue de servidor."
  { echo "server_deploy=true"; echo "severity=unknown"; } >> "$out"
fi
if [ -n "$site" ] && full stable; then
  python3 "$tools/release.py" impact impact-base-stable.json "$new" > impact-stable.json
  python3 -c 'import json;r=json.load(open("impact-stable.json"));print(f"- Clientes (stable {r[\"base\"]}): actualización {\"sí\" if r[\"client_update\"] else \"no\"}")' >> "$sum"
  mine=releases/$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["mrpack"]["file"])' "$new")
  if [ -f "$mine" ]; then
    base=$(python3 -c 'import json;r=json.load(open("impact-base-stable.json"));print(r["version"]+"/"+r["mrpack"]["file"])')
    curl -fsSL --max-time 60 -o impact-base.mrpack "$site/releases/$base"
    python3 "$tools/check-quests.py" impact-base.mrpack "$mine"
  fi
fi
