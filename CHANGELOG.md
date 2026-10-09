# Changelog

Cada versión tiene una etiqueta git `v<versión>`. `bash scripts/build.sh` sobre esa etiqueta reconstruye el mismo `.mrpack`, byte por byte. Los `.mrpack` viven en `releases/`, fuera de git, junto con su `.sha256`.

**Líneas**
- **0.1.x**: línea base (Create + AE2 + calidad de vida), sin dimensiones nuevas. Rama `release/0.1`.
- **0.2.x**: la base + The Aether. Rama `release/0.2`. **Estable actual.**
- **0.3.0-alpha.N**: siguiente paso (Deep Aether, Deeper and Darker), en `main`. Las alphas pueden agregar y quitar mods entre sí; sus mundos son desechables (ver *Versiones y ramas* en el README).

## 0.2.0 — 2026-10-09 (estable)
- **Mismo contenido que 0.2.0-alpha.1**: los archivos y overrides de `modrinth.index.json` son idénticos; solo cambia el número de versión.
- **Validado por el usuario en el cliente (Prism)**: se cargaron los 67 mods que lista Prism (incluye los que vienen dentro de otros JARs), mundo nuevo, entrada al Aether y vuelta al Overworld. El log ya no muestra el error del plugin JEI de Applied Create.
- 57 artefactos (56 en el cliente, 38 en el servidor). `sha256 60b6799616b1f21771788bbf8f94c8107394680a8d93d8fdc4b1347b081b6892`

## 0.2.0-alpha.1 — 2026-10-09
- **Agregado**: The Aether 1.21.1-1.5.10 (trae dentro Accessories, Cumulus y Nitrogen) + owo-lib 0.12.15.5-beta.1.
- **Teclas**: accesorios del Aether (I) y capa de invisibilidad (V) sin asignar, porque chocaban con Dank Storage y la terminal de AE2. Los accesorios se abren con el botón del inventario.
- **Pruebas**: la integración de servidor incluye la dimensión del Aether y sus 4 estructuras (`docs/alpha1-integration.json`).
- 57 artefactos (56 en el cliente, 38 en el servidor). `sha256 a62e053c5af06f7d8856dec4ec7499aec5b0b3f101868d313e1713a36ca66b8f`

## 0.1.0-rc.5 — 2026-10-09
- **Agregado**: Jade 15.10.6 (`both`): información del bloque o entidad que se mira. Integra AE2, Extended AE, Waystones, GraveStone y Balm.
- **Herramientas**: `validate.py` resuelve `${file.jarVersion}` desde el manifest del JAR, igual que FML. Ahora se verifican los rangos de 4 bibliotecas embebidas más (262 rangos).
- **Probado**: servidor actualizado in situ desde rc.4 con integración aprobada (`docs/rc5-integration.json`). Prism no muestra avisos de dominios (P4 cerrado).
- 55 artefactos (54 en el cliente, 36 en el servidor). `sha256 86e93ac7254d9031719cab25c91d5bbff72a54e5931127e71370523831a7bcf0`

## 0.1.0-rc.4 — 2026-10-09
- **Agregado**: Iris 1.8.12 y 5 shaderpacks apagados por defecto (MakeUp Ultra Fast, Mellow, Miniature, Sildur's Basic y Vibrant); Controlling 19.0.5 + Searchables 1.0.2; AE2 JEI Integration 1.2.1.
- **Cambiado**: Sodium 0.8.13 → 0.6.13 (pareja estable con Iris). Teclas: menú de Building Gadgets K → H; Iris K/R; selector de shaders sin tecla.
- **Corregido**: el plugin JEI de Applied Create fallaba con `NoClassDefFoundError` (visto en el cliente rc.3).
- `sha256 c84aaf79b38c2dd1537341b2d98f5a43d1d9f86260a7d81514c1b3eec9ffd2ae`

## 0.1.0-rc.3 — 2026-10-09
- **Agregado**: FTB Chunks + FTB Teams (100 chunks reclamados y 100 forzados por jugador); Just Zoom 2.1.0 (+ Konkrete); Sophisticated Backpacks + Sophisticated Core; GraveStone.
- **Cambiado**: JEI, Architectury y FTB Library también en el servidor; teclas sin conflictos (zoom C, mochila B/Z/X, waypoint N, mapa de FTB J).
- **Probado**: primera prueba de cliente en Prism: arranque en ~36 s y mundo nuevo sin problemas.
- `sha256 b9455c3933efd4a46bfe036c50aab5f0aec9f9fe44fbb0c82c1b279c4e4333a8`

## 0.1.0-rc.2 — 2026-10-09
- **Corregido**: la release rc.1 no incluía configs ni atajos de teclado. Ahora se indexan `config/` y `options.txt` (en `client-overrides/`).
- **Herramientas**: instalación de servidor idempotente con registro de hashes; pruebas de integración y pregeneración automatizadas.
- `sha256 2ca94de531d849e96b59a26bd9d928e5960c6534b2a1f9961f0b96ecfef9826c`

## 0.1.0-rc.1 — 2026-10-09
- Base del agente anterior (Astra): 38 artefactos con Create, AE2 y addons, calidad de vida, exploración ligera y optimización. Excessive Utilities con las quarries desactivadas.
- `sha256 5dabeb13b0339d899f4a032ce3c3255c3b77ee4a82aa5d891596f6de8bcac5c8`
