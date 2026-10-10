# Pruebas del pipeline CI/CD (2026-10-10)

Qué se probó, con qué resultado y qué falta. Evidencia cruda: `cicd-autoupdate-scenario.json`, `cicd-ec2-e2e.txt` y los runs de GitHub Actions.

## 1. Auto-update de Prism (local, packwiz-installer real) — 19/19

`scripts/tests/autoupdate-scenario.py`: sitio local con 0.4.0 (A), 0.5.0-alpha.1 (B) y una variante solo de cliente (C = B sin Dynamic FPS + nuevo default en `options.txt`). La instancia se importa desde el `.mrpack` de A como lo hace Prism y se personaliza: `options.txt` (FOV, tecla de salto), ajustes de un shader, un mundo, `servers.dat`, un mod propio, config de JEI y waypoints de Xaero.

| Paso | Resultado |
|---|---|
| Primera ejecución sobre la instancia importada (stable=A) | ✅ 3.3 s; **ningún mod re-descargado** (mtimes intactos); archivos del jugador intactos |
| Segunda ejecución | ✅ sin cambios (los archivos `preserve` modificados se revalidan, no se reescriben) |
| A → B (3 mods nuevos, configs nuevas) | ✅ 74 s; instancia = B; config del pack actualizada; opciones/teclas/shaders/mundo/mod propio conservados |
| B → C (solo cliente) | ✅ impacto `client`, sin despliegue de servidor; Dynamic FPS borrado; `options.txt` **no** reemplazado por el default nuevo |
| Publicación rota (metafile con bytes distintos al índice) | ✅ el instalador sale con error (Prism no lanza), **nada escrito** en la instancia |
| Sitio corregido → rollback de cliente C → B | ✅ Dynamic FPS restaurado; archivos del jugador conservados |
| Instalación lado servidor del mismo árbol | ✅ exactamente los 53 mods de servidor, ningún mod de cliente |

## 2. Servidor: deploy/rollback de punta a punta (local, NeoForge real) — 42/42 (`cicd-ec2-e2e.txt`)

`ops/tests/e2e-local.sh`: los scripts de `ops/ec2` instalados con `install.sh` en un "/opt/vanilla-tech" de prueba; el servicio se emula con el mismo instalador que usa itzg (mc-image-helper 1.72.0 `install-modrinth-modpack`, que también instala NeoForge) y un JVM NeoForge real con los 53 mods, RCON y Server List Ping. Releases: R1 = 0.5.0-alpha.1, R2 = config de servidor cambiada + Chunky quitado, R3 = rota a propósito (sin Architectury → NeoForge no carga), 0.4.0 y una con otro NeoForge.

Cubre: `install.sh` (idempotente, parche de `idle-shutdown.sh`); rechazos sin tocar nada (sha distinto, downgrade → 13, NeoForge distinto → 12, versión con caracteres raros, jugadores conectados → 10, lock ocupado → 11, release ya activa → no-op); deploy R1→R2 (Chunky borrado, config aplicada, marcador del mundo y `ops.json` conservados, contador de inactividad reiniciado, backup registrado); deploy R3 → **reversión automática** (código 2, servidor sano en R2, mundo intacto, datos apartados en `failed/`, historial); `rollback previous` (vuelve a R1 con el mundo del backup y guarda backup de seguridad); deshacer el rollback; ensayo de restauración; retención; `status.sh`; `idle-shutdown.sh` no apaga con el flag de mantenimiento y sí ignora un flag huérfano de más de 3 h.

Tiempos locales (laptop, heap 2G): deploy completo R1→R2 60 s (detener, backup verificado de ~400 MB, activar, arrancar, healthcheck); release rota detectada al primer error de carga de mods y revertida; rollback ~70 s.

**Fallas que encontraron las pruebas y se corrigieron**
1. `snapshot_verify` usaba `tar -t | grep -q` bajo `pipefail`: al cortar `grep` la tubería, `tar` moría por SIGPIPE y un backup bueno se daba por inválido (al azar). Efecto observado: "deshacer rollback" restauró correctamente su backup de seguridad (código 2) en vez de avanzar. Corregido con `grep -c`; mismo patrón corregido en el escaneo de la consola del healthcheck y en `rt_running`.
2. `drill.sh` calculaba mal la carpeta de cada dimensión.
3. Primera corrida en `/tmp` (tmpfs, RAM): `deploy.sh` se negó a respaldar por falta de espacio (1.4 GiB libres, pedía 2.5) y volvió a arrancar el servidor anterior sin cambios: el chequeo de espacio y la recuperación de la fase `stopped` funcionan. La prueba se movió a disco.

## 3. GitHub Actions (repo real)

| Run | Resultado |
|---|---|
| CI en PR #1, job `build` | ✅ lint; packwiz **compilado desde el commit fijado**; build con `.mrpack` **idéntico** al histórico (`3578edc3…`); 78 artefactos y 410 rangos Maven OK; 0 exclusiones de itzg |
| CI en PR #1, job `smoke` | ✅ NeoForge 21.1.257 con 53 mods: `Done (18.590s)`, salida 0, RSS pico 1.5 GiB (heap 4G), 18 líneas ERROR conocidas del arranque |
| CI en PR #1 tras los fixes de `ops/` | ✅ build + smoke |

## 4. Estáticas

- `shellcheck -S warning` limpio en `ops/`, `scripts/ci/`, `scripts/build.sh`; `actionlint` limpio en los 4 workflows.
- Python que corre en la instancia (`mc_tools.py` y los bloques embebidos) compatible con la gramática de Python 3.9 (Amazon Linux 2023).
- El documento SSM renderizado pasa `sh -n`; todos sus parámetros tienen `allowedPattern`/`allowedValues`.

## 5. Pendiente (no se puede probar sin la siguiente release o sin la instancia)

- Instalar `ops/ec2` en la EC2 real y correr `status.sh` + `drill.sh` sobre un backup real.
- Primer deploy real por el workflow **Deploy** (será 0.6.0-alpha.1, impacto alto, con tu aprobación): SSM, `sync-modpack.sh`, docker/itzg y tiempos reales.
- Configurar Prism en el Windows del amigo con la URL real; confirmar adopción sin descargas.
- Comportamiento del CDN de GitHub Pages justo después de promover `stable` (el instalador rechaza mezclas, pero conviene observarlo una vez).
- Prueba de gameplay en Prism de cada release: sigue siendo manual (el CI no la sustituye).
