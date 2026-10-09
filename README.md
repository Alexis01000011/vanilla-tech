# Vanilla Tech

Modpack de Minecraft Java para survival cooperativo de dos jugadores: **vanilla técnico** con Create y Applied Energistics 2, mucha calidad de vida y exploración ligera, sin reemplazar terreno, biomas ni las estructuras vanilla de las que dependen las granjas.

| | |
|---|---|
| Versión del pack | **0.5.0-alpha.1** (pruebas: L_Ender's Cataclysm y Just Hammers). Estable actual: **0.4.0**. Ver [Versiones](#versiones-y-ramas) |
| Minecraft / loader | 1.21.1 / NeoForge 21.1.257 |
| Java | 21 |
| Gestor | [packwiz](https://packwiz.infra.link/) (commit `ef87d96`) |
| Launcher | Prism Launcher (`.mrpack`) |
| Mods | 78 artefactos fijados (72 mods + 5 shaderpacks + 1 resource pack): 77 en el cliente, 53 en el servidor |
| Estado | Servidor probado (instalación limpia, integración por comandos, pregeneración). Cliente **0.4.0-alpha.1** (mismos mods que 0.4.0) probado en Prism por el usuario; antes, 0.3.0-alpha.1 con el Aether, Deep Aether y el Otherside. Los mods nuevos de 0.5.0-alpha.1 solo están probados en el servidor. Faltan las pruebas en juego de [known-issues.md](docs/known-issues.md). |

Contenido principal: Create + Create: Connected + Create Crafts & Additions · AE2 + Applied Create + AE2 Wireless Terminals + Extended AE + AE2 JEI Integration · Waystones · Dank Storage · Storage Drawers · Sophisticated Backpacks · GraveStone · Building Gadgets 2 · Excessive Utilities · FTB Chunks · **The Aether + Deep Aether + Deeper and Darker** (alpha) · L_Ender's Cataclysm · Just Hammers · Friends & Foes · Illager Invasion · It Takes a Pillage · Artifacts · Explorify + YUNG's Extras/Bridges · JEI · Jade · Inventory Profiles Next · Crafting Tweaks · Controlling · Xaero's Minimap/World Map · Just Zoom · Not Enough Animations + Fresh Animations: Player Extension (EMF/ETF) · Sodium + Iris (shaders opcionales, apagados) · Lithium, FerriteCore, ModernFix, ImmediatelyFast, Entity Culling, Dynamic FPS · spark · Chunky.
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
| [CHANGELOG.md](CHANGELOG.md) | Cambios de cada versión, con el SHA-256 de cada `.mrpack`. |

## Estructura del repositorio

```
vanilla-tech/
├── pack.toml, index.toml     # proyecto packwiz (fuente de verdad)
├── mods/*.pw.toml            # 72 metafiles con versión, URL y hash fijados (sin JARs)
├── shaderpacks/              # 5 metafiles de shaders (Modrinth) + ajustes .txt → client-overrides/
├── resourcepacks/            # metafile de Fresh Animations: Player Extension (activado en options.txt)
├── config/                   # configs del pack (EU, ModernFix, Lithium, FTB Chunks, Artifacts, Illager Invasion, Cataclysm) → overrides/
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
bash scripts/check.sh    # descarga los 78 artefactos a .cache y valida todo; regenera la matriz
```
El resultado queda en `releases/vanilla-tech-<versión>.mrpack` (+ `.sha256`). El empaquetado es determinista: mismas entradas, mismo archivo.

> **packwiz** se descarga de un artefacto de CI que caduca el **2026-12-05**. Después de esa fecha, compílalo con `go install github.com/packwiz/packwiz@ef87d964f8cbd52b3b13ea42453ef322290e2b9e` y copia el binario a `.tools/packwiz`. Ver [known-issues.md](docs/known-issues.md).

### Scripts

| Script | Qué hace |
|---|---|
| `scripts/build.sh` | `bootstrap-tools.py` → `packwiz refresh` → `packwiz modrinth export` → `package.py` (mueve `options.txt` y los ajustes de shaders a `client-overrides/`, ordena el manifiesto y rechaza JARs embebidos). |
| `scripts/check.sh` | `fetch-artifacts.py`, `validate.py`, `check-ranges.py`, `worldgen-audit.py` y `gen-matrix.py`. |
| `scripts/prepare-server.sh` | Instala o actualiza un servidor desde la release (`--directory`, `--heap 3G…10G`, `--replace-configs`). Idempotente. Nunca acepta la EULA. |
| `scripts/test-server.sh` | Arranque acotado en `127.0.0.1:25575` sobre un directorio marcado con `.vanilla-tech-test-only`. Envía comandos de un archivo (`#sleep`, `#wait REGEX`) y guarda `docs/<name>.json`. |
| `scripts/integration-commands.txt` | Prueba de integración: estructuras vanilla, de Explorify, The Aether, Deep Aether, Deeper and Darker y de los mods de illagers y de L_Ender's Cataclysm, dimensiones del Aether y del Otherside, AE2, Create, Applied Create y colocación de bloques de los demás mods. |
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

## Versiones y ramas

| Línea | Rama | Para qué |
|---|---|---|
| `0.1.x` | `release/0.1` | Línea base: Create + AE2 + calidad de vida, **sin dimensiones nuevas** (última: 0.1.0-rc.5). |
| `0.2.x` | `release/0.2` | La base + The Aether (0.2.0). |
| `0.3.x` | `release/0.3` | + Deep Aether + Deeper and Darker (0.3.0). |
| `0.4.x` | `release/0.4` | **Estable actual**: + mobs, illagers, Artifacts, Storage Drawers, addons de Create y animaciones (0.4.0, validada por el usuario en el cliente). |
| `0.5.0-alpha.N` | `main` | Siguiente paso: L_Ender's Cataclysm y Just Hammers. Entre una alpha y otra se pueden agregar o quitar mods. |

- Cada release lleva una etiqueta anotada `v<versión>` (`git tag -n1` las lista) y una entrada en [CHANGELOG.md](CHANGELOG.md) con el SHA-256 del `.mrpack`.
- Para volver a una versión: usa su archivo en `releases/`, o `git checkout v<versión> && bash scripts/build.sh`, que lo reconstruye idéntico.
- Orden de madurez: `alpha` (en pruebas) → `beta` (contenido cerrado) → `rc` (probado en cliente y servidor) → versión final. Cuando el usuario valida una alpha en el cliente, se publica como versión estable con los mismos archivos; solo cambia el número.

**Mundos y versiones**
- Cada import en Prism crea una instancia aparte con el número de versión en el nombre. Las versiones anteriores siguen ahí para comparar.
- Los mundos creados con una **alpha** son de prueba. Si una versión posterior quita un mod de dimensión, Minecraft borra de ese mundo los bloques, ítems y entidades del mod, y el jugador que estaba en esa dimensión aparece en el Overworld.
- No abras un mundo con una versión **más vieja** que la última que lo guardó.
- El servidor real solo recibe versiones `rc` o finales, y siempre con backup previo ([installation.md](docs/installation.md#backups)).

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
8. Anota el cambio en `CHANGELOG.md`, haz commit y etiqueta la release (`git tag -a v<versión>`).

## Licencias y distribución

El repositorio solo contiene metadatos, configs y scripts. Los JARs se descargan de Modrinth o CurseForge desde sus CDNs oficiales y se verifican por hash; nunca se redistribuyen. Cada mod conserva su propia licencia (ver su página).
