# Catálogo de mods — Vanilla Tech 0.1.0-rc.2

Minecraft **1.21.1** · NeoForge **21.1.257** · 40 artefactos fijados (`pin = true`).
Fuente de verdad: los metafiles de `mods/*.pw.toml`. Este documento explica *qué* aporta cada mod y *por qué* está en el pack.

**Side**: `both` = cliente y servidor · `client` = solo cliente (el servidor no lo instala) · `server` = solo servidor.

## A. Tecnología (núcleo)

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| Create | 6.0.10 | [Modrinth](https://modrinth.com/mod/create) | both | Mecánica rotacional, contraptions y automatización. Incluye internamente Flywheel 1.0.6 y Ponder 1.0.82. |
| Applied Energistics 2 | 19.2.18 | [Modrinth](https://modrinth.com/mod/ae2) | both | Almacenamiento digital y autocrafteo. Requiere GuideME. |
| Applied Create | 1.1.7 | [Modrinth](https://modrinth.com/mod/applied-create) | both | Puente AE2–Create: `kinetic_energy_acceptor` (rotación → energía AE2), Pattern Providers de andesita/latón, ME Gearbox, ME Blueprint Cannon, Spatial Assembler. |

## B. Addons de AE2

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| AE2 Wireless Terminals (ae2wtlib) | 19.5.1 | [Modrinth](https://modrinth.com/mod/applied-energistics-2-wireless-terminals) | both | Terminal universal, terminales inalámbricas de patrones, **Quantum Bridge Card** (alcance infinito e interdimensional), Magnet Card, restock. |
| Extended AE | 1.21-2.2.35 | [Modrinth](https://modrinth.com/mod/extended-ae) | both | Pattern Providers/Interfaces de 36 slots, Extended Pattern Access Terminal, Pattern Modifier, ensambladores paralelos, buses avanzados. Requiere Glodium. |
| FTB JEI Extras | 21.1.7 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-jei-extras) | client | Recetas de Extended AE en JEI (Extended AE dejó de integrarse con JEI en 1.21). |

## C. Utilidades, construcción y chunkloading

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| Waystones | 21.1.46 | [Modrinth](https://modrinth.com/mod/waystones) | both | Teletransporte entre piedras activadas. Requiere Balm. |
| Dank Storage | 20 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/dank-storage) | both | Contenedores portátiles de gran capacidad. |
| Building Gadgets 2 | 1.3.9 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/building-gadgets) | both | Herramientas de construcción, copia/pega y destrucción por área. Funcionan con energía FE. |
| Charging Gadgets | 1.14.1 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/charging-gadgets) | both | Estación de carga para los gadgets (con combustible o FE). |
| Excessive Utilities | 1.21.1-1.10.0-build.64 | [Modrinth](https://modrinth.com/mod/excessive-utilities) | both | Remake de Extra Utilities: Grid Power, generadores FE, Angel Ring, Transfer Nodes/tuberías, Trash Cans, etc. **Quarries desactivadas** (0 bloques/tick). Requiere Aaron, Curios y Kotlin for Forge. |
| FTB Chunks | 2101.1.22 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-chunks-forge) | both | Claim y chunkloading desde el mapa (tecla **J**). Límite de 100 chunks reclamados y 100 forzados por jugador. Requiere FTB Teams, FTB Library y Architectury. |

## D. Exploración y estructuras

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| Explorify | 1.6.5 | [Modrinth](https://modrinth.com/mod/explorify) | both | Estructuras pequeñas estilo vanilla (ruinas, tabernas, granjas, torres de vigilancia, campamentos…). Se instala como mod; no hace falta datapack. |
| YUNG's Extras | 1.21.1-5.1.1 | [Modrinth](https://modrinth.com/mod/yungs-extras) | both | Pequeños detalles de worldgen. |
| YUNG's Bridges | 1.21.1-5.1.1 | [Modrinth](https://modrinth.com/mod/yungs-bridges) | both | Puentes sobre ríos. |

## E. Inventario, recetas y navegación

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| Just Enough Items (JEI) | 19.51.0.418 | [Modrinth](https://modrinth.com/mod/jei) | both | Consulta de recetas. En el servidor habilita el traslado de recetas (botón "+"). |
| Inventory Profiles Next | 2.2.5 | [Modrinth](https://modrinth.com/mod/inventory-profiles-next) | client | Ordenamiento de inventario y perfiles. Requiere libIPN. |
| Crafting Tweaks | 21.1.11 | [Modrinth](https://modrinth.com/mod/crafting-tweaks) | both | Rotar, balancear y limpiar la cuadrícula de crafteo. Requiere Balm. |
| Xaero's Minimap | 26.6.0 | [Modrinth](https://modrinth.com/mod/xaeros-minimap) | client | Minimapa (el único activo: el de FTB Chunks se desactiva desde el servidor). |
| Xaero's World Map | 1.47.0 | [Modrinth](https://modrinth.com/mod/xaeros-world-map) | client | Mapa del mundo (tecla M). |

## F. Rendimiento y diagnóstico

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| Sodium | 0.8.13 | [Modrinth](https://modrinth.com/mod/sodium) | client | Motor de renderizado. Create (Flywheel) lo soporta oficialmente. |
| Lithium | 0.15.4 | [Modrinth](https://modrinth.com/mod/lithium) | both | Optimización de lógica de servidor (ticks, IA, colisiones). |
| FerriteCore | 7.0.3 | [Modrinth](https://modrinth.com/mod/ferrite-core) | both | Reduce memoria de estados de bloque y modelos. |
| ModernFix | 5.27.26 | [Modrinth](https://modrinth.com/mod/modernfix) | both | Arranque más rápido y menos memoria. Dos mixins desactivados por conflicto con Lithium. |
| ImmediatelyFast | 1.6.14 | [Modrinth](https://modrinth.com/mod/immediatelyfast) | client | Optimiza el renderizado inmediato (HUD, texto, mapas). |
| Entity Culling | 1.11.3 | [Modrinth](https://modrinth.com/mod/entityculling) | client | No dibuja entidades ni *block entities* ocultas. |
| Dynamic FPS | 3.11.4 | [Modrinth](https://modrinth.com/mod/dynamic-fps) | client | Baja los FPS con la ventana sin foco o minimizada. |
| spark | 1.10.124 | [Modrinth](https://modrinth.com/mod/spark) | both | Perfilador: `/spark tps`, `/spark profiler`, `/spark health`. |
| Chunky | 1.4.23 | [Modrinth](https://modrinth.com/mod/chunky) | server | Pregeneración controlada de chunks. |

## G. Bibliotecas (dependencias obligatorias verificadas en los JARs)

| Biblioteca | Versión | Fuente | Side | Requerida por |
|---|---|---|---|---|
| GuideME | 21.1.19 | [Modrinth](https://modrinth.com/mod/guideme) | both | AE2 |
| Glodium | 1.21-2.2 | [Modrinth](https://modrinth.com/mod/glodium) | both | Extended AE |
| Kotlin for Forge | 5.12.0 | [Modrinth](https://modrinth.com/mod/kotlin-for-forge) | both | Applied Create, Excessive Utilities, Aaron |
| Aaron | 1.21.1-1.21.0-build.39 | [Modrinth](https://modrinth.com/mod/aaron) | both | Excessive Utilities |
| Curios API | 9.5.1 | [Modrinth](https://modrinth.com/mod/curios) | both | Excessive Utilities |
| Balm | 21.0.66 | [Modrinth](https://modrinth.com/mod/balm) | both | Waystones, Crafting Tweaks |
| libIPN | 6.6.3 | [Modrinth](https://modrinth.com/mod/libipn) | client | Inventory Profiles Next |
| YUNG's API | 1.21.1-5.1.9 | [Modrinth](https://modrinth.com/mod/yungs-api) | both | YUNG's Extras, YUNG's Bridges |
| FTB Library | 2101.1.37 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-library-forge) | both | FTB Chunks, FTB Teams, FTB JEI Extras |
| FTB Teams | 2101.1.11 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-teams-forge) | both | FTB Chunks |
| Architectury API | 13.0.11 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/architectury-api) | both | FTB Library, FTB Chunks, FTB Teams |

## Rechazados o no incluidos

| Mod | Motivo |
|---|---|
| Create: Applied Kinetics | Redundante con Applied Create, que funciona en las versiones fijadas. No se instalan ambos. |
| AEInfinityBooster | Redundante: la Quantum Bridge Card de ae2wtlib ya da alcance infinito e interdimensional. |
| Advanced AE | Sin necesidad funcional que Extended AE no cubra. |
| EMI, REI | JEI es el visor elegido; no se instalan dos visores de recetas. |
| Terralith, Tectonic, Structory | Excluidos por el plan: cambian el terreno o los biomas vanilla. |
| Lootr | Excluido por el plan. |
| YUNG's Better Ocean Monuments / Nether Fortresses / Mineshafts / Strongholds y similares | Reemplazan estructuras vanilla de las que dependen las granjas. |
| Phosphor, Starlight | Obsoletos en 1.21.1 (el motor de luz vanilla ya incorpora esas mejoras). |
| Mekanism, Thermal, RFTools | Sistemas industriales grandes; fuera de alcance. La energía FE sale de Excessive Utilities y la de AE2 de Create vía Applied Create. |
| Open Parties and Claims | Alternativa a FTB Chunks con integración nativa en Xaero; el usuario prefirió FTB Chunks. |
