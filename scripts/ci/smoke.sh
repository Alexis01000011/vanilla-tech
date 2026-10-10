#!/usr/bin/env bash
# smoke.sh NAME — arranca un servidor NeoForge real con el .mrpack de releases/ en un directorio
# desechable (127.0.0.1:25575) y corre comandos básicos. Deja docs/NAME.json y docs/NAME.log.
# Limita: no hay jugadores; no sustituye la prueba de gameplay en Prism.
set -euo pipefail
name=${1:-ci-smoke}; dir=.cache/$name-server
rm -rf "$dir"
python3 scripts/prepare-server.py --directory "$dir" --heap 3G   # user_jvm_args; test-server.py fija su propio -Xmx
touch "$dir/.vanilla-tech-test-only"
# El dueño del repositorio ya aceptó la EULA de Minecraft para su servidor; este es un servidor de prueba
# efímero de su CI, en loopback y sin jugadores.
python3 scripts/test-server.py --directory "$dir" --name "$name" --accept-eula --heap 4G --timeout 900
python3 - "$name" <<'PY'
import json,re,sys
n=sys.argv[1];r=json.load(open(f'docs/{n}.json'));log=open(f'docs/{n}.log',errors='replace').read()
errs=len(re.findall(r'/ERROR\]',log))
print(f"ready={r['ready']} exit={r['exit_code']} elapsed={r['elapsed_seconds']}s peak_rss={r['peak_rss_mib']}MiB errors_in_log={errs}")
with open(__import__('os').environ.get('GITHUB_STEP_SUMMARY','/dev/null'),'a') as f:
    f.write(f"### Smoke test de servidor\n- Arrancó: **{r['ready']}**, salida {r['exit_code']}, {r['elapsed_seconds']} s, RSS pico {r['peak_rss_mib']} MiB\n- Líneas ERROR en el log: {errs} (revisar el artefacto si suben respecto a la release anterior)\n- Límite: sin jugadores; la prueba de gameplay en Prism sigue siendo manual.\n")
PY
