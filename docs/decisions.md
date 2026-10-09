# Bitácora de decisiones técnicas

Registro breve, en orden cronológico, de las decisiones que afectan versiones, contenido o configuración. Sirve para entender *por qué* el pack está como está antes de actualizarlo.

| Fecha | Decisión | Motivo / evidencia |
|---|---|---|
| 2026-10-09 | Minecraft 1.21.1 + NeoForge **21.1.257**, Java 21. | Requisito firme del proyecto. 21.1.257 cumple el mínimo más alto exigido por los mods (Create ≥ 21.1.219, JEI ≥ 21.1.238). |
| 2026-10-09 | packwiz fijado al commit `ef87d96` (binario de CI) en `.tools/`. | No había release etiquetada reciente; el binario se verifica por SHA-256 (`research/packwiz.json`). Ver riesgo en `known-issues.md`. |
| 2026-10-09 | Todos los metafiles con `pin = true` y URL de descarga explícita. | Release cerrada: `packwiz update` no debe mover versiones sin decisión explícita. |
| 2026-10-09 | El `.mrpack` nunca incluye JARs; `scripts/package.py` aborta si encuentra uno. | No redistribuir archivos de terceros. Los launchers descargan desde Modrinth/CurseForge. |
| 2026-10-09 | `options.txt` va en `client-overrides/`, no en `overrides/`. | Es configuración de cliente; no debe copiarse al servidor. |
| 2026-10-09 | **Applied Create** como integración AE2–Create (no Create: Applied Kinetics). | Disponible para 1.21.1/NeoForge con rangos compatibles; aporta `kinetic_energy_acceptor` (rotación de Create → energía AE2), lo que evita meter otro mod de energía. No se instalan ambos. |
| 2026-10-09 | Alcance inalámbrico infinito/interdimensional con la **Quantum Bridge Card** de AE2 Wireless Terminals; **no** AEInfinityBooster. | ae2wtlib ya trae la función; añadir AEInfinityBooster sería redundante. |
| 2026-10-09 | Sin Advanced AE. | No hay necesidad funcional que Extended AE no cubra. |
| 2026-10-09 | **FTB JEI Extras** (+ FTB Library + Architectury). | Extended AE dejó de integrar JEI en 1.21; su propia página recomienda FTB JEI Extras para recuperar sus recetas en JEI. Confirmado por el usuario. |
| 2026-10-09 | **Charging Gadgets** para recargar Building Gadgets 2. | BG2 usa energía FE y no trae cargador propio; Charging Gadgets quema combustible o acepta FE. |
| 2026-10-09 | **Excessive Utilities** aceptado como excepción, aunque añade 3 dimensiones (`the_depths`, `quantum_quarry`, `the_last_millennium`). | Aporta Grid Power, generadores, Angel Ring, Transfer Nodes y Trash Cans pedidos en el plan. Ender Quarry y Quantum Quarry a **0 bloques/tick** en `config/excessive_utilities-server.toml` (las quarries no son prioridad y rompen la progresión vanilla). |
| 2026-10-09 | ModernFix: `mixin.perf.remove_biome_temperature_cache=false` y `mixin.bugfix.paper_chunk_patches=false`. | El primer arranque registró *Method overwrite conflict* entre ModernFix y Lithium en ambos métodos; se deja la implementación de Lithium. |
| 2026-10-09 | Explorify como **mod** (JAR), no como datapack. | Un solo artefacto para cliente y servidor, gestionado igual que el resto; sin pasos manuales en el mundo. |
| 2026-10-09 | Se conserva el pin de JEI 19.51.0.418 aunque declara `minecraft [1.21,1.21.1)`. | FML 4 (`VersionSupportMatrix`) acepta explícitamente rangos de 1.21 en 1.21.1; `scripts/CheckRanges.java` replica esa regla. Se confirmó en el arranque del servidor. |
| 2026-10-09 | Release **0.1.0-rc.2**. | rc.1 se exportó antes de indexar las configs de Excessive Utilities/ModernFix y los atajos: la release no llevaba los límites de las quarries. |
| 2026-10-09 | Atajos: Building Gadgets *Settings* **G → K**; mapa de FTB Chunks **M → J**. | Curios usa G por defecto y el World Map de Xaero usa M (defaults leídos del bytecode de cada mod). |
| 2026-10-09 | **FTB Chunks** + FTB Teams añadidos (petición del usuario) para chunkloading desde una interfaz. | Ver configuración abajo. Alternativa no elegida: Open Parties and Claims (integra con los mapas de Xaero, pero el usuario pidió FTB Chunks). |
| 2026-10-09 | FTB Chunks: `max_claimed_chunks = 100`, `max_force_loaded_chunks = 100`, `party_limit_mode = "sum"`. | "100 chunks por usuario". Con `sum`, si ambos jugadores forman un *party*, el equipo dispone de 100 + 100. |
| 2026-10-09 | FTB Chunks: `force_load_mode = "never"`. | Los chunks forzados funcionan solo mientras haya un miembro del equipo conectado. Evita que el servidor consuma CPU (y créditos en instancias *burstable*) sin jugadores. Cambiar a `"always"` si se quieren granjas 24/7. |
| 2026-10-09 | FTB Chunks: `disable_protection = true`. | Servidor privado de dos jugadores de confianza; los claims se usan solo para chunkloading. Evita que la protección bloquee *fake players* (deployers de Create, planos de formación de AE2, Mechanical User de EU) y mantiene explosiones/pistones vanilla. |
| 2026-10-09 | FTB Chunks: `force_disable_minimap = true`. | Xaero's Minimap es el minimapa elegido; se evita un segundo minimapa. El mapa grande de FTB (tecla J) sigue disponible para reclamar chunks. |
| 2026-10-09 | JEI pasa de `client` a **`both`**. | El traslado de recetas (botón "+") requiere JEI en el servidor (`jei.tooltip.error.recipe.transfer.no.server`). |
| 2026-10-09 | `prepare-server.py` guarda `.vanilla-tech-installed.json` con los hashes instalados. | ModernFix reescribe su config al arrancar; sin ese registro, cualquier actualización se bloqueaba por "config distinta". Ahora solo se detiene si el pack **y** el admin cambiaron el mismo archivo. |
| 2026-10-09 | Operador del servidor previsto: **`imalexisxo`**. | Se configura en el servidor real (`/op imalexisxo` desde la consola), no en el modpack: `ops.json` necesita el UUID de la cuenta. |
