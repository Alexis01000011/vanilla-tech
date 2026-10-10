#!/usr/bin/env bash
# site-checkout.sh DIR — worktree de la rama gh-pages junto al checkout "ci" (hereda sus credenciales).
# Si la rama no existe todavía, crea una huérfana vacía.
set -euo pipefail
dir=$1; repo=${CI_REPO:-ci}
if git -C "$repo" fetch --depth 1 origin gh-pages:refs/remotes/origin/gh-pages 2>/dev/null; then
  git -C "$repo" worktree add -B gh-pages "$(realpath -m "$dir")" origin/gh-pages
else
  git -C "$repo" worktree add --orphan -b gh-pages "$(realpath -m "$dir")"
  echo "gh-pages nueva"
fi
