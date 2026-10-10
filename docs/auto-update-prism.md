# Actualizaciones automáticas en Prism Launcher

Con esto, cada vez que le das a **Jugar**, Prism revisa si hay una versión nueva del modpack y descarga solo lo que cambió. No hay que volver a importar `.mrpack` ni copiar mundos.

> **URL del modpack:** `https://alexis01000011.github.io/vanilla-tech/stable/pack.toml`
> (Ábrela en el navegador: tiene que mostrar un texto que empieza con `name = "Vanilla Tech"`.)

Se configura **una sola vez** por instancia. El `.mrpack` que ya importaste no se actualiza solo: necesita estos pasos.

## Qué toca y qué no

| El actualizador **sí** cambia | El actualizador **nunca** toca |
|---|---|
| Los mods del pack: agrega, actualiza y quita **solo los que instaló el pack** | Tus mundos (`saves/`), capturas, `servers.dat` |
| Las configs que trae el pack (`config/…` del pack) | `options.txt`: opciones, **teclas**, FOV, sonido |
| Los resource packs y shaderpacks del pack | Los ajustes de shaders (`shaderpacks/*.txt`) |
| | Mods que agregaste tú, mapas de Xaero, configs que creen los mods |

`options.txt` y los ajustes de shaders solo se escriben si no existen (instancia nueva). Por eso, si una versión cambia una tecla por defecto, en tu instancia no se aplica sola: el cambio viene anotado en el CHANGELOG.

## Configuración (una vez)

### 1. Respaldo de la instancia
Cierra el juego. En Prism, clic derecho sobre la instancia de Vanilla Tech → **Copiar** → nómbrala `Vanilla Tech (respaldo)`. Así tienes todo (mundos, opciones, Java) por si algo sale mal.

### 2. Descargar el bootstrap oficial
Descarga `packwiz-installer-bootstrap.jar` (versión **v0.0.3**) desde la página oficial:
<https://github.com/packwiz/packwiz-installer-bootstrap/releases/tag/v0.0.3>

Opcional, para comprobar que es el archivo correcto: en **Windows**, abre PowerShell en la carpeta de Descargas y corre
```powershell
Get-FileHash .\packwiz-installer-bootstrap.jar
```
El `Hash` tiene que ser `A8FBB24DC604278E97F4688E82D3D91A318B98EFC08D5DBFCBCBCAB6443D116C` (en Linux: `sha256sum packwiz-installer-bootstrap.jar`, en minúsculas).

### 3. Copiarlo a la carpeta del juego de esa instancia
Clic derecho en la instancia → **Carpeta** (*Folder*). Entra a la carpeta `minecraft` (o `.minecraft`): es la que tiene `options.txt`, `mods/` y `saves/`. Copia ahí el `.jar`.

En Windows suele ser `%APPDATA%\PrismLauncher\instances\<nombre de la instancia>\minecraft\` (pégalo en la barra del Explorador). Si Windows oculta las extensiones, el archivo se ve como `packwiz-installer-bootstrap` con tipo *Executable Jar File*: está bien, no le cambies el nombre.

No lo pongas en la carpeta general de Prism ni en `mods/`.

### 4. Comando previo al lanzamiento
Clic derecho en la instancia → **Editar** → **Configuración** → pestaña **Comandos personalizados** (*Custom commands*):
1. Marca la casilla **Comandos personalizados**.
2. En **Comando previo al lanzamiento** (*Pre-launch command*) pega, tal cual (es igual en Windows y en Linux; Prism se encarga de las comillas y de `$INST_JAVA`):

   ```
   "$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://alexis01000011.github.io/vanilla-tech/stable/pack.toml
   ```
3. Cierra la ventana (se guarda sola).

`$INST_JAVA` lo reemplaza Prism por el Java de la instancia; no lo cambies.

### 5. Jugar
Dale a **Jugar**. Antes del juego aparece una ventanita *packwiz-installer*:
- **La primera vez** revisa los ~90 archivos del pack. Si tu instancia ya tiene la misma versión, termina en unos segundos sin descargar mods.
- **Cuando hay versión nueva**, descarga solo lo que cambió y luego abre el juego.
- **Si no hay internet** o la página no responde, muestra un error con dos botones: **Continue without updating** (juegas con lo que tienes; para el servidor necesitas la versión correcta) o **Quit**.

## ¿Qué versión tengo?
- La versión vigente está en <https://alexis01000011.github.io/vanilla-tech/> (fila con `stable`).
- Si el servidor tiene otra versión, Minecraft no te deja entrar y avisa de mods distintos: cierra el juego y vuelve a darle a **Jugar** para que se actualice.

## Problemas
| Síntoma | Qué hacer |
|---|---|
| Error *Failed to download pack.toml* | Revisa tu internet y abre la URL del modpack en el navegador. Si no carga, avísale a Alexis; mientras, usa **Continue without updating**. |
| Error de *hash* o *Invalid mod file hash* | La publicación se está propagando o un archivo se bajó mal. Elige **Quit**, espera unos minutos y vuelve a darle a **Jugar**. No se aplica nada a medias. |
| El juego no abre después de actualizar | Abre la instancia `Vanilla Tech (respaldo)` para seguir jugando y avísale a Alexis con el log de Prism. |
| Quiero dejar de actualizar automáticamente | Desmarca **Comandos personalizados** en la instancia. |

## Para probar versiones nuevas (solo Alexis)
Una segunda instancia con el mismo procedimiento pero con `…/staging/pack.toml` recibe las releases antes de que se aprueben para todos. Nunca uses `staging` para entrar al servidor real.
