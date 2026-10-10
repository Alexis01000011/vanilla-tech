#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
python3 scripts/bootstrap-tools.py
mkdir -p .cache releases
.tools/packwiz --cache .cache/packwiz refresh
# Player-owned client files (options, keybinds, shader settings) are never overwritten by auto-update.
if [ -n "$(python3 scripts/preserve.py)" ]; then .tools/packwiz --cache .cache/packwiz refresh; fi
.tools/packwiz --cache .cache/packwiz modrinth export --restrictDomains=false -o .cache/export.mrpack
python3 scripts/package.py
