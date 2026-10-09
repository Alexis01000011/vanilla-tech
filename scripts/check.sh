#!/usr/bin/env bash
# Offline validation of the built release: hashes, export parity, sides, nested deps,
# version ranges and vanilla worldgen overrides; regenerates the compatibility matrix.
set -euo pipefail
cd -- "$(dirname -- "$0")"
version=$(python3 -c "import tomllib;print(tomllib.load(open('../pack.toml','rb'))['version'])")
python3 fetch-artifacts.py "../releases/vanilla-tech-$version.mrpack" >/dev/null
python3 validate.py
python3 check-ranges.py
python3 worldgen-audit.py
python3 gen-matrix.py
