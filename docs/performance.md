# Rendimiento: mediciones y recomendaciones

Todo lo de este documento son **mediciones reales sin jugadores conectados** o recomendaciones derivadas de ellas. No hay todavía mediciones de cliente ni de partidas con dos jugadores ([known-issues.md](known-issues.md), P2 y P12), así que **no se promete** un consumo máximo ni FPS estables.

## Entorno de las mediciones

| Parámetro | Valor |
|---|---|
| Máquina | Laptop con AMD Ryzen 5 3500U (4 núcleos / 8 hilos) y 8 GB físicos (5.7 GiB visibles) |
| JVM | OpenJDK 21.0.12, G1, `-Xms512m -Xmx2G`, `-XX:ActiveProcessorCount=2` (la JVM dimensiona sus hilos como si hubiera 2 núcleos, para aproximar una instancia pequeña) |
| Servidor | NeoForge 21.1.257, 31 mods de servidor (rc.2) y 34 (rc.3), `view-distance=4`, `simulation-distance=4`, semilla `20261009` |
| Herramientas | `scripts/test-server.py` (RSS leído de `/proc`), `spark tps/health`, log de GC (`-Xlog:gc*`) |

## Servidor: resultados

| Prueba | Arranque (`Done`) | RSS máximo | Notas |
|---|---|---|---|
| rc.1, primer arranque (Astra) | — | 1253 MiB | Mundo nuevo. |
| rc.2, primer arranque (instalación limpia) | 28.3 s | 1086 MiB | Mundo nuevo. |
| rc.2, integración + pregeneración de **1681 chunks** con Chunky | 30 s | **1665 MiB** | Prueba más pesada realizada. |
| rc.2, integración corregida (con JEI en servidor) | 30.1 s | 1269 MiB | Mundo nuevo. |
| rc.3, integración (con Sophisticated Backpacks y GraveStone) | 28.7 s | 1224 MiB | Mundo nuevo. |

Detalle de la prueba con pregeneración (`docs/rc2-integration.json`):

- **Chunky**: 1681 chunks (radio de 320 bloques) en **2 min 38 s**, unos **10.6 chunks/s**.
- **TPS** durante la pregeneración: 20.0. El tick mediano sube a ~49 ms porque Chunky usa a propósito el tiempo libre de cada tick. En reposo el tick mediano es de **0.8–1.1 ms**.
- **Heap ocupado después de cada GC**: máximo 1057 MiB; comprometido como máximo 1133 MiB de los 2048 MiB permitidos.
- **Pausas de GC** (264 en total): p50 15.6 ms, p95 61 ms, p99 118 ms, máximo 171 ms. Ningún *Full GC*.
- **`locate` de estructuras lejanas**: genera ticks de 2–3 s (*Can't keep up*). Es esperable al buscar o generar terreno nuevo.

**Conclusión**: sin jugadores, el servidor vive con ~0.6–1.1 GiB de heap ocupado. La carga real depende de lo que construyan los jugadores: contraptions de Create, redes y autocrafteo de AE2, entidades de granjas y chunks forzados de FTB Chunks.

## Servidor: recomendaciones por tamaño de instancia

| | EC2 con **8 GiB** | EC2 con **16 GiB** |
|---|---|---|
| Heap (`-Xmx`) | **5 GiB** (`prepare-server.py --heap 5G`) | **8 GiB** (`--heap 8G`) para empezar |
| Por qué | Deja ~3 GiB para Linux, metaspace, *code cache*, hilos y buffers nativos (en las pruebas el RSS superó al heap ocupado en ~0.5 GiB). | Lo medido no justifica más. La RAM sobrante sirve como caché de disco del mundo, lo que acelera las cargas de chunks. Subir a 10 GiB solo si `spark health` muestra el heap ocupado por encima del 70 % de forma sostenida. |
| `-Xms` | 1 GiB (de `server-template/user_jvm_args.txt`) | Igual. Con la RAM sobrada puede fijarse `-Xms` = `-Xmx` para evitar redimensionamientos. |
| `view-distance` / `simulation-distance` | 8 / 6 | 10 / 8, si los TPS se mantienen en 20 |
| GC | G1, el predeterminado de Java 21. No hace falta afinarlo. | Igual |

`server-template/user_jvm_args.txt` ya activa G1 y el log de GC rotativo (`gc.log`, 3 × 10 MiB) para diagnosticar.

### Prácticas de operación
- **Pregenerar** antes de jugar (radio de 1000–2000 bloques con Chunky). Con nadie conectado, a ~10 chunks/s, un radio de 1000 bloques (~15 600 chunks) tarda unos 25 min en hardware parecido.
- **spark**: `/spark tps` para salud general; `/spark profiler start --timeout 120` cuando haya lag, y compartir el enlace que genera.
- **Create**: los contraptions grandes en movimiento y los trenes son lo que más suele pesar. Si suben los MSPT, revisar con spark las entidades de tipo contraption.
- **AE2**: el autocrafteo con muchos Molecular Assemblers y buses rápidos consume tick. Conviene preferir los ensambladores paralelos de Extended AE a muchas unidades sueltas.
- **FTB Chunks**: el peor caso son 200 chunks forzados (100 por jugador) activos mientras alguien juega. Con `force_load_mode = "never"` no consumen nada sin jugadores conectados.
- **Backups**: ver [installation.md](installation.md#backups). Un mundo pregenerado ocupa espacio; dimensiona el volumen EBS con margen.

## Cliente: recomendaciones iniciales (sin medir todavía)

| Parámetro | Valor | Motivo |
|---|---|---|
| Heap | **3 GiB** (3072 MiB en Prism) | La laptop ve solo 5.7 GiB porque la iGPU reserva 2 GiB. Con 3 GiB de heap más ~1–1.5 GiB nativos de la JVM, quedan ~1.5 GiB para el sistema. Usar 3.5 GiB solo si spark muestra presión de heap y el sistema no está usando swap. |
| Render / simulación | 8 / 6 | Configurado en `options.txt` del pack. |
| Shaders | No | Requisito del plan. |
| FPS máx. / VSync | 60 / sí | Menos calor y consumo; Dynamic FPS los baja aún más con la ventana sin foco. |
| Mapas | Xaero (minimapa + world map) | El minimapa de FTB está desactivado para no duplicar el costo de renderizado de mapas. |

### Cómo medir en la prueba de cliente (P2)
1. Abrir Prism con el navegador cerrado; observar `free -h` antes y durante el juego.
2. Entrar a un mundo nuevo, caminar ~5 minutos y luego quedarse quieto.
3. `F3`: FPS y uso de memoria de la JVM.
4. `/spark health` y `/spark tps` (en un solo jugador también funcionan).
5. Anotar FPS mínimos y medios, heap usado, RSS de la JVM (`ps -o rss= -p <pid>`) y si hubo swap (`vmstat 1`).
