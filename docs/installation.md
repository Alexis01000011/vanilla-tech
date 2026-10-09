# Instalación y actualización

Release actual: `releases/vanilla-tech-0.1.0-rc.2.mrpack` (Minecraft 1.21.1, NeoForge 21.1.257, Java 21).
El `.mrpack` solo contiene el manifiesto y las configs: los launchers descargan cada JAR de Modrinth o CurseForge y verifican su hash.

> Si no tienes el `.mrpack`, genéralo con `bash scripts/build.sh` (ver [README](../README.md)).

---

## 1. Cliente — Prism Launcher (Linux)

### Requisitos
- Prism Launcher y una cuenta de Microsoft con Minecraft Java.
- Java 21. Prism puede descargarlo solo; en Arch también sirve `pacman -S jre21-openjdk`.
- Sin shaders. Sodium ya viene incluido.

### Importar
1. En Prism: **Add Instance → Import** y elige el archivo `vanilla-tech-0.1.0-rc.2.mrpack`.
2. Prism descarga 39 mods (Chunky es solo de servidor). Ocho vienen de `edge.forgecdn.net` (CurseForge): Building Gadgets 2, Charging Gadgets, Dank Storage, FTB Chunks, FTB Teams, FTB Library, FTB JEI Extras y Architectury. Si Prism avisa de descargas desde dominios fuera de su lista blanca, acepta: son las URLs oficiales de CurseForge y cada archivo se verifica por hash. *(Aviso pendiente de confirmar en la prueba de cliente.)*
3. **Edit Instance → Settings → Java**:
   - Memoria máxima: **3072 MiB** en la laptop de 8 GB, porque la iGPU reserva 2 GiB y el sistema solo ve 5.7 GiB. Sube a 3584 MiB solo si `/spark health` muestra presión de memoria y el sistema no está usando swap. Detalles en [performance.md](performance.md).
   - Memoria mínima: 1024 MiB.
   - Argumentos JVM: no hacen falta (Java 21 usa G1 por defecto).
4. Lanza la instancia. El primer arranque tarda más porque compila cachés.

### Lo que trae preconfigurado (`client-overrides/options.txt`)
Distancia de renderizado 8, simulación 6, 60 FPS con VSync, gráficos *Fast* y estos atajos:

| Acción | Tecla | Motivo |
|---|---|---|
| Terminal inalámbrica AE2 | V | Sin asignar por defecto. |
| Building Gadgets: menú | K | G lo usa Curios. |
| Building Gadgets: deshacer / ancla / rango | Retroceso / Inicio / Fin | Sin asignar por defecto. |
| Mapa de FTB Chunks (reclamar y forzar chunks) | J | M lo usa el World Map de Xaero. |

Para revisar conflictos: **Opciones → Controles**; las teclas repetidas aparecen en rojo.

### Unirse al servidor
**Multiplayer → Add Server** con la IP o el DNS del servidor (puerto 25565). El servidor tiene whitelist activada, así que el admin debe añadirte antes.

---

## 2. Servidor dedicado (Linux x86-64, p. ej. AWS EC2)

> Este repositorio **no** crea ni modifica infraestructura de AWS. Estos pasos suponen una instancia ya creada por el propietario.

### Requisitos
- Java 21 *headless* (Amazon Corretto 21 u OpenJDK 21).
- Python ≥ 3.11 (solo para `prepare-server.py`) y git.
- Puerto **TCP 25565** abierto en el *security group*, idealmente solo para las IP de los dos jugadores.
- RAM: ver [performance.md](performance.md) (heap de 5 GiB con 8 GiB de RAM, 8 GiB con 16 GiB de RAM).

### Instalar
```bash
git clone <este-repo> vanilla-tech && cd vanilla-tech
bash scripts/build.sh                     # genera releases/vanilla-tech-<versión>.mrpack
python3 scripts/prepare-server.py --directory /srv/minecraft/vanilla-tech --heap 5G   # 8G en 16 GiB
```
`prepare-server.py` hace lo siguiente:
- Verifica el instalador de NeoForge por SHA-256 e instala el servidor.
- Descarga solo los mods de servidor (31 JARs; omite los 9 de solo cliente) y verifica sus hashes.
- Copia las configs del pack.
- Escribe `server.properties` y `user_jvm_args.txt` a partir de `server-template/`, solo si no existen.
- **No acepta la EULA.**

### Primer arranque
```bash
cd /srv/minecraft/vanilla-tech
# El propietario lee https://aka.ms/MinecraftEULA y, si está de acuerdo:
echo "eula=true" > eula.txt
bash run.sh nogui
```
Ya en la consola del servidor:
```
whitelist add imalexisxo
whitelist add <jugador2>
op imalexisxo
```
**`imalexisxo` es el administrador previsto.** `op` necesita que la cuenta exista (el servidor resuelve el UUID con `online-mode=true`); por eso se hace en el servidor real y no se incluye en el modpack.

