# Vanilla Tech

Modpack de Minecraft Java para survival cooperativo de dos jugadores: **vanilla técnico** con Create y Applied Energistics 2, mucha calidad de vida y exploración ligera, sin reemplazar terreno, biomas ni las estructuras vanilla de las que dependen las granjas.

| | |
|---|---|
| Versión del pack | **0.1.0-rc.2** |
| Minecraft / loader | 1.21.1 / NeoForge 21.1.257 |
| Java | 21 |
| Gestor | [packwiz](https://packwiz.infra.link/) (commit `ef87d96`) |
| Launcher | Prism Launcher (`.mrpack`) |
| Mods | 40 artefactos fijados: 39 en el cliente, 31 en el servidor |
| Estado | Servidor probado (instalación limpia, integración por comandos, pregeneración). **Cliente pendiente** de prueba en Prism. |

Contenido principal: Create · AE2 + Applied Create + AE2 Wireless Terminals + Extended AE · Waystones · Dank Storage · Building Gadgets 2 · Excessive Utilities · FTB Chunks · Explorify + YUNG's Extras/Bridges · JEI · Inventory Profiles Next · Crafting Tweaks · Xaero's Minimap/World Map · Sodium, Lithium, FerriteCore, ModernFix, ImmediatelyFast, Entity Culling, Dynamic FPS · spark · Chunky.
La lista completa, con versiones y enlaces, está en [docs/mod-catalog.md](docs/mod-catalog.md).

## Documentación

| Documento | Contenido |
|---|---|
| [docs/installation.md](docs/installation.md) | Instalar y actualizar cliente (Prism) y servidor; FTB Chunks; backups; operador `imalexisxo`. |
| [docs/mod-catalog.md](docs/mod-catalog.md) | Qué aporta cada mod, enlaces oficiales y mods rechazados. |
| [docs/compatibility-matrix.md](docs/compatibility-matrix.md) | Versión, fuente, dependencias, lado y estado de prueba de cada mod (generada). |
| [docs/performance.md](docs/performance.md) | Mediciones del servidor y recomendaciones de memoria para cliente y servidor (8/16 GiB). |
| [docs/test-results.md](docs/test-results.md) | Resultados reales de cada etapa de validación. |
| [docs/known-issues.md](docs/known-issues.md) | Problemas conocidos y pruebas pendientes. |
| [docs/decisions.md](docs/decisions.md) | Bitácora de decisiones técnicas. |

## Estructura del repositorio

```
vanilla-tech/
├── pack.toml, index.toml     # proyecto packwiz (fuente de verdad)
├── mods/*.pw.toml            # 40 metafiles con versión, URL y hash fijados (sin JARs)
├── config/                   # configs del pack (EU, ModernFix, FTB Chunks) → overrides/
├── options.txt               # opciones y atajos de cliente → client-overrides/
├── server-template/          # server.properties y user_jvm_args.txt de partida
├── scripts/                  # build, validación, instalación y pruebas de servidor
├── research/                 # locks de herramientas (packwiz, NeoForge, ECJ) y metadatos consultados
├── docs/                     # documentación y resúmenes JSON de las pruebas
└── releases/                 # .mrpack generados (no versionados)
```
No se versionan `.tools/`, `.cache/`, `releases/`, `server/` ni ningún `*.jar`.

## Reconstruir desde cero

Requisitos: Linux x86-64, git, Python ≥ 3.11, **JDK 21 completo** (con `javac`; el chequeo de rangos lo necesita. Para el servidor basta el JRE) y acceso a internet.

```bash
git clone <este-repo> vanilla-tech && cd vanilla-tech
bash scripts/build.sh    # descarga packwiz verificado, refresca el índice, exporta y empaqueta
bash scripts/check.sh    # descarga los 40 JARs a .cache y valida todo; regenera la matriz
```
El resultado queda en `releases/vanilla-tech-<versión>.mrpack` (+ `.sha256`). El empaquetado es determinista: mismas entradas, mismo archivo.

> **packwiz** se descarga de un artefacto de CI que caduca el **2026-12-05**. Después de esa fecha, compílalo con `go install github.com/packwiz/packwiz@ef87d964f8cbd52b3b13ea42453ef322290e2b9e` y copia el binario a `.tools/packwiz`. Ver [known-issues.md](docs/known-issues.md).

### Scripts

| Script | Qué hace |
|---|---|
| `scripts/build.sh` | `bootstrap-tools.py` → `packwiz refresh` → `packwiz modrinth export` → `package.py` (mueve `options.txt` a `client-overrides/`, ordena el manifiesto y rechaza JARs embebidos). |
| `scripts/check.sh` | `fetch-artifacts.py`, `validate.py`, `check-ranges.py`, `worldgen-audit.py` y `gen-matrix.py`. |
| `scripts/prepare-server.sh` | Instala o actualiza un servidor desde la release (`--directory`, `--heap 3G…10G`, `--replace-configs`). Idempotente. Nunca acepta la EULA. |
| `scripts/test-server.sh` | Arranque acotado en `127.0.0.1:25575` sobre un directorio marcado con `.vanilla-tech-test-only`. Envía comandos de un archivo (`#sleep`, `#wait REGEX`) y guarda `docs/<name>.json`. |
| `scripts/integration-commands.txt` | Prueba de integración: estructuras vanilla y de Explorify, AE2, Create, Applied Create y colocación de bloques de los demás mods. |
| `scripts/pregen-commands.txt` | Benchmark de pregeneración con Chunky. |
| `scripts/research.py` | Vuelve a consultar Modrinth para ver versiones nuevas (no modifica el pack). |

### Probar un servidor localmente
```bash
python3 scripts/prepare-server.py --directory .cache/server-test --heap 3G
touch .cache/server-test/.vanilla-tech-test-only     # solo en directorios desechables
# --accept-eula solo con la aprobación del propietario de la cuenta
python3 scripts/test-server.py --directory .cache/server-test --name local-integration \
  --accept-eula --timeout 900 --commands scripts/integration-commands.txt
```

## Actualizar o agregar un mod

Nunca uses versiones "latest" dinámicas en una release cerrada.

1. Consulta la versión con `python3 scripts/research.py` o en la página del proyecto.
2. Agrégala o cámbiala:
   - Modrinth: `.tools/packwiz modrinth add --project-id <id> --version-id <id>`
   - CurseForge: `.tools/packwiz curseforge add --addon-id <id> --file-id <id>`. Después reemplaza `mode = "metadata:curseforge"` por la URL explícita `https://edge.forgecdn.net/files/<id/1000>/<id%1000>/<archivo>` (ver `mods/ftb-chunks-forge.pw.toml`).
3. Fija la versión (`.tools/packwiz pin <mod>`) y revisa `side` (`client`, `server` o `both`).
4. Sube la `version` de `pack.toml`.
5. `bash scripts/build.sh && bash scripts/check.sh`.
6. Prueba el servidor (arriba) y, si el cambio afecta al cliente, también en Prism.
7. Actualiza `docs/test-status.toml`, `docs/decisions.md` y `docs/mod-catalog.md`; regenera la matriz con `check.sh`.
8. Haz commit y etiqueta la release (`git tag v<versión>`).

## Licencias y distribución

El repositorio solo contiene metadatos, configs y scripts. Los JARs se descargan de Modrinth o CurseForge desde sus CDNs oficiales y se verifican por hash; nunca se redistribuyen. Cada mod conserva su propia licencia (ver su página).
