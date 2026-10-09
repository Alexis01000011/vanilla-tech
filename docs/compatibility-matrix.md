# Matriz de compatibilidad — Vanilla Tech 0.1.0-rc.4

Minecraft 1.21.1 · NeoForge 21.1.257 · 49 artefactos fijados.
Generada por `scripts/gen-matrix.py`; no editar a mano. Los estados viven en `docs/test-status.toml`.

**Estados**
- **Verified**: hashes, metadatos, lado (cliente/servidor) y rangos de versión comprobados (`validate.py`, `check-ranges.py`).
- **Launch tested**: cargó sin errores en un arranque real de NeoForge (servidor dedicado o cliente en Prism). La columna *Evidencia* indica qué más se comprobó por comandos.
- **Gameplay tested**: funcionalidad probada por un jugador dentro del juego.
- **Blocked**: problema abierto.

El cliente **rc.3** arrancó en Prism y entró a un mundo nuevo (2026-10-09); los mods nuevos o cambiados en rc.4 siguen pendientes de esa prueba ([known-issues.md](known-issues.md)). Las dependencias se leen de `META-INF/neoforge.mods.toml` en cada JAR, sin contar las bibliotecas que el propio JAR trae embebidas (jar-in-jar).

| Mod | Versión | Fuente | Dependencias obligatorias | Side | Estado | Evidencia |
|---|---|---|---|---|---|---|
| Aaron | 1.21.0 | [Modrinth](https://modrinth.com/mod/aaron) | Kotlin for Forge | both | Launch tested | Servidor carga |
| AE2 JEI Integration | 1.2.1 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ae2-jei-integration) | Applied Energistics 2, Just Enough Items (JEI) | both | Launch tested | Servidor rc.4 carga; en cliente debe arreglar el plugin JEI de Applied Create |
| Applied Create | 1.1.7 | [Modrinth](https://modrinth.com/mod/applied-create) | Applied Energistics 2, Create, Kotlin for Forge | both | Launch tested | Servidor: la rotación de Create (16 RPM) enciende un controlador AE2 vía kinetic_energy_acceptor, sin celda de energía |
| Applied Energistics 2 | 19.2.18 | [Modrinth](https://modrinth.com/mod/ae2) | GuideME | both | Launch tested | Servidor: controlador online con celda creativa |
| Applied Energistics 2 Wireless Terminals | 19.5.1 | [Modrinth](https://modrinth.com/mod/applied-energistics-2-wireless-terminals) | Applied Energistics 2 | both | Launch tested | Servidor carga; Quantum Bridge Card y receta presentes en el JAR |
| Architectury API | 13.0.11 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/architectury-api) | — | both | Launch tested | Servidor carga |
| Balm | 21.0.66 | [Modrinth](https://modrinth.com/mod/balm) | — | both | Launch tested | Servidor carga |
| Building Gadgets | 1.3.9 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/building-gadgets) | — | both | Launch tested | Servidor carga |
| Charging Gadgets | 1.14.1 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/charging-gadgets) | — | both | Launch tested | Servidor: estación colocada |
| Chunky | 1.4.23 | [Modrinth](https://modrinth.com/mod/chunky) | — | server | Launch tested | Servidor: pregeneración de 1681 chunks |
| Controlling | 19.0.5 | [Modrinth](https://modrinth.com/mod/controlling) | Searchables | client | Verified | Solo cliente; probar en cliente rc.4 |
| Crafting Tweaks | 21.1.11 | [Modrinth](https://modrinth.com/mod/crafting-tweaks) | Balm | both | Launch tested | Servidor carga |
| Create | 6.0.10 | [Modrinth](https://modrinth.com/mod/create) | — | both | Launch tested | Servidor: red cinética, eje a 16 RPM desde motor creativo |
| Curios API | 9.5.1+1.21.1 | [Modrinth](https://modrinth.com/mod/curios) | — | both | Launch tested | Servidor carga |
| Dank Storage | 20 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/dank-storage) | — | both | Launch tested | Servidor carga |
| Dynamic FPS | 3.11.4 | [Modrinth](https://modrinth.com/mod/dynamic-fps) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Entity Culling | 1.11.3 | [Modrinth](https://modrinth.com/mod/entityculling) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Excessive Utilities | 1.10.0 | [Modrinth](https://modrinth.com/mod/excessive-utilities) | Aaron, Curios API, Kotlin for Forge | both | Launch tested | Servidor: generador colocado; quarries a 0 bloques/tick |
| Explorify | 1.6.5 | [Modrinth](https://modrinth.com/mod/explorify) | — | both | Launch tested | Servidor: locate de ruins, tavern y farmstead |
| Extended AE | 1.21-2.2.35-neoforge | [Modrinth](https://modrinth.com/mod/extended-ae) | Applied Energistics 2, Glodium, GuideME | both | Launch tested | Servidor carga; aviso inofensivo de loot table EMC (ProjectE ausente) |
| FerriteCore | 7.0.3 | [Modrinth](https://modrinth.com/mod/ferrite-core) | — | both | Launch tested | Servidor carga |
| FTB Chunks (NeoForge) | 2101.1.22 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-chunks-forge) | Architectury API, FTB Library (NeoForge), FTB Teams (NeoForge) | both | Launch tested | Servidor: config del pack cargada sin reescritura |
| FTB JEI Extras | 21.1.7 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-jei-extras) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| FTB Library (NeoForge) | 2101.1.37 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-library-forge) | Architectury API | both | Launch tested | Servidor carga |
| FTB Teams (NeoForge) | 2101.1.11 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/ftb-teams-forge) | Architectury API, FTB Library (NeoForge) | both | Launch tested | Servidor carga |
| Glodium | 1.21-2.2-neoforge | [Modrinth](https://modrinth.com/mod/glodium) | — | both | Launch tested | Servidor carga |
| GraveStone Mod | 1.21.1-1.0.40 | [Modrinth](https://modrinth.com/mod/gravestone-mod) | — | both | Launch tested | Servidor: bloque de lápida colocado |
| GuideME | 21.1.19 | [Modrinth](https://modrinth.com/mod/guideme) | — | both | Launch tested | Servidor carga |
| ImmediatelyFast | 1.6.14+1.21.1 | [Modrinth](https://modrinth.com/mod/immediatelyfast) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Inventory Profiles Next | 2.2.5 | [Modrinth](https://modrinth.com/mod/inventory-profiles-next) | libIPN | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Iris Shaders | 1.8.12-snapshot+mc1.21.1-local | [Modrinth](https://modrinth.com/mod/iris) | Sodium | client | Verified | Solo cliente; shaders apagados por defecto; probar en cliente rc.4 |
| Just Enough Items (JEI) | 19.51.0.418 | [Modrinth](https://modrinth.com/mod/jei) | — | both | Launch tested | Servidor carga (regla de alias 1.21 de FML); habilita traslado de recetas |
| Just Zoom | 2.1.0 | [Modrinth](https://modrinth.com/mod/just-zoom) | Konkrete | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente; zoom en la tecla C) |
| Konkrete | 1.9.9 | [Modrinth](https://modrinth.com/mod/konkrete) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente (biblioteca de Just Zoom)) |
| Kotlin for Forge | kotlinforforge-5.12.0-all.jar | [Modrinth](https://modrinth.com/mod/kotlin-for-forge) | — | both | Launch tested | Servidor carga |
| libIPN | 6.6.3 | [Modrinth](https://modrinth.com/mod/libipn) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Lithium | 0.15.4+mc1.21.1 | [Modrinth](https://modrinth.com/mod/lithium) | — | both | Launch tested | Servidor carga |
| ModernFix | 5.27.26+mc1.21.1 | [Modrinth](https://modrinth.com/mod/modernfix) | — | both | Launch tested | Servidor carga; 2 mixins desactivados por conflicto con Lithium |
| Searchables | 1.0.2 | [Modrinth](https://modrinth.com/mod/searchables) | — | client | Verified | Solo cliente (biblioteca de Controlling) |
| Sodium | 0.6.13+mc1.21.1 | [Modrinth](https://modrinth.com/mod/sodium) | — | client | Verified | Solo cliente; bajado de 0.8.13 a 0.6.13 en rc.4 para usar Iris estable; probar en cliente rc.4 |
| Sophisticated Backpacks | 3.26.9 | [Modrinth](https://modrinth.com/mod/sophisticated-backpacks) | Sophisticated Core | both | Launch tested | Servidor: mochila colocada como bloque |
| Sophisticated Core | 1.5.7 | [Modrinth](https://modrinth.com/mod/sophisticated-core) | — | both | Launch tested | Servidor carga |
| spark | 1.10.124 | [Modrinth](https://modrinth.com/mod/spark) | — | both | Launch tested | Servidor: spark tps / health |
| Waystones | 21.1.46 | [Modrinth](https://modrinth.com/mod/waystones) | Balm | both | Launch tested | Servidor: bloque colocado |
| Xaero's Minimap | 26.6.0 | [Modrinth](https://modrinth.com/mod/xaeros-minimap) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
| Xaero's World Map | 1.47.0 | [Modrinth](https://modrinth.com/mod/xaeros-world-map) | — | client | Launch tested | Cliente rc.3: arranque y mundo nuevo en Prism (solo cliente) |
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
