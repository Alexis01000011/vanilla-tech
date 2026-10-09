# Resultados de pruebas

Cada corrida deja un resumen JSON versionado en `docs/<nombre>.json`. Los logs completos (`docs/<nombre>.log`) se generan en local y no se versionan (`*.log` está en `.gitignore`).

## Etapa 1 — Dependencias (rc.2, 2026-10-09) ✅

`bash scripts/check.sh`:

| Comprobación | Resultado |
|---|---|
| Hashes de `index.toml`/`pack.toml` y de los 40 JARs descargados | PASS |
| Paridad metafiles ↔ `modrinth.index.json` (URL, lado cliente/servidor) | PASS |
| Ningún JAR embebido en el `.mrpack` | PASS |
| Dependencias obligatorias por lado, incluidas las de JARs anidados (jar-in-jar) | PASS |
| 220 rangos de versión con Maven `VersionRange` y la regla de alias de FML para 1.21.1 | PASS |
| Ningún archivo `data/minecraft/worldgen/**` sobrescrito por mods de servidor | PASS (no descarta cambios por código) |

## Etapa 2 — Servidor dedicado ✅

| Corrida | Release | Resultado | Evidencia |
|---|---|---|---|
| Primer arranque (Astra) | rc.1 | Arranca y para limpio; RSS 1253 MiB | `server-first-launch.json` |
| Smoke + bloques (Astra) | rc.1 | AE2 online, `locate` vanilla y Explorify OK | `server-smoke.json` |
| Primer arranque, **instalación limpia desde la release** con `prepare-server.py` | rc.2 | `Done` en 28.3 s; RSS 1086 MiB; FTB genera sus configs | `rc2-first-launch.json` |
| Integración + pregeneración | rc.2 | Todo OK salvo el montaje inicial de Applied Create (error de la prueba; ver abajo) | `rc2-integration.json` |
| Actualización in situ con `prepare-server.py` (agrega JEI, respeta la config reescrita por ModernFix) + integración corregida en mundo nuevo | rc.2 | Todo OK | `rc2-integration-2.json` |

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
| Config de FTB Chunks del pack: instalada desde la release y **no reescrita** por FTB tras 2 arranques | ✅ (señal de que es válida) | mismo SHA-256 antes y después |
| Config de quarries de Excessive Utilities (0 bloques/tick) instalada desde la release | ✅ | `config/excessive_utilities-server.toml` |
| Chunky: 1681 chunks | ✅ 2 min 38 s, 20 TPS | `Task finished` |

**Nota sobre Applied Create**: en la primera corrida el controlador estaba en línea con el eje y no se conectó. La guía del mod (`ae2guide/kinetic_energy_acceptor.md`) indica que AE2 se conecta por las caras **perpendiculares** al eje. Con el controlador a un costado, la prueba pasó.

## Etapa 4 — Survival técnico: estructuras vanilla para granjas ✅ (generación)

`locate` con semilla `20261009`, igual en las tres corridas:

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

## Etapa 5 — Cliente ⏳ pendiente

Requiere al usuario frente a la laptop. Plan: importar el `.mrpack` en Prism, arrancar, revisar controles, entrar a un mundo nuevo, medir según [performance.md](performance.md#cómo-medir-en-la-prueba-de-cliente-p2) y probar en juego P5–P11.
