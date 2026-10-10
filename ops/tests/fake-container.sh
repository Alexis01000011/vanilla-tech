#!/bin/bash
# fake-container.sh — lo que hace itzg/minecraft-server TYPE=MODRINTH en cada arranque, sin docker.
set -euo pipefail
cd "$VT_DATA"
echo "[init] mc-image-helper install-modrinth-modpack $VT_MODPACK"
"$MIH" install-modrinth-modpack --results-file="$VT_DATA/.install-modrinth.env" --project="$VT_MODPACK" \
  --output-directory="$VT_DATA" ${VT_TEST_EXCLUDES:+--default-exclude-includes="$VT_TEST_EXCLUDES"} \
  || { echo "[init] ERROR Failed to installModrinth modpack"; exit 1; }
# itzg reescribe server.properties desde variables de entorno en cada arranque
cat > server.properties <<PROPS
server-ip=127.0.0.1
server-port=$VT_PORT
enable-rcon=true
rcon.port=$VT_TEST_RCON_PORT
rcon.password=$VT_TEST_RCON_PW
online-mode=false
level-name=world
level-seed=20261010
view-distance=4
simulation-distance=4
spawn-protection=0
max-tick-time=-1
PROPS
# Directorio desechable de prueba local, autorizado por el dueño (igual que scripts/test-server.py).
echo "eula=true" > eula.txt
NFV=$(python3 -c 'import json,sys,zipfile;print(json.load(zipfile.ZipFile(sys.argv[1]).open("modrinth.index.json"))["dependencies"]["neoforge"])' "$VT_MODPACK")
echo "[init] starting NeoForge $NFV"
exec java -Xms512m "-Xmx${VT_TEST_HEAP:-2G}" -XX:ActiveProcessorCount=2 -XX:+UseG1GC \
  "@libraries/net/neoforged/neoforge/$NFV/unix_args.txt" nogui
