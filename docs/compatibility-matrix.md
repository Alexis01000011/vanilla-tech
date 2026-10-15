# Matriz de compatibilidad — Vanilla Tech 0.7.0

Minecraft 1.21.1 · NeoForge 21.1.257 · 85 artefactos fijados.
Generada por `scripts/gen-matrix.py`; no editar a mano. Los estados viven en `docs/test-status.toml`.

**Estados**
- **Verified**: hashes, metadatos, lado (cliente/servidor) y rangos de versión comprobados (`validate.py`, `check-ranges.py`).
- **Launch tested**: cargó sin errores en un arranque real de NeoForge (servidor dedicado o cliente en Prism). La columna *Evidencia* indica qué más se comprobó por comandos.
- **Gameplay tested**: funcionalidad probada por un jugador dentro del juego.
- **Blocked**: problema abierto.

El cliente **0.4.0-alpha.1** (mismos mods que 0.4.0) arrancó en Prism y entró al mundo; antes, 0.3.0-alpha.1 entró al Aether y al Otherside (2026-10-09). Los mods agregados en 0.5.0-alpha.1 solo están probados en el servidor; las pruebas en juego siguen pendientes ([known-issues.md](known-issues.md)). Las dependencias se leen de `META-INF/neoforge.mods.toml` en cada JAR, sin contar las bibliotecas que el propio JAR trae embebidas (jar-in-jar).

