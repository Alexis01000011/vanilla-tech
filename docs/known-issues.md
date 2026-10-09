# Problemas conocidos y pruebas pendientes

Estado a 2026-10-09, release **0.1.0-rc.3**.

## Pruebas pendientes

| # | Prueba | Por qué sigue pendiente |
|---|---|---|
| P1 | **Cliente en Prism Launcher**: importar el `.mrpack`, arrancar y entrar a un mundo. | Requiere al usuario frente a la laptop (sesión gráfica y cuenta de Microsoft). |
| P2 | **FPS y memoria reales del cliente** con distancia 8 y heap de 3 GiB. | No se afirma rendimiento estable sin medirlo. Ver [performance.md](performance.md). |
| P3 | **Conflictos de teclas** en *Opciones → Controles*. | Los defaults de Xaero, IPN y Excessive Utilities no se pudieron leer del bytecode; hay que revisarlos dentro del juego. |
| P4 | **Aviso de dominios no permitidos** de Prism con las 8 descargas de `edge.forgecdn.net`. | Hay que confirmar si aparece y si el import termina bien. |
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

### Distribución y reproducibilidad
- **packwiz se obtiene de un artefacto de CI de GitHub** (`nightly.link`, commit `ef87d96`), verificado por SHA-256. Ese artefacto **caduca el 2026-12-05** (según la API de GitHub); después, `scripts/bootstrap-tools.py` no podrá descargarlo en otra computadora. Alternativas:
  - `go install github.com/packwiz/packwiz@ef87d964f8cbd52b3b13ea42453ef322290e2b9e` y copiar el binario a `.tools/packwiz`, o
  - conservar una copia del binario fuera de git; el script lo acepta si coincide el SHA-256.
- **8 mods vienen de CurseForge** (`edge.forgecdn.net`). Las URLs están fijadas en los metafiles; si CurseForge las retirara, habría que actualizar el metafile.
- **El rango de versiones solo se verifica para las dependencias que se pueden leer en los metadatos del JAR.** Las incompatibilidades por código (mixins) solo se detectan al arrancar el juego.

### Rendimiento
- La laptop cliente tiene 8 GB físicos, pero **la iGPU reserva 2 GiB**: el sistema ve 5.7 GiB y ya usa swap con el escritorio abierto. Con heap de 3 GiB más el uso nativo de la JVM, conviene cerrar el navegador mientras se juega. Si la BIOS lo permite, bajar la memoria reservada de la iGPU (UMA frame buffer) libera RAM.
- Los comandos `locate` y la generación de estructuras grandes provocan picos de *Can't keep up* de 2–7 s en el servidor de prueba (2 núcleos). Es normal al explorar terreno nuevo; pregenerar con Chunky lo reduce durante el juego.
