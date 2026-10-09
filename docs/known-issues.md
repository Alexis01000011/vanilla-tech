# Problemas conocidos y pruebas pendientes

Estado a 2026-10-09, release **0.3.0-alpha.1** (estable: 0.2.0).

## Pruebas pendientes

| # | Prueba | Por qué sigue pendiente |
|---|---|---|
| P1 | ~~Cliente en Prism Launcher~~ — **hecho con rc.3**: importó, arrancó en ~36 s y entró a un mundo nuevo. | Repetir con rc.4 (P16). |
| P2 | **FPS y memoria reales del cliente** con distancia 8 y heap de 3 GiB. | Primera muestra (rc.3, heap de 3900 MiB por el default de Prism): RSS de la JVM 2.7 GiB en el mundo; al sistema le quedaban 0.9 GiB y había 2.2 GiB en swap. Falta medir con 3072 MiB y anotar FPS. |
| P3 | **Conflictos de teclas** en *Opciones → Controles*. | Los defaults de Xaero, IPN y Excessive Utilities no se pudieron leer del bytecode; hay que revisarlos dentro del juego. |
| P4 | ~~Aviso de dominios no permitidos~~ — **hecho**: Prism importó rc.3 (8 descargas de `edge.forgecdn.net`) sin ningún aviso. | — |
| P5 | **Terminal inalámbrica + Quantum Bridge Card**: alcance infinito e interdimensional. | Requiere un jugador. Solo se verificó que el ítem y su receta existen. |
| P6 | **Building Gadgets 2**: uso y recarga en la Charging Station. | Requiere un jugador. La estación se coloca sin errores en el servidor. |
| P7 | **Waystones**: activar dos piedras y teletransportarse. | Requiere un jugador. |
| P8 | **Excessive Utilities**: Grid Power, Angel Ring, Transfer Nodes, Trash Can. | Requiere un jugador. El generador se coloca sin errores. |
| P9 | **FTB Chunks**: reclamar y forzar carga, límite de 100 y `party_limit_mode = "sum"`. | Requiere un jugador. La config se instala y FTB la carga sin reescribirla (señal de que es válida). |
| P10 | **Contraptions de Create** en movimiento (pistones, rodamientos, trenes) y deployers dentro de chunks reclamados. | Requiere un jugador. Con `disable_protection = true` no debería haber bloqueo de *fake players*. |
| P11 | **Granjas vanilla** (hierro, mobs, raids, guardianes, aldeanos). | Las estructuras se generan (ver [test-results.md](test-results.md)), pero eso no prueba que las granjas funcionen. |
| P12 | **Carga con dos jugadores** en el servidor (TPS, MSPT, memoria). | Todas las mediciones son sin jugadores conectados. |
| P13 | **Just Zoom**: zoom con C y rueda del mouse. | Solo cliente. |
| P14 | **Sophisticated Backpacks**: abrir con B desde la ranura de Curios y el imán (Z). | Requiere un jugador. |
| P15 | **GraveStone**: morir, comprobar que la lápida guarda inventario + Curios y recuperarlo. | Requiere un jugador. |
| P16 | ~~Cliente con Sodium 0.6.13, Iris 1.8.12, Controlling y AE2 JEI Integration~~ — **hecho con 0.2.0-alpha.1**: arranque y mundo sin errores. | — |
| P17 | **Shaders**: activar MakeUp/Miniature con K, comprobar FPS y que Create (contraptions) se vea bien. | Opcional; en la iGPU puede no ser jugable con los pesados. |
| P18 | **JEI ↔ AE2**: botón "+" en la terminal de codificación de patrones y sin el error del plugin JEI de Applied Create en el log. | **Parcial (0.2.0-alpha.1)**: el error del plugin JEI de Applied Create ya no aparece y AE2 JEI Integration registra su plugin. Falta probar el botón "+". |
| P20 | **The Aether en el cliente**: portal (marco de glowstone + agua), entrar y volver, cielo y nubes con Sodium, Iris y shaders; dungeons y jefes; botón de accesorios del inventario. | **Parcial (0.2.0-alpha.1)**: el usuario entró al Aether y volvió (log: 16:06 → 16:17). Faltan shaders, dungeons y el botón de accesorios. El servidor ya ubica los 3 dungeons. |
| P21 | **Dos sistemas de accesorios**: Curios (G) y Accessories del Aether (botón en el inventario). Hay que ver dónde se puede equipar la mochila, que B la abra desde ahí y que GraveStone guarde los ítems de ambos al morir. | Sophisticated Backpacks trae integración con Curios y con Accessories; GraveStone no tiene integración específica con ninguno de los dos. |
| P22 | **Deep Aether**: biomas nuevos al explorar el Aether, Brass Dungeon y teclas de habilidades (Stratus Dash R, Slider Slam Alt). | En el servidor se ubica el Brass Dungeon y el bioma aerglow_forest (0.3.0-alpha.1). |
| P23 | **Deeper and Darker**: activar el portal de una ancient city, entrar al Otherside y volver; Soul Elytra con Y. | En el servidor carga la dimensión `deeperdarker:otherside` y se ubica el Ancient Temple (0.3.0-alpha.1). |
| P19 | **Jade**: el HUD muestra el bloque que se mira y la información de AE2 y Create. | Solo cliente; en el servidor ya cargan los plugins de AE2, Extended AE, Waystones, GraveStone y Balm (rc.5). |