| Mod | Versión | Fuente | Dependencias obligatorias | Side | Estado | Evidencia |
|---|---|---|---|---|---|---|
| Aaron | 1.21.0 | [Modrinth](https://modrinth.com/mod/aaron) | Kotlin for Forge | both | Launch tested | Servidor carga |
| AE2 JEI Integration | 1.2.1 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ae2-jei-integration) | Applied Energistics 2, Just Enough Items (JEI) | both | Launch tested | Servidor y cliente 0.2.0-alpha.1: registra su plugin JEI; desaparece el error de Applied Create. Botón + sin probar |
| AmbientSounds | 6.3.10 | [Modrinth](https://modrinth.com/mod/ambientsounds) | CreativeCore | client | Verified |  |
| Applied Create | 1.1.7 | [Modrinth](https://modrinth.com/mod/applied-create) | Applied Energistics 2, Create, Kotlin for Forge | both | Launch tested | Servidor: la rotación de Create (16 RPM) enciende un controlador AE2 vía kinetic_energy_acceptor, sin celda de energía |
| Applied Energistics 2 | 19.2.18 | [Modrinth](https://modrinth.com/mod/ae2) | GuideME | both | Launch tested | Servidor: controlador online con celda creativa |
| Applied Energistics 2 Wireless Terminals | 19.5.1 | [Modrinth](https://modrinth.com/mod/applied-energistics-2-wireless-terminals) | Applied Energistics 2 | both | Launch tested | Servidor carga; Quantum Bridge Card y receta presentes en el JAR |
| Architectury API | 13.0.11 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/architectury-api) | — | both | Launch tested | Servidor carga |
| Artifacts | 13.2.5 | [Modrinth](https://modrinth.com/mod/artifacts) | — | both | Launch tested | Servidor 0.4.0-alpha.1 carga con Curios y sin compatibilidad con Accessories; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| Balm | 21.0.66 | [Modrinth](https://modrinth.com/mod/balm) | — | both | Launch tested | Servidor carga |
| Building Gadgets | 1.3.9 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/building-gadgets) | — | both | Launch tested | Servidor carga |
| Charging Gadgets | 1.14.1 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/charging-gadgets) | — | both | Launch tested | Servidor: estación colocada |
| Chunky | 1.4.23 | [Modrinth](https://modrinth.com/mod/chunky) | — | server | Launch tested | Servidor: pregeneración de 1681 chunks |
| Cirrus | 1.4.1 | [Modrinth](https://modrinth.com/mod/cirrus) | Architectury API, YetAnotherConfigLib (YACL) | client | Verified |  |
| Controlling | 19.0.5 | [Modrinth](https://modrinth.com/mod/controlling) | Searchables | client | Launch tested | Cliente 0.2.0-alpha.1 arranca |
| Crafting Tweaks | 21.1.11 | [Modrinth](https://modrinth.com/mod/crafting-tweaks) | Balm | both | Launch tested | Servidor carga |
| Create | 6.0.10 | [Modrinth](https://modrinth.com/mod/create) | — | both | Launch tested | Servidor: red cinética, eje a 16 RPM desde motor creativo |
| Create Crafts & Additions | 1.6.0 | [Modrinth](https://modrinth.com/mod/createaddition) | Create | both | Launch tested | Servidor 0.4.0-alpha.1: motor eléctrico colocado; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| Create: Connected | 1.3.3-mc1.21.1 | [Modrinth](https://modrinth.com/mod/create-connected) | Create | both | Launch tested | Servidor 0.4.0-alpha.1: caja de engranajes de latón colocada; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| Create: Ultimate Factory | 2.2.4 | [Modrinth](https://modrinth.com/mod/create-ultimate-factory) | — | both | Verified |  |
| CreativeCore | 2.13.51 | [Modrinth](https://modrinth.com/mod/creativecore) | — | client | Verified |  |
| Curios API | 9.5.1+1.21.1 | [Modrinth](https://modrinth.com/mod/curios) | — | both | Launch tested | Servidor carga |
| Dank Storage | 20 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/dank-storage) | — | both | Launch tested | Servidor carga |
| Deep Aether | 1.21.1-1.1.5.1 | [Modrinth](https://modrinth.com/mod/deep-aether) | The Aether | both | Gameplay tested | Cliente 0.3.0-alpha.1 (usuario): Aether con contenido nuevo. Servidor: brass_dungeon y aerglow_forest ubicados |
| Deeper and Darker | 1.4.1 | [Modrinth](https://modrinth.com/mod/deeperdarker) | — | both | Gameplay tested | Cliente 0.3.0-alpha.1 (usuario): entrada al Otherside. Servidor: dimensión cargada y ancient_temple ubicado |
| Dynamic FPS | 3.11.4 | [Modrinth](https://modrinth.com/mod/dynamic-fps) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| ElevatorMod | 1.21.1-1.11.4 | [Modrinth](https://modrinth.com/mod/elevatormod) | — | both | Verified |  |
| EMF Compat: Core | 2.3.0 | [Modrinth](https://modrinth.com/mod/emf-compat-core) | Entity Model Features | client | Launch tested | Solo cliente; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| EMF Compat: Not Enough Animations | 1.2.1 | [Modrinth](https://modrinth.com/mod/not-enough-animations-emf-compat) | EMF Compat: Core, Entity Model Features, Not Enough Animations | client | Launch tested | Solo cliente; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| Entity Culling | 1.11.3 | [Modrinth](https://modrinth.com/mod/entityculling) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Entity Model Features | 3.3.11 | [Modrinth](https://modrinth.com/mod/entity-model-features) | Entity Texture Features | client | Launch tested | Solo cliente; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| Entity Texture Features | 7.2.5 | [Modrinth](https://modrinth.com/mod/entitytexturefeatures) | — | client | Launch tested | Solo cliente; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| Excessive Utilities | 1.10.0 | [Modrinth](https://modrinth.com/mod/excessive-utilities) | Aaron, Curios API, Kotlin for Forge | both | Launch tested | Servidor: generador colocado; quarries a 0 bloques/tick |
| Explorify | 1.6.5 | [Modrinth](https://modrinth.com/mod/explorify) | — | both | Launch tested | Servidor: locate de ruins, tavern y farmstead |
| Extended AE | 1.21-2.2.35-neoforge | [Modrinth](https://modrinth.com/mod/extended-ae) | Applied Energistics 2, Glodium, GuideME | both | Launch tested | Servidor carga; aviso inofensivo de loot table EMC (ProjectE ausente) |
| FerriteCore | 7.0.3 | [Modrinth](https://modrinth.com/mod/ferrite-core) | — | both | Launch tested | Servidor carga |
| Forgematica | 0.4.2+mc1.21.1 | [Modrinth](https://modrinth.com/mod/forgematica) | MaFgLib | client | Verified |  |
| Friends & Foes | 4.0.27 | [Modrinth](https://modrinth.com/mod/friends-and-foes-forge) | Resourceful Lib | both | Launch tested | Servidor 0.4.0-alpha.1: botón de cobre colocado; iceologer_cabin ubicada (citadel no aparece cerca de la semilla); cliente 0.4.0-alpha.1 arranca y entra al mundo |
| FTB Chunks (NeoForge) | 2101.1.22 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-chunks-forge) | Architectury API, FTB Library (NeoForge), FTB Teams (NeoForge) | both | Launch tested | Servidor: config del pack cargada sin reescritura |
| FTB JEI Extras | 21.1.7 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-jei-extras) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| FTB Library (NeoForge) | 2101.1.37 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-library-forge) | Architectury API | both | Launch tested | Servidor carga |
| FTB Quests (NeoForge) | 2101.1.36 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-quests-forge) | Architectury API, FTB Library (NeoForge), FTB Teams (NeoForge) | both | Verified |  |
| FTB Teams (NeoForge) | 2101.1.11 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-teams-forge) | Architectury API, FTB Library (NeoForge) | both | Launch tested | Servidor carga |
| Glodium | 1.21-2.2-neoforge | [Modrinth](https://modrinth.com/mod/glodium) | — | both | Launch tested | Servidor carga |
| GraveStone Mod | 1.21.1-1.0.40 | [Modrinth](https://modrinth.com/mod/gravestone-mod) | — | both | Launch tested | Servidor: bloque de lápida colocado |
| GuideME | 21.1.19 | [Modrinth](https://modrinth.com/mod/guideme) | — | both | Launch tested | Servidor carga |
| Illager Invasion | 21.1.6 | [Modrinth](https://modrinth.com/mod/illager-invasion) | Puzzles Lib | both | Launch tested | Servidor 0.4.0-alpha.1: illager_fort ubicado; config sin Illusioner en raids aceptada; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| ImmediatelyFast | 1.6.14+1.21.1 | [Modrinth](https://modrinth.com/mod/immediatelyfast) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Inventory Profiles Next | 2.2.5 | [Modrinth](https://modrinth.com/mod/inventory-profiles-next) | libIPN | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Iris Shaders | 1.8.12-snapshot+mc1.21.1-local | [Modrinth](https://modrinth.com/mod/iris) | Sodium | client | Launch tested | Cliente 0.2.0-alpha.1: arranca; cambia de pipeline al entrar al Aether. Shaders sin probar |
| It Takes a Pillage | 1.0.13 | [Modrinth](https://modrinth.com/mod/it-takes-a-pillage-continuation) | Resourceful Lib | both | Launch tested | Servidor 0.4.0-alpha.1: bastille ubicada; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| Jade | 15.10.6+neoforge | [Modrinth](https://modrinth.com/mod/jade) | — | both | Launch tested | Servidor rc.5 carga con plugins de AE2, Extended AE, Waystones, GraveStone y Balm; cliente 0.2.0-alpha.1 arranca; HUD sin confirmar |
| Just Enough Items (JEI) | 19.51.0.418 | [Modrinth](https://modrinth.com/mod/jei) | — | both | Launch tested | Servidor carga (regla de alias 1.21 de FML); habilita traslado de recetas |
| Just Hammers | 21.1.4 | [Modrinth](https://modrinth.com/mod/just-hammers) | — | both | Launch tested | Servidor 0.5.0-alpha.1 carga (solo ítems) |
| Just Zoom | 2.1.0 | [Modrinth](https://modrinth.com/mod/just-zoom) | Konkrete | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente; zoom en la tecla C) |
| Konkrete | 1.9.9 | [Modrinth](https://modrinth.com/mod/konkrete) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente (biblioteca de Just Zoom)) |
| Kotlin for Forge | kotlinforforge-5.12.0-all.jar | [Modrinth](https://modrinth.com/mod/kotlin-for-forge) | — | both | Launch tested | Servidor carga |
| L_Ender's Cataclysm | 3.33 | [Modrinth](https://modrinth.com/mod/l_enders-cataclysm) | Curios API, Lionfish-API | both | Launch tested | Servidor 0.5.0-alpha.1: soul_black_smith, burning_arena, ancient_factory y sunken_city ubicadas |
| libIPN | 6.6.3 | [Modrinth](https://modrinth.com/mod/libipn) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Lionfish-API | 3.1 | [Modrinth](https://modrinth.com/mod/lionfish-api) | — | both | Launch tested | Servidor 0.5.0-alpha.1 carga (L_Ender's Cataclysm) |
| Lithium | 0.15.4+mc1.21.1 | [Modrinth](https://modrinth.com/mod/lithium) | — | both | Launch tested | Servidor carga |
| MaFgLib | 0.4.3+mc1.21.1 | [Modrinth](https://modrinth.com/mod/mafglib) | — | client | Verified |  |
| ModernFix | 5.27.26+mc1.21.1 | [Modrinth](https://modrinth.com/mod/modernfix) | — | both | Launch tested | Servidor carga; 2 mixins desactivados por conflicto con Lithium |
| Nature's Compass | 1.21.1-3.4.0-neoforge | [Modrinth](https://modrinth.com/mod/natures-compass) | — | both | Verified |  |
| Not Enough Animations | 1.12.6 | [Modrinth](https://modrinth.com/mod/not-enough-animations) | — | client | Launch tested | Solo cliente; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| owo-lib | 0.12.15.5-beta.1+1.21 | [Modrinth](https://modrinth.com/mod/owo-lib) | — | both | Launch tested | Servidor alpha.1 carga (requerida por Accessories, que viene dentro de Aether) |
| Paxi | 1.21.1-NeoForge-5.1.3 | [Modrinth](https://modrinth.com/mod/paxi) | YUNG's API | both | Verified |  |
| Ping Wheel | 1.12.2 | [Modrinth](https://modrinth.com/mod/ping-wheel) | — | both | Verified |  |
| Puzzles Lib | 21.1.63 | [Modrinth](https://modrinth.com/mod/puzzles-lib) | — | both | Launch tested | Servidor 0.4.0-alpha.1 carga (Illager Invasion); cliente 0.4.0-alpha.1 arranca y entra al mundo |
| Resourceful Lib | 3.0.12 | [Modrinth](https://modrinth.com/mod/resourceful-lib) | — | both | Launch tested | Servidor 0.4.0-alpha.1 carga (Friends & Foes, It Takes a Pillage); cliente 0.4.0-alpha.1 arranca y entra al mundo |
| Searchables | 1.0.2 | [Modrinth](https://modrinth.com/mod/searchables) | — | client | Verified | Solo cliente (biblioteca de Controlling) |
| Sodium | 0.6.13+mc1.21.1 | [Modrinth](https://modrinth.com/mod/sodium) | — | client | Launch tested | Cliente 0.2.0-alpha.1: arranque, mundo y Aether (bajado a 0.6.13 en rc.4 para usar Iris estable) |
| Sophisticated Backpacks | 3.26.9 | [Modrinth](https://modrinth.com/mod/sophisticated-backpacks) | Sophisticated Core | both | Launch tested | Servidor: mochila colocada como bloque |
| Sophisticated Core | 1.5.7 | [Modrinth](https://modrinth.com/mod/sophisticated-core) | — | both | Launch tested | Servidor carga |
| spark | 1.10.124 | [Modrinth](https://modrinth.com/mod/spark) | — | both | Launch tested | Servidor: spark tps / health |
| Storage Drawers | 13.11.4 | [Modrinth](https://modrinth.com/mod/storagedrawers) | — | both | Launch tested | Servidor 0.4.0-alpha.1: cajón colocado; cliente 0.4.0-alpha.1 arranca y entra al mundo |
| TerraBlender | 4.1.0.8 | [Modrinth](https://modrinth.com/mod/terrablender) | — | both | Launch tested | Cliente 0.3.0-alpha.1 arranca. Servidor: las 18 estructuras previas salen en las mismas coordenadas que en 0.2.0-alpha.1 |
| The Aether | 1.5.10 | [Modrinth](https://modrinth.com/mod/aether) | — | both | Gameplay tested | Cliente 0.2.0-alpha.1 (usuario): entrada al Aether y vuelta. Servidor: dimensión y 3 dungeons + large_aercloud ubicados |
| Time in a bottle | 6.5.4 | [Modrinth](https://modrinth.com/mod/time-in-a-bottle-universal) | — | both | Verified |  |
| Waystones | 21.1.46 | [Modrinth](https://modrinth.com/mod/waystones) | Balm | both | Launch tested | Servidor: bloque colocado |
| Xaero's Minimap | 26.6.0 | [Modrinth](https://modrinth.com/mod/xaeros-minimap) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Xaero's World Map | 1.47.0 | [Modrinth](https://modrinth.com/mod/xaeros-world-map) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| YetAnotherConfigLib (YACL) | 3.8.2+1.21.1-neoforge | [Modrinth](https://modrinth.com/mod/yacl) | — | client | Verified |  |
| YUNG's API | 1.21.1-NeoForge-5.1.9 | [Modrinth](https://modrinth.com/mod/yungs-api) | — | both | Launch tested | Servidor carga |
| YUNG's Bridges | 1.21.1-NeoForge-5.1.1 | [Modrinth](https://modrinth.com/mod/yungs-bridges) | YUNG's API | both | Launch tested | Servidor carga |
| YUNG's Extras | 1.21.1-NeoForge-5.1.1 | [Modrinth](https://modrinth.com/mod/yungs-extras) | YUNG's API | both | Launch tested | Servidor carga |

## Shaderpacks (solo cliente, apagados por defecto)

| Shaderpack | Archivo | Fuente |
|---|---|---|
| MakeUp - Ultra Fast | MakeUp-UltraFast-9.5a.zip | [Modrinth](https://modrinth.com/shader/izsIPI7a) |
| Mellow | Mellow Shader v3.2.zip | [Modrinth](https://modrinth.com/shader/BUxf36AP) |
| Miniature Shader | miniature-shader-2.18.11.zip | [Modrinth](https://modrinth.com/shader/UaS8ROxa) |
| Sildur's Basic Shaders | Sildur's Basic Shaders v2.6 Fancy.zip | [Modrinth](https://modrinth.com/shader/N1BIOvQX) |
| Sildur's Vibrant Shaders | Sildur's Vibrant Shaders v1.56 Extreme.zip | [Modrinth](https://modrinth.com/shader/z8EjLYqN) |
