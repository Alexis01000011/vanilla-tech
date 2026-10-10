#!/usr/bin/env bash
# site-push.sh DIR MESSAGE — commitea y empuja gh-pages; reintenta con rebase si otro workflow publicó antes.
# Un push a gh-pages dispara el despliegue de GitHub Pages, que reemplaza el sitio completo de una vez.
set -euo pipefail
dir=$1; msg=$2
git -C "$dir" add -A
if git -C "$dir" diff --cached --quiet; then echo "sin cambios en el sitio"; exit 0; fi
git -C "$dir" commit -q -m "$msg"
for i in 1 2 3 4 5; do
  git -C "$dir" push origin HEAD:gh-pages && exit 0
  echo "push rechazado; rebase sobre gh-pages ($i)"; sleep $((i * 5))
  git -C "$dir" pull --rebase origin gh-pages
  python3 "$(dirname "$0")/../release.py" verify --site "$dir"
done
exit 1