## Problemas conocidos

### Compatibilidad y contenido
- **JEI declara `minecraft [1.21, 1.21.1)`**, un rango que excluye 1.21.1. Carga igual gracias a la regla oficial de FML (`VersionSupportMatrix`), que acepta rangos de 1.21 en 1.21.1. Es un error de metadatos del JAR, no una incompatibilidad. Al actualizar JEI, conviene volver a revisar el rango.
- **Excessive Utilities añade 3 dimensiones** (`the_depths`, `quantum_quarry`, `the_last_millennium`) y una ancient city propia que solo aparece en su bioma `the_depths`. Las ancient cities vanilla no se modifican. Es una excepción aceptada.
- **Excessive Utilities agrega `the_depths` al tag `c:is_overworld`.** Si algún mod usa ese tag para generar contenido, también puede aparecer en esa dimensión. Con los mods actuales no se observó ningún efecto.
- **Bug de Excessive Utilities en su config**: `tlmChunkDistance` tiene un default de 1024, fuera de su propio rango (2–100). NeoForge lo corrige a 100 al arrancar. Es inofensivo.
- **Errores de carga inofensivos en el log del servidor**:
  - `extendedae:blocks/ex_emc_interface`: tabla de loot de la integración con ProjectE, que no está instalado.
  - `Couldn't load tag excessive_utilities:ender_quarry_upgrade`: un tag con referencias faltantes; las quarries están desactivadas de todos modos.
- **ModernFix y Lithium** se pisan en dos mixins (`remove_biome_temperature_cache`, `paper_chunk_patches`). Se desactivaron en ModernFix (`config/modernfix-mixins.properties`). ModernFix reescribe ese archivo con comentarios al arrancar, y es normal.
- **El minimapa de FTB Chunks** se desactiva desde el servidor (`force_disable_minimap = true`). En un mundo de un solo jugador la config del pack también aplica, porque se instala en ambos lados.

- **Sophisticated Backpacks y Sophisticated Core publican versiones casi a diario.** Están fijadas en una pareja compatible (Backpacks 3.26.9 requiere Core ≥ 1.5.6). Al actualizar, súbelas juntas.
- **Advertencias de mixin inofensivas al arrancar** (`functionalstorage/world/EnderSavedData`, `ApiStatus$ScheduledForRemoval`): integraciones opcionales con mods que no están instalados. Ya aparecían en la rc.1.

