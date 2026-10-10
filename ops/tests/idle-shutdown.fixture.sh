#!/bin/bash
# Copia fiel de /opt/vanilla-tech/idle-shutdown.sh (de minecraft-server-scripts/vanilla-tech/user-data.sh) para probar install.sh.
# Apaga la instancia tras 10 min sin jugadores. Corre por cron cada minuto, asi que el apagado real
# cae ~10-11 min despues del ultimo jugador. Misma logica que mc-idle-shutdown.sh / e2e/autoshutdown.sh:
# cuenta jugadores con RCON `list`, hace backup y `shutdown -h now` (la instancia queda stopped).
# Desactivado mientras exista el sentinela de pregeneracion.
# Extra: si RCON no responde 30 min seguidos (server en crash loop o pack roto), apaga igual para no
# dejar la instancia prendida quemando creditos. Un fallo suelto de RCON nunca cuenta como "vacio".
set -uo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

[ -f /var/run/vanilla-tech-pregen-active ] && exit 0
IDLE_FILE=/var/run/vanilla-tech-idle-since
FAIL_FILE=/var/run/vanilla-tech-rcon-fail-since
THRESHOLD=600
FAIL_THRESHOLD=1800
GRACE_MIN=5

# Gracia tras el boot: el contenedor tarda unos minutos en instalar y cargar los mods.
UPTIME_MIN=$(awk '{print int($1/60)}' /proc/uptime)
if [ "$UPTIME_MIN" -lt "$GRACE_MIN" ]; then rm -f "$IDLE_FILE"; exit 0; fi

NOW=$(date +%s)
# /list responde: "There are 2 of a max of 4 players online: a, b" -> tomamos el "There are N".
LIST_OUT=$(docker exec mc rcon-cli list 2>/dev/null)
PLAYER_COUNT=$(printf '%s' "$LIST_OUT" | grep -oP 'There are \K[0-9]+' | head -n1)

if ! [[ "$PLAYER_COUNT" =~ ^[0-9]+$ ]]; then
  [ -f "$FAIL_FILE" ] || echo "$NOW" > "$FAIL_FILE"
  FAIL_FOR=$((NOW - $(cat "$FAIL_FILE")))
  echo "$(date): consulta de jugadores fallo hace ${FAIL_FOR}s (salida='${LIST_OUT}'); omitiendo ciclo"
  if [ "$FAIL_FOR" -ge "$FAIL_THRESHOLD" ]; then
    echo "$(date): RCON sin respuesta ${FAIL_FOR}s: apagando para no gastar"
    shutdown -h now
  fi
  exit 0
fi
rm -f "$FAIL_FILE"

if [ "$PLAYER_COUNT" -eq 0 ]; then
  if [ ! -f "$IDLE_FILE" ]; then
    echo "$NOW" > "$IDLE_FILE"
    echo "$(date): Servidor vacio, iniciando contador"
  else
    IDLE_FOR=$((NOW - $(cat "$IDLE_FILE")))
    echo "$(date): Vacio desde hace ${IDLE_FOR}s (umbral: ${THRESHOLD}s)"
    if [ "$IDLE_FOR" -ge "$THRESHOLD" ]; then
      echo "$(date): Apagando por inactividad (backup + shutdown)..."
      docker exec mc rcon-cli "say Servidor apagandose por inactividad en 10s..." 2>/dev/null || true
      sleep 10
      /opt/vanilla-tech/backup.sh || true
      shutdown -h now
    fi
  fi
else
  echo "$(date): ${PLAYER_COUNT} jugador(es) conectado(s)"
  rm -f "$IDLE_FILE"
fi
