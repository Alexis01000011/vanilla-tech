# Resultados de pruebas

Cada corrida deja un resumen JSON versionado en `docs/<nombre>.json`. Los logs completos (`docs/<nombre>.log`) se generan en local y no se versionan (`*.log` está en `.gitignore`).

## Etapa 1 — Dependencias (rc.4, 2026-10-09) ✅

`bash scripts/check.sh`:

| Comprobación | Resultado |
|---|---|
| Hashes de `index.toml`/`pack.toml` y de los 54 artefactos descargados (49 JARs + 5 shaderpacks) | PASS |
| Paridad metafiles ↔ `modrinth.index.json` (URL, lado cliente/servidor) | PASS |
| Ningún JAR embebido en el `.mrpack` | PASS |
| Dependencias obligatorias por lado, incluidas las de JARs anidados (jar-in-jar) | PASS |
| 258 rangos de versión con Maven `VersionRange` y la regla de alias de FML para 1.21.1 | PASS |
| Ningún archivo `data/minecraft/worldgen/**` sobrescrito por mods de servidor | PASS (no descarta cambios por código) |

## Etapa 2 — Servidor dedicado ✅

| Corrida | Release | Resultado | Evidencia |
|---|---|---|---|
| Primer arranque (Astra) | rc.1 | Arranca y para limpio; RSS 1253 MiB | `server-first-launch.json` |
| Smoke + bloques (Astra) | rc.1 | AE2 online, `locate` vanilla y Explorify OK | `server-smoke.json` |
| Primer arranque, **instalación limpia desde la release** con `prepare-server.py` | rc.2 | `Done` en 28.3 s; RSS 1086 MiB; FTB genera sus configs | `rc2-first-launch.json` |
| Integración + pregeneración | rc.2 | Todo OK salvo el montaje inicial de Applied Create (error de la prueba; ver abajo) | `rc2-integration.json` |
| Actualización in situ con `prepare-server.py` (agrega JEI, respeta la config reescrita por ModernFix) + integración corregida en mundo nuevo | rc.2 | Todo OK | `rc2-integration-2.json` |
| Actualización in situ a rc.3 (agrega Sophisticated Backpacks/Core y GraveStone) + integración en mundo nuevo | rc.3 | Todo OK; `Done` en 28.7 s; RSS 1224 MiB; 34 JARs | `rc3-integration.json` |
| Actualización in situ a rc.4 (agrega AE2 JEI Integration) + integración en mundo nuevo | rc.4 | Todo OK; `Done` en 29.5 s; RSS 1408 MiB; 35 JARs | `rc4-integration.json` |
| **Servidor real** (AWS r8i.large, itzg `TYPE=MODRINTH`, `MEMORY=8G`): instalación de 0.5.0-alpha.1 y pregeneración de 10 201 chunks del Overworld | 0.5.0-alpha.1 | Todo OK: 8 min 19 s (~20 chunks/s), sin "Can't keep up" ni errores; overrides `lithium.properties` y `cataclysm-common.toml` presentes en `config/`; el mixin de Lithium se desactiva; RSS plano en 6.77–6.88 GiB. Heap tras GC no medido | Reporte de la sesión que opera el servidor |
| Actualización in situ a **0.5.0-alpha.1** (L_Ender's Cataclysm + Lionfish API, Just Hammers) + integración en mundo nuevo | 0.5.0-alpha.1 | Todo OK: las estructuras de 0.4.0-alpha.1 en **las mismas coordenadas**; Cataclysm: Soul Black Smith a 913 bloques y Burning Arena a 2307 en el Nether, Ancient Factory a 2140 y Sunken City a 4681 en el Overworld (la Ruined Citadel no aparece cerca de esta semilla); checks de la base, las dimensiones y 0.4 OK. Segunda corrida con las configs de Lithium y Cataclysm: Lithium desactiva solo `world.game_events.dispatch` y ningún mod reescribe las configs. `Done` en 34.5–47.9 s; RSS 1970–2394 MiB (dos corridas, heap de 2 GiB); 53 JARs | `0.5.0-alpha.1-integration.json` |
| Actualización in situ a **0.4.0-alpha.1** (Storage Drawers, Friends & Foes, Illager Invasion, It Takes a Pillage, Artifacts, Create: Connected, Create Crafts & Additions; las configs de Artifacts e Illager Invasion se instalan y los mods no las reescriben) + integración en mundo nuevo | 0.4.0-alpha.1 | Todo OK: las 18 estructuras de 0.3.0 en **las mismas coordenadas**; illager_fort a 2817 bloques, bastille a 1144 e iceologer_cabin a 2519 (citadel no aparece cerca de esta semilla); cajón, motor eléctrico, caja de engranajes de latón y botón de cobre colocados; checks de la base y de las dimensiones OK. `Done` en 39.2 s; RSS 1679 MiB; 50 JARs | `0.4.0-alpha.1-integration.json` |
| Actualización in situ a **0.3.0-alpha.1** (Deep Aether, Deeper and Darker, TerraBlender; corrida con la candidata `0.2.0-alpha.2`, mismos archivos) + integración en mundo nuevo | 0.3.0-alpha.1 | Todo OK: las 18 estructuras de 0.2.0-alpha.1 en **las mismas coordenadas** (misma semilla); brass_dungeon a 1187 bloques, aerglow_forest a 340 y ancient_temple a 286 en el Otherside; dimensión Otherside cargada; checks de la base OK. `Done` en 57.6 s; RSS 1487 MiB; 41 JARs | `0.3.0-alpha.1-integration.json` |
| Actualización in situ a **0.2.0-alpha.1** (agrega The Aether + owo-lib) + integración en mundo nuevo | alpha.1 | Todo OK: 14 estructuras de la base + 4 de Aether (bronze 96, silver 121 y gold dungeon 887 bloques; large_aercloud), dimensión `aether:the_aether` cargada, Freezer colocado y los checks de la base; `Done` en 27.2 s; RSS 1395 MiB; 38 JARs | `alpha1-integration.json` |
| Actualización in situ a rc.5 (agrega Jade) + integración en mundo nuevo | rc.5 | Todo OK (14 estructuras, AE2, Create a 16 RPM, Applied Create, lápida y mochila); `Done` en 23.3 s; RSS 1364 MiB; 36 JARs. Jade carga los plugins de AE2, Extended AE, Waystones, GraveStone y Balm | `rc5-integration.json` |

La EULA se aceptó solo para estos servidores de prueba locales, desechables (marcados con `.vanilla-tech-test-only` y con autorización del propietario). Escuchan únicamente en `127.0.0.1`.

## Etapa 3 — Integración (por comandos, sin jugadores)

| Comprobación | Resultado | Evidencia en log |
|---|---|---|
| Mundo nuevo se crea y se guarda (overworld, nether, end, dimensiones de EU, spatial storage de AE2) | ✅ | `All dimensions are saved` |
| Red AE2 con celda creativa | ✅ controlador `state=online` | `VT_AE2_CONTROLLER_ONLINE` |
| Red cinética de Create (motor creativo → 2 ejes) | ✅ el segundo eje gira a 16 RPM | `has the following block data: 16.0f` |
| **AE2–Create (Applied Create)**: motor → `kinetic_energy_acceptor` → controlador, **sin** celda de energía | ✅ controlador online | `VT_APPLIEDCREATE_ACCEPTOR_POWERS_AE2` |
| Waystone, Charging Station y generador de Excessive Utilities se colocan | ✅ (solo colocación) | `Changed the block` |
| JEI carga en el servidor (rango 1.21 aceptado por FML) | ✅ | arranque sin errores |
| Lápida (GraveStone) y mochila (Sophisticated Backpacks) se colocan como bloques (rc.3) | ✅ (solo colocación) | `VT_GRAVESTONE_PLACED`, `VT_BACKPACK_PLACED` |
| Config de FTB Chunks del pack: instalada desde la release y **no reescrita** por FTB tras 2 arranques | ✅ (señal de que es válida) | mismo SHA-256 antes y después |
| Config de quarries de Excessive Utilities (0 bloques/tick) instalada desde la release | ✅ | `config/excessive_utilities-server.toml` |
| Chunky: 1681 chunks | ✅ 2 min 38 s, 20 TPS | `Task finished` |

**Nota sobre Applied Create**: en la primera corrida el controlador estaba en línea con el eje y no se conectó. La guía del mod (`ae2guide/kinetic_energy_acceptor.md`) indica que AE2 se conecta por las caras **perpendiculares** al eje. Con el controlador a un costado, la prueba pasó.

## Etapa 4 — Survival técnico: estructuras vanilla para granjas ✅ (generación)

`locate` con semilla `20261009`, igual en todas las corridas (rc.1, rc.2 y rc.3):

| Estructura | Distancia desde el origen |
|---|---|
| Monumento oceánico (guardianes) | 1569 |
| Fortaleza del Nether (blazes, wither skeletons) | 57 |
| Bastión | 724 |
| Stronghold | 1961 |
| Mina abandonada | 128 |
| Aldea de llanuras (aldeanos, golems de hierro) | 494 |
| Puesto de saqueadores (raids) | 1367 |
| Cabaña de bruja | 1470 |
| Ancient city | 1657 |
| Trial chambers | 329 |
| End city | 1195 |
| Explorify: ruins / tavern / farmstead | 918 / 1087 / 574 |

Que una estructura se genere **no prueba** que las granjas funcionen: las condiciones de spawn se comprueban jugando (pendiente P11).

## Etapa 5 — Cliente ✅ arranque y dimensión (pruebas en juego pendientes)

**rc.3, 2026-10-09** (usuario en la laptop; Prism con Java 21.0.7 gestionado por Prism):

| Comprobación | Resultado |
|---|---|
| Import del `.mrpack` en Prism y arranque | ✅ ~36 s desde el lanzamiento hasta el menú (log: 20:25:20 → 20:25:56) |
| Crear y entrar a un mundo nuevo | ✅ "todo perfecto", según el usuario |
| Errores en el log | Solo el plugin JEI de Applied Create (falta AE2 JEI Integration, añadida en rc.4) y avisos inofensivos (narrador, realms, consulta de versiones de Xaero) |
| Memoria (heap de 3900 MiB, el default global de Prism) | RSS de la JVM 2.7 GiB en el mundo; al sistema le quedaban 0.9 GiB; swap usada 2.2 GiB |

**0.2.0-alpha.1, 2026-10-09** (usuario; mismos archivos que la estable **0.2.0**):

| Comprobación | Resultado |
|---|---|
| Import y arranque | ✅ Prism carga los 67 mods que lista (incluye los que vienen dentro de otros JARs) |
| Mundo nuevo, entrar al Aether y volver | ✅ Log: entrada a `aether:the_aether` a las 16:06:52 y vuelta al Overworld a las 16:17:18 |
| AE2 JEI Integration | ✅ Registra su plugin y ya no aparece el error del plugin JEI de Applied Create |
| Errores en el log | Solo avisos inofensivos: narrador, realms, consulta de versiones de Xaero y 96 `X11: Standard cursor shape unavailable` |
| Memoria | La instancia seguía usando 3900 MiB (Prism global). RSS 2.7 GiB y 1.8 GiB de swap |

El usuario declaró estable esta versión y se publicó como **0.2.0**.

**0.3.0-alpha.1, 2026-10-09** (usuario; mismos archivos que la estable **0.3.0**):

| Comprobación | Resultado |
|---|---|
| Aether con Deep Aether | ✅ "todo funciona bien", según el usuario. Log: entrada al Aether y vuelta |
| Otherside (Deeper and Darker) | ✅ Log: entrada a `deeperdarker:otherside` a las 16:49 |
| Errores en el log | Ninguno nuevo; solo advertencias de modelos faltantes en 4 ítems de Deep Aether y el chequeo de versión de AeroBlender |
| Memoria | La instancia seguía usando 3900 MiB (Prism global) |

El usuario declaró estable esta versión y se publicó como **0.3.0**.

**0.4.0-alpha.1, 2026-10-09** (usuario; mismos archivos que la estable **0.4.0**): "todo bien". El log del cliente no muestra errores nuevos: solo las advertencias de modelos ya conocidas de Deep Aether y Excessive Utilities. Memoria todavía en 3900 MiB (Prism global). El usuario declaró estable esta versión y se publicó como **0.4.0**. Siguen pendientes las pruebas en juego P5–P11 y P13–P15.