- **AE2 1.21.1 no integra JEI** (solo EMI/REI). Desde la rc.4 lo cubre AE2 JEI Integration; sin ella, el plugin JEI de Applied Create lanza `NoClassDefFoundError: tamaized/ae2jeiintegration/...` (visto en el cliente rc.3).
- **Errores inofensivos en el log del cliente**: `GL ERROR 65547: X11: Standard cursor shape unavailable` (GLFW no encuentra algunas formas de cursor en este escritorio), `Error while loading the narrator` (no hay narrador en Linux), `Couldn't connect to realms` y `Online mod data expired` de Xaero (consulta de versiones en línea).
- **Prism usa por defecto su memoria global** (3900 MiB en esta máquina) si la instancia no marca *Memory*. El `.mrpack` no puede fijar la memoria; hay que hacerlo en la instancia.
- **Iris con Sodium 0.6.13**: se bajó Sodium para usar la Iris estable. Si en el futuro sale una Iris estable para Sodium 0.8 en 1.21.1, se puede volver a subir los dos juntos.

### The Aether (0.2.0-alpha)
- **Dos sistemas de accesorios**. The Aether 1.21.1 usa *Accessories* y el resto del pack usa *Curios*. Funcionan por separado: las pantallas son distintas y las ranuras no se comparten. Existe una capa de compatibilidad (cclayer) que reemplaza a Curios, pero no se usa: cambiaría la base 0.1 y también es beta.
- **owo-lib solo tiene versiones beta para NeoForge**, y Accessories, dentro de Aether, es 1.1.0-beta.48. Es la combinación que publica el equipo de The Aether.
- **Diseño de Aether**: en esa dimensión, las herramientas que no son del Aether minan más lento (`Debuff non-Aether tools = true`) y las camas explotan solo si se activa esa opción (por defecto no). Se dejaron los valores por defecto del mod.
- **Avisos `Reference map ... could not be read`** de Aether, Accessories, Cumulus y Nitrogen al arrancar: son normales en NeoForge y no indican un problema.
- **Deeper and Darker modifica las ancient cities vanilla**: agrega vasijas (`ancient_vase`) en 17 piezas de muro. Algunas son falsas y sueltan un mob (`fakeVaseChance = 0.16`). La forma de la ciudad no cambia y las ancient cities no se usan para granjas.
- **El arranque del servidor tarda más** con tres dimensiones nuevas: `Done` en 57.6 s en 0.3.0-alpha.1, contra 27 s en 0.2.0-alpha.1, en la máquina de prueba con 2 núcleos.
- **Aviso al arrancar `Failed to process update information`** (AeroBlender): su URL de comprobación de versiones no devuelve JSON. Es inofensivo.
- **Quitar Aether de un mundo donde ya se usó** borra sus bloques e ítems. Ver *Versiones y ramas* en el README.

### Distribución y reproducibilidad
- **packwiz se obtiene de un artefacto de CI de GitHub** (`nightly.link`, commit `ef87d96`), verificado por SHA-256. Ese artefacto **caduca el 2026-12-05** (según la API de GitHub); después, `scripts/bootstrap-tools.py` no podrá descargarlo en otra computadora. Alternativas:
  - `go install github.com/packwiz/packwiz@ef87d964f8cbd52b3b13ea42453ef322290e2b9e` y copiar el binario a `.tools/packwiz`, o
  - conservar una copia del binario fuera de git; el script lo acepta si coincide el SHA-256.
- **9 mods vienen de CurseForge** (`edge.forgecdn.net`). Las URLs están fijadas en los metafiles; si CurseForge las retirara, habría que actualizar el metafile.
- **El rango de versiones solo se verifica para las dependencias que se pueden leer en los metadatos del JAR.** Las incompatibilidades por código (mixins) solo se detectan al arrancar el juego.

### Rendimiento
- La laptop cliente tiene 8 GB físicos, pero **la iGPU reserva 2 GiB**: el sistema ve 5.7 GiB y ya usa swap con el escritorio abierto. Con heap de 3 GiB más el uso nativo de la JVM, conviene cerrar el navegador mientras se juega. Si la BIOS lo permite, bajar la memoria reservada de la iGPU (UMA frame buffer) libera RAM.
- Los comandos `locate` y la generación de estructuras grandes provocan picos de *Can't keep up* de 2–7 s en el servidor de prueba (2 núcleos). Es normal al explorar terreno nuevo; pregenerar con Chunky lo reduce durante el juego.
