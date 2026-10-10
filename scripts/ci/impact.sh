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
  python3 -c 'import json;r=json.load(open("impact-stable.json"));print("- Clientes (stable %s): actualización %s" % (r["base"], "sí" if r["client_update"] else "no"))' >> "$sum"
fi
# Quest IDs: compare with the newest published release older than this one (not only stable), so
# 0.6.0 -> 0.6.1 book edits are checked even while stable/server still run an older version.
mine=releases/$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["mrpack"]["file"])' "$new")
if [ -n "$site" ] && [ -f "$mine" ]; then
  prev=$(curl -fsSL --max-time 30 "$site/releases.json" | python3 -c '
import json,sys
sys.path.insert(0,sys.argv[1]);import release
new=json.load(open(sys.argv[2]))["version"];k=release.version_key
older=[r for r in json.load(sys.stdin)["releases"] if k(r["version"])<k(new)]
b=max(older,key=lambda r:k(r["version"])) if older else None
print(b["version"]+" "+b["mrpack"] if b else "")' "$tools" "$new") || prev=
  read -r pv prev <<<"$prev"
  if [ -n "$prev" ]; then
    echo "- IDs del quest book comparados con \`$pv\`" >> "$sum"
    curl -fsSL --max-time 60 -o impact-base.mrpack "$site/$prev"
    python3 "$tools/check-quests.py" impact-base.mrpack "$mine"
  fi
fi
