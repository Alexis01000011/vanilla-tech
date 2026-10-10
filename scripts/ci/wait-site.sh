#!/usr/bin/env bash
# wait-site.sh URL/release.json VERSION — espera a que GitHub Pages sirva esa versión (máx. 15 min).
set -euo pipefail
url=$1; want=$2
for _ in $(seq 1 90); do
  got=$(curl -fsSL --max-time 20 -H 'Cache-Control: no-cache' "$url?t=$(date +%s)" 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin)["version"])' 2>/dev/null || true)
  [ "$got" = "$want" ] && { echo "sitio sirve $want: $url"; exit 0; }
  sleep 10
done
echo "::error::GitHub Pages no sirvió $want en $url"; exit 1
