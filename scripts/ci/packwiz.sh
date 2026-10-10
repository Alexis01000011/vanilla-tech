#!/usr/bin/env bash
# Build packwiz from source at the commit locked in research/packwiz.json (CI). Prints the binary path.
# The nightly.link artifact used by bootstrap-tools.py expires on 2026-12-05; a source build of the
# same commit produces the same exports.
set -euo pipefail
cd -- "$(dirname -- "$0")/../.."
commit=$(python3 -c "import json;print(json.load(open('research/packwiz.json'))['commit'])")
out=${PACKWIZ_OUT:-$PWD/.cache/packwiz-src/packwiz-$commit}
if [ ! -x "$out" ]; then
  GOBIN=$(dirname "$out")/bin GOFLAGS=-mod=mod go install "github.com/packwiz/packwiz@$commit" >&2
  mkdir -p "$(dirname "$out")"; mv "$(dirname "$out")/bin/packwiz" "$out"
fi
"$out" --help >/dev/null
echo "$out"
