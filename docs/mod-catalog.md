# Catálogo de mods — Vanilla Tech 0.3.0-alpha.1

Minecraft **1.21.1** · NeoForge **21.1.257** · 60 artefactos fijados (55 mods + 5 shaderpacks) (`pin = true`).
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
| AE2 JEI Integration | 1.2.1 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ae2-jei-integration) | both | Integración AE2 ↔ JEI (AE2 para 1.21.1 solo integra EMI/REI): traslado de recetas con "+" a las terminales de crafteo y codificación de patrones; también la necesita el plugin JEI de Applied Create. |

## C. Utilidades, construcción y chunkloading

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| Waystones | 21.1.46 | [Modrinth](https://modrinth.com/mod/waystones) | both | Teletransporte entre piedras activadas. Requiere Balm. |
| Dank Storage | 20 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/dank-storage) | both | Contenedores portátiles de gran capacidad. |
| Building Gadgets 2 | 1.3.9 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/building-gadgets) | both | Herramientas de construcción, copia/pega y destrucción por área. Funcionan con energía FE. |
| Charging Gadgets | 1.14.1 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/charging-gadgets) | both | Estación de carga para los gadgets (con combustible o FE). |
| Excessive Utilities | 1.21.1-1.10.0-build.64 | [Modrinth](https://modrinth.com/mod/excessive-utilities) | both | Remake de Extra Utilities: Grid Power, generadores FE, Angel Ring, Transfer Nodes/tuberías, Trash Cans, etc. **Quarries desactivadas** (0 bloques/tick). Requiere Aaron, Curios y Kotlin for Forge. |
| Sophisticated Backpacks | 1.21.1-3.26.9.2195 | [Modrinth](https://modrinth.com/mod/sophisticated-backpacks) | both | Mochilas mejorables (cobre → netherite) con upgrades (imán, restock, alimentación, etc.). Se integran con Curios (ranura de espalda), JEI y Crafting Tweaks. Requiere Sophisticated Core. |
| GraveStone Mod | 1.21.1-1.0.40 | [Modrinth](https://modrinth.com/mod/gravestone-mod) | both | Al morir, una lápida guarda el inventario en vez de dejarlo tirado (que también guarde los Curios está pendiente de probar, P15). |
| FTB Chunks | 2101.1.22 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-chunks-forge) | both | Claim y chunkloading desde el mapa (tecla **J**). Límite de 100 chunks reclamados y 100 forzados por jugador. Requiere FTB Teams, FTB Library y Architectury. |

## D. Exploración y estructuras

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| Explorify | 1.6.5 | [Modrinth](https://modrinth.com/mod/explorify) | both | Estructuras pequeñas estilo vanilla (ruinas, tabernas, granjas, torres de vigilancia, campamentos…). Se instala como mod; no hace falta datapack. |
| YUNG's Extras | 1.21.1-5.1.1 | [Modrinth](https://modrinth.com/mod/yungs-extras) | both | Pequeños detalles de worldgen. |
| YUNG's Bridges | 1.21.1-5.1.1 | [Modrinth](https://modrinth.com/mod/yungs-bridges) | both | Puentes sobre ríos. |

## D2. Dimensiones

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| The Aether | 1.21.1-1.5.10 | [Modrinth](https://modrinth.com/mod/aether) | both | Dimensión de islas flotantes con portal de **marco de glowstone + agua**. Trae ores, mobs, 3 dungeons con jefes (bronce, plata y oro) y accesorios (guantes, anillos, colgantes, capas). No modifica el Overworld: solo agrega un tag aditivo de biomas para las ranas. Trae dentro Accessories 1.1.0-beta.48, Cumulus 2.0.7 y Nitrogen 1.1.25; requiere owo-lib. Licencia: código LGPL-3.0, assets ARR (el pack solo lo referencia, no lo redistribuye). |
| Deep Aether | 1.21.1-1.1.5.1 | [Modrinth](https://modrinth.com/mod/deep-aether) | both | Expansión del Aether: 11 biomas nuevos (bosques de aerglow, pantano de yagroot, golden heights, sacred lands…), materiales (skyjade, stratus), mobs, el Brass Dungeon y drops extra de los jefes. Sus biomas se reparten dentro del Aether con AeroBlender (incluido en su JAR); solo agrega features y mobs a biomas del Aether. Licencia LGPL-3.0. |
| Deeper and Darker | 1.4.1 | [Modrinth](https://modrinth.com/mod/deeperdarker) | both | Dimensión **Otherside**, a la que se llega activando el portal de reinforced deepslate de las ancient cities. Trae biomas, mobs, el Ancient Temple y equipo (Soul Elytra, Sculk Transmitter, armadura de warden). En el Overworld solo agrega **vasijas decorativas** (`ancient_vase`) a 17 piezas de muro de las ancient cities: la forma de la ciudad no cambia. No tiene dependencias. Licencia AGPL-3.0. |

## E. Inventario, recetas y navegación

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| Just Enough Items (JEI) | 19.51.0.418 | [Modrinth](https://modrinth.com/mod/jei) | both | Consulta de recetas. En el servidor habilita el traslado de recetas (botón "+"). |
| Inventory Profiles Next | 2.2.5 | [Modrinth](https://modrinth.com/mod/inventory-profiles-next) | client | Ordenamiento de inventario y perfiles. Requiere libIPN. |
| Crafting Tweaks | 21.1.11 | [Modrinth](https://modrinth.com/mod/crafting-tweaks) | both | Rotar, balancear y limpiar la cuadrícula de crafteo. Requiere Balm. |
| Jade | 15.10.6 | [Modrinth](https://modrinth.com/mod/jade) | both | Muestra qué bloque o entidad estás mirando, de qué mod es, la herramienta necesaria y su estado (progreso del horno, contenido de inventarios, energía). Trae soporte para AE2, Extended AE, Waystones, GraveStone y Balm. En el servidor es opcional, pero envía datos extra (contenido de inventarios). |
| Controlling | 19.0.5 | [Modrinth](https://modrinth.com/mod/controlling) | client | Buscador y filtro de conflictos en *Opciones → Controles*, para que cada jugador cambie atajos con facilidad. Requiere Searchables. |
| Xaero's Minimap | 26.6.0 | [Modrinth](https://modrinth.com/mod/xaeros-minimap) | client | Minimapa (el único activo: el de FTB Chunks se desactiva desde el servidor). |
| Just Zoom | 2.1.0 | [Modrinth](https://modrinth.com/mod/just-zoom) | client | Zoom simple (tecla **C**, rueda para acercar o alejar). Requiere Konkrete. |
| Xaero's World Map | 1.47.0 | [Modrinth](https://modrinth.com/mod/xaeros-world-map) | client | Mapa del mundo (tecla M). |

## F. Rendimiento y diagnóstico

| Mod | Versión | Fuente | Side | Para qué |
|---|---|---|---|---|
| Sodium | 0.6.13 | [Modrinth](https://modrinth.com/mod/sodium) | client | Motor de renderizado. Create (Flywheel) lo soporta oficialmente. Se usa la 0.6.13 (y no la 0.8.13) porque es la que soporta Iris estable. |
| Iris Shaders | 1.8.12 | [Modrinth](https://modrinth.com/mod/iris) | client | Soporte de shaders. **Apagados por defecto**; K los activa o desactiva. Flywheel (Create) detecta Iris y cambia de backend cuando hay un shader activo. |
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
| Sophisticated Core | 1.21.1-1.5.7.2381 | [Modrinth](https://modrinth.com/mod/sophisticated-core) | both | Sophisticated Backpacks |
| Konkrete | 1.9.9 | [Modrinth](https://modrinth.com/mod/konkrete) | client | Just Zoom |
| Searchables | 1.0.2 | [Modrinth](https://modrinth.com/mod/searchables) | client | Controlling |
| GuideME | 21.1.19 | [Modrinth](https://modrinth.com/mod/guideme) | both | AE2 |
| Glodium | 1.21-2.2 | [Modrinth](https://modrinth.com/mod/glodium) | both | Extended AE |
| Kotlin for Forge | 5.12.0 | [Modrinth](https://modrinth.com/mod/kotlin-for-forge) | both | Applied Create, Excessive Utilities, Aaron |
| Aaron | 1.21.1-1.21.0-build.39 | [Modrinth](https://modrinth.com/mod/aaron) | both | Excessive Utilities |
| Curios API | 9.5.1 | [Modrinth](https://modrinth.com/mod/curios) | both | Excessive Utilities |
| Balm | 21.0.66 | [Modrinth](https://modrinth.com/mod/balm) | both | Waystones, Crafting Tweaks |
| libIPN | 6.6.3 | [Modrinth](https://modrinth.com/mod/libipn) | client | Inventory Profiles Next |
| YUNG's API | 1.21.1-5.1.9 | [Modrinth](https://modrinth.com/mod/yungs-api) | both | YUNG's Extras, YUNG's Bridges |
| FTB Library | 2101.1.37 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-library-forge) | both | FTB Chunks, FTB Teams (FTB JEI Extras no la declara ni la usa en su código) |
| FTB Teams | 2101.1.11 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-teams-forge) | both | FTB Chunks |
| TerraBlender | 4.1.0.8 | [Modrinth](https://modrinth.com/mod/terrablender) | both | Deep Aether, que también trae la 4.1.0.3 dentro; NeoForge elige la 4.1.0.8. No registra regiones en el Overworld: las estructuras salen en las mismas coordenadas que sin él. En Modrinth, todas sus versiones para 1.21.1 están marcadas como beta. |
| owo-lib | 0.12.15.5-beta.1+1.21 | [Modrinth](https://modrinth.com/mod/owo-lib) | both | Accessories (que viene dentro de The Aether). Solo hay versiones beta para NeoForge; es la que exige la página de The Aether. |
| Architectury API | 13.0.11 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/architectury-api) | both | FTB Library, FTB Chunks, FTB Teams |

## H. Shaderpacks (solo cliente, apagados por defecto)

Los mismos que el usuario tenía en su instancia 1.21.11, identificados en Modrinth por hash (misma versión exacta). Se descargan de Modrinth; el pack solo incluye los ajustes guardados de MakeUp y Mellow (`shaderpacks/*.zip.txt`).

| Shaderpack | Versión | Fuente | Licencia | Nota |
|---|---|---|---|---|
| MakeUp – Ultra Fast | 9.5a | [Modrinth](https://modrinth.com/shader/makeup-ultra-fast-shaders) | LGPL-3.0 | Ligero; con los ajustes del usuario. |
| Mellow | 3.2 | [Modrinth](https://modrinth.com/shader/mellow) | MIT | Con los ajustes del usuario (SSAO, reflejos, TAA). |
| Miniature | 2.18.11 | [Modrinth](https://modrinth.com/shader/miniature-shader) | MIT | Ligero. |
| Sildur's Basic Shaders | 2.6 Fancy | [Modrinth](https://modrinth.com/shader/sildurs-basic-shaders) | ARR | Ligero. |
| Sildur's Vibrant Shaders | 1.56 Extreme | [Modrinth](https://modrinth.com/shader/sildurs-vibrant-shaders) | ARR | **Pesado** para una iGPU. |

## Rechazados o no incluidos

| Mod | Motivo |
|---|---|
| Create: Applied Kinetics | Redundante con Applied Create, que funciona en las versiones fijadas. No se instalan ambos. |
| AEInfinityBooster | Redundante: la Quantum Bridge Card de ae2wtlib ya da alcance infinito e interdimensional. |
| Advanced AE | Sin necesidad funcional que Extended AE no cubra. |
| EMI, REI | JEI es el visor elegido; no se instalan dos visores de recetas. AE2 1.21.1 integra EMI de forma nativa, pero se mantuvo JEI y se añadió AE2 JEI Integration para no cambiar de visor. |
| Terralith, Tectonic, Structory | Excluidos por el plan: cambian el terreno o los biomas vanilla. |
| Lootr | Excluido por el plan. |
| YUNG's Better Ocean Monuments / Nether Fortresses / Mineshafts / Strongholds y similares | Reemplazan estructuras vanilla de las que dependen las granjas. |
| Phosphor, Starlight | Obsoletos en 1.21.1 (el motor de luz vanilla ya incorpora esas mejoras). |
| Mekanism, Thermal, RFTools | Sistemas industriales grandes; fuera de alcance. La energía FE sale de Excessive Utilities y la de AE2 de Create vía Applied Create. |
| Just Zoom 3.x | La 3.0.0 es una reescritura publicada el 2026-10-03, con un crash corregido en 3.0.1 al día siguiente, y agrega una tecla de configuración en **B**, que ya está ocupada. Se fijó la 2.1.0 (marzo de 2025). |
| Ok Zoomer | Solo hay versión beta para NeoForge 1.21.1. |
| Sophisticated Backpacks Create Integration | No se pidió; se puede añadir si se quieren mochilas en contraptions. |
| Iris 1.8.14-beta.1 + Sodium 0.8.13 | La única Iris para Sodium 0.8 en 1.21.1 es beta y no declara rango contra Sodium 0.8.13. Se eligió la pareja estable Sodium 0.6.13 + Iris 1.8.12. |
| WTHIT, The One Probe | Alternativas a Jade. Jade es el más usado en 1.21.1 y AE2, Waystones y GraveStone ya traen su integración. |
| Open Parties and Claims | Alternativa a FTB Chunks con integración nativa en Xaero; el usuario prefirió FTB Chunks. |
