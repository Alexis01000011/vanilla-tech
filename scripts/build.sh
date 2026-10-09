#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
python3 scripts/bootstrap-tools.py
mkdir -p .cache releases
.tools/packwiz --cache .cache/packwiz refresh
.tools/packwiz --cache .cache/packwiz modrinth export --restrictDomains=false -o .cache/export.mrpack
python3 scripts/package.py