### Ejecutarlo como servicio (opcional)
Ejemplo con systemd + tmux, para conservar acceso a la consola:
```ini
# /etc/systemd/system/vanilla-tech.service
[Unit]
Description=Vanilla Tech Minecraft server
After=network-online.target

[Service]
Type=forking
User=minecraft
WorkingDirectory=/srv/minecraft/vanilla-tech
ExecStart=/usr/bin/tmux new-session -d -s vanilla-tech 'bash run.sh nogui'
ExecStop=/usr/bin/tmux send-keys -t vanilla-tech 'stop' Enter
ExecStop=/bin/sh -c 'while tmux has-session -t vanilla-tech 2>/dev/null; do sleep 1; done'
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
```
Para ver la consola: `sudo -u minecraft tmux attach -t vanilla-tech`. Para salir sin detener el servidor: `Ctrl+B`, luego `D`.

### Pregeneración (recomendada antes de jugar)
Desde la consola, con nadie conectado:
```
chunky world minecraft:overworld
chunky center 0 0
chunky radius 1000
chunky start
```
`chunky progress` muestra el avance. Mide con `spark tps` al terminar. Los tiempos medidos están en [performance.md](performance.md).

### Backups
- Mínimo: un backup diario del directorio del mundo (`world/` o el `level-name` que configures), más `config/`, `defaultconfigs/`, `server.properties`, `ops.json` y `whitelist.json`.
- Backup consistente con el servidor encendido: `save-off`, luego `save-all flush`, copiar el mundo (`tar`/`rsync`) y por último `save-on`.
- Guarda los backups **fuera** de la instancia, por ejemplo con un *snapshot* de EBS o en otra máquina. Configurar eso en AWS le corresponde al propietario.

---

## 3. FTB Chunks — chunkloading

- **J** abre el mapa de FTB Chunks; desde ahí se reclaman chunks y se fuerza su carga. Las instrucciones aparecen en pantalla.
- Límites por jugador: **100 chunks reclamados** y **100 forzados**.
- **Recomendado: formen un *party*.** Abre la pantalla de equipos desde el botón del inventario o con `/ftbteams party create <nombre>` y luego invita al otro jugador. Con `party_limit_mode = "sum"`, el equipo dispone de 200 + 200, y basta con que **uno** de los dos esté conectado para que funcionen las granjas de ambos.
- Los chunks forzados **solo cargan si hay un miembro del equipo conectado** (`force_load_mode = "never"`). Para granjas 24/7, cambia a `"always"` (ver abajo) y vigila el costo en CPU.
- La protección de claims está **desactivada** (`disable_protection = true`): los claims sirven solo para chunkloading, y así Create y AE2 funcionan sin restricciones.

### Cambiar la configuración de FTB Chunks en el servidor
- **Defaults del pack**: `config/ftbchunks-world.snbt`. Este archivo puede sobrescribirse al actualizar el pack.
- **Override local del admin**: copia ese archivo a `<mundo>/serverconfig/ftbchunks-world.snbt` y edítalo; las actualizaciones del pack no lo tocan. Reinicia el servidor para aplicar los cambios.

---

## 4. Actualizar

### Servidor
```bash
cd vanilla-tech && git pull && bash scripts/build.sh
# detener el servidor y hacer backup del mundo primero
python3 scripts/prepare-server.py --directory /srv/minecraft/vanilla-tech
```
Comportamiento del script:
- **JARs**: quita los que instaló una release anterior y ya no están en el pack. Si encuentra un JAR que no instaló el pack, se detiene.
- **Configs que el pack no cambió**: no las toca, aunque las haya reescrito un mod o editado el admin.
- **Configs que el pack sí cambió**: si nadie las tocó localmente, las reemplaza. Si las cambiaron las dos partes, se detiene y lista los archivos; revísalos y vuelve a correr con `--replace-configs`, que guarda la copia local como `*.bak-<versión>`.

### Cliente (Prism)
La forma más segura es crear una instancia nueva con el `.mrpack` nuevo y copiar desde la anterior:
- `saves/` (mundos locales), `options.txt`, `servers.dat`.
- `xaero/` (waypoints y mapa explorado) y `local/` (datos de cliente de FTB).

Alternativa a futuro, sin pasos manuales: publicar el repositorio y usar `packwiz-installer-bootstrap` como *pre-launch command* de Prism apuntando al `pack.toml` publicado. Así cada arranque sincroniza el cliente con la versión del repositorio.
