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

## Etapa 5 — Cliente 🟡 parcial

**rc.3, 2026-10-09** (usuario en la laptop; Prism con Java 21.0.7 gestionado por Prism):

| Comprobación | Resultado |
|---|---|
| Import del `.mrpack` en Prism y arranque | ✅ ~36 s desde el lanzamiento hasta el menú (log: 20:25:20 → 20:25:56) |
| Crear y entrar a un mundo nuevo | ✅ "todo perfecto", según el usuario |
| Errores en el log | Solo el plugin JEI de Applied Create (falta AE2 JEI Integration, añadida en rc.4) y avisos inofensivos (narrador, realms, consulta de versiones de Xaero) |
| Memoria (heap de 3900 MiB, el default global de Prism) | RSS de la JVM 2.7 GiB en el mundo; al sistema le quedaban 0.9 GiB; swap usada 2.2 GiB |

**rc.4 y rc.5**: pendientes de importar (rc.4 no llegó a probarse en el cliente; basta con probar la versión más nueva) (P16–P18 en [known-issues.md](known-issues.md)). Siguen pendientes las pruebas en juego P5–P11 y P13–P15.
