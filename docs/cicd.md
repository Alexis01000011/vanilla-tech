# CI/CD de Vanilla Tech

Cómo un cambio del pack llega a los clientes (Prism) y al servidor EC2 sin reinstalar instancias ni arriesgar el mundo.

```
 PR / push ──► CI ──────────────► etiqueta vX.Y.Z ──► Release ───────────────► Deploy (manual + aprobación) ─────────────► clientes
              lint, build,          (inmutable)        GitHub Release           plan: impacto vs. lo que corre la EC2          Prism pre-launch:
              JARs, rangos,                            Pages: releases/<v>/     ├─ solo cliente: no toca la EC2                stable/pack.toml
              smoke NeoForge                           staging/ ─► Prism de     └─ servidor: OIDC → SSM → deploy.sh            descarga solo
              (si toca servidor)                       prueba                      backup → pack → arranque → healthcheck      lo que cambió
                                                                                   ✔ sano → promueve stable/ + server/
                                                                                   ✘ falla → restaura backup, stable no cambia
```

- **Publicar no es desplegar.** Una etiqueta publica una release inmutable y mueve `staging`. Nada llega al servidor ni a los clientes sin el workflow **Deploy** y la aprobación del environment `production`.
- **`stable` cambia solo después** de que el servidor quedó sano con esa versión (o si la release es solo de cliente).
- Nunca se despliega por un push, ni se prende la EC2 por un push.

## 1. Diagnóstico (2026-10-10)

| Tema | Estado real |
|---|---|
| Repositorio | packwiz (`pack.toml`, `index.toml`, 72 `mods/*.pw.toml`, 5 shaderpacks, 1 resource pack, 7 configs, `options.txt`). Etiquetas `v0.1.0-rc.1`…`v0.5.0-alpha.1`, ramas `release/0.x`. `build.sh` produce un `.mrpack` determinista (el sha está en el CHANGELOG). Solo local: sin remoto ni CI. |
| Lados | `side` de cada metafile → `env` del `.mrpack`: 77 artefactos de cliente, 53 de servidor (Chunky solo servidor; Sodium, Iris, Dynamic FPS, etc. solo cliente). |
| Actualización de clientes | No existía: cada versión era un `.mrpack` importado como instancia nueva. |
| Servidor | EC2 (variable `EC2_INSTANCE_ID`; r8i.large, 16 GiB, AL2023). `vanilla-tech.service` (systemd) corre `docker run itzg/minecraft-server:java21` con `TYPE=MODRINTH` y `MODRINTH_MODPACK=/modpacks/vanilla-tech.mrpack`. `ExecStartPre=sync-modpack.sh` copia `s3://<bucket>/modpack/vanilla-tech.mrpack` sobre el archivo local **en cada arranque**. |
| Cómo instala itzg | mc-image-helper `install-modrinth-modpack`: baja los archivos con `env.server≠unsupported` (menos su lista interna de mods de cliente), copia `overrides/` + `server-overrides/` con reemplazo **en cada arranque**, instala NeoForge y borra lo que instaló el pack anterior y el nuevo ya no trae (manifiesto `/data/.modrinth-modpack-manifest.json`). La "versión" de un `.mrpack` local es su fecha de modificación. |
| Datos persistentes | `/opt/vanilla-tech/data/`: `world/` (Overworld, `DIM-1`, `DIM1`, `dimensions/…` del Aether, Otherside, etc.; `playerdata/`, `advancements/`, `stats/`, `data/` con FTB Chunks/Teams), `server.properties` (lo regenera itzg desde `mc.env`), `whitelist.json`, `ops.json`, `banned-*.json`, `config/`, `defaultconfigs/`. |
| Acceso | Sin SSH. SSM Agent con `AmazonSSMManagedInstanceCore` en `vanilla-tech-server-role` (+ S3 `modpack/*` y `backups/*`, token de Cloudflare). SG solo 25565. |
| Encendido/apagado | Lambda `vanilla-tech-power` (HTTP API) **solo prende** (`StartInstances`). El apagado es el cron `idle-shutdown.sh`: 10 min sin jugadores → `backup.sh` (mundo a S3, versionado) → `shutdown -h now`; también apaga si RCON no responde 30 min. Respeta el flag de pregeneración. |
| DNS | Registro A del servidor en Cloudflare (DNS-only, DDNS en cada arranque). El dominio real no es el `mods.alexis.online` del handoff; no se tocó DNS. |
| Hosting para manifiestos | No había. Se eligió GitHub Pages (abajo). `packs.alexis.online` era una propuesta; no se creó ningún dominio. |
| SO del amigo | Windows (confirmado por el usuario). La guía usa rutas y PowerShell de Windows; el comando de Prism es el mismo en Linux. |

## 2. Decisiones

1. **packwiz sigue siendo la fuente de verdad.** El `.mrpack` es un derivado determinista del mismo commit; el CI comprueba que reproduce el sha del CHANGELOG.
2. **Sitio estático en GitHub Pages** (gratis, HTTPS, despliegue atómico del sitio completo por cada push a `gh-pages`, fuera de la EC2). Requiere repositorio **público** en el plan gratuito: el repo solo tiene metadatos, configs y scripts (se verificó que no hay secretos; las IDs de cuenta e instancia viven en variables del repo y en la instancia, no en el código).
3. **Alias = copia completa.** `packwiz-installer` no sigue `..` fuera de la carpeta del `pack.toml` (verificado en su código), así que `stable/` y `staging/` son copias íntegras de `releases/<v>/`. Cada árbol está encadenado por hashes (pack → index → archivos) y `release.py verify` lo comprueba antes de cada push. Si un CDN sirviera una mezcla de versiones, el instalador rechaza el hash y **no aplica nada** (probado).
4. **El servidor sigue con itzg `TYPE=MODRINTH`** (no se impuso otro mecanismo). `deploy.sh` usa el `.mrpack` de la release, verificado contra el sha que manda el pipeline, y además confirma que los mods instalados son exactamente los de servidor de la release (nombre + sha512).
5. **El puntero de S3 y el archivo local siempre iguales.** Como `sync-modpack.sh` baja el objeto de S3 en cada arranque, `deploy.sh`/`rollback.sh` actualizan ambos; si no, el próximo arranque cambiaría de pack sin backup ni healthcheck.
6. **GitHub OIDC → rol mínimo → un documento SSM.** El rol solo se puede asumir desde el environment `production` de este repo y solo puede: ejecutar `VanillaTech-Deploy` sobre esta instancia, leer resultados, describir y **prender** la instancia. Los parámetros del documento están restringidos por regex (versión, sha256, id de backup, valores fijos): no hay interpolación libre de shell.
7. **EC2 apagada:** el deploy falla sin cambios y pide prenderla (botón) o relanzar con `start_if_stopped` (la decisión queda en quien aprueba). No se implementó "pendiente para el próximo arranque": ejecutaría un deploy sin nadie mirando cuando un jugador aprieta el botón.
8. **Backups locales completos + copia externa.** Antes de cada cambio: tar.zst del directorio de datos completo (mundo, mods, configs, librerías: arranca sin red) + el `.mrpack` activo + checksums, verificado; y el `backup.sh` existente sube el mundo a S3 (bucket versionado ya existente). Retención local: 3 (mínimo 2) más los protegidos.
9. **Archivos del jugador con `preserve`.** `options.txt` y `shaderpacks/*.txt` se marcan `preserve = true` en `index.toml` (lo hace `build.sh`; `release.py publish` lo aplica también a etiquetas viejas). El `.mrpack` no cambia por esto (sha `3578edc3…` idéntico).
10. **Sin archivo `VERSION`.** La versión vive en `pack.toml`; el CI exige que coincidan etiqueta, `pack.toml`, `modrinth.index.json` y una entrada `## <versión>` en el CHANGELOG. `release.json` registra versión, commit, MC/NeoForge, sha256/sha512 del `.mrpack` y la huella de cliente y de servidor.
11. **Impacto calculado, no declarado.** `release.py impact` compara huellas: `none`, `client` (no toca la EC2), `low` (configs de servidor), `medium` (mods de servidor actualizados), `high` (mods de servidor agregados/quitados → exige `confirm_high_impact`). Cambiar Minecraft/NeoForge se bloquea en lint, en el deploy y en `deploy.sh`.

## 3. Archivos

| Ruta | Qué es |
|---|---|
| `.github/workflows/ci.yml` | PR/push: `check-pack.py` → packwiz compilado del commit fijado → `build.sh` → `check.sh` (hashes, lados, dependencias anidadas, rangos con Maven VersionRange, worldgen) → `check-itzg.py` → impacto → smoke test NeoForge si toca servidor. Sin AWS. |
| `.github/workflows/release.yml` | Etiqueta `v*`: lo mismo sobre la etiqueta + reproducibilidad contra el CHANGELOG + GitHub Release + `releases/<v>/` y `staging/` en Pages + instalación real con packwiz-installer (cliente y servidor) desde la URL publicada. `bootstrap` (una vez) registra la release que ya corre. |
| `.github/workflows/deploy.yml` | Manual. `plan` (sin aprobación): release publicada, sha del sitio = sha de la GitHub Release, impacto, puertas. `deploy` (environment `production`): SSM → `deploy.sh`; si sano, promueve `stable/` y `server/`; verifica instalación desde `stable/`. |
| `.github/workflows/rollback.yml` | Manual con aprobación: SSM → `rollback.sh`, luego `stable/` y `server/` → versión restaurada. |
| `scripts/release.py` | `meta`, `impact`, `publish` (inmutable), `alias`, `server`, `verify`, `render` del sitio. |
| `scripts/check-pack.py`, `check-itzg.py`, `check-quests.py`, `check-install.py`, `preserve.py` | Lint rápido; mods que itzg omitiría; IDs del quest book; instalación real con packwiz-installer; marcas `preserve`. |
| `scripts/ci/*.sh` | packwiz desde fuente, impacto, smoke, checkout/push de `gh-pages`, espera de Pages. |
| `ops/ec2/` | Lo que corre en la instancia (`/opt/vanilla-tech/cd/`): `deploy.sh`, `rollback.sh`, `healthcheck.sh`, `status.sh`, `drill.sh`, `lib.sh`, `mc_tools.py` (Python 3.9), `install.sh`. |
| `ops/aws/` | `ssm-document.yaml`, plantillas de trust/política IAM, `setup-aws.sh`, `install-on-instance.sh`. |
| `ops/github/ssm-run.sh` | Ejecuta el documento SSM y traduce códigos de salida. |
| `ops/tests/`, `scripts/tests/` | Pruebas locales: e2e del servidor (NeoForge real, sin AWS) y escenario de Prism. |

## 4. Operación

### Publicar una versión
1. Cambios en una rama → PR → CI verde.
2. Subir `version` en `pack.toml`, `bash scripts/build.sh && bash scripts/check.sh`, entrada `## X.Y.Z — fecha` en el CHANGELOG con el `sha256`, merge.
3. `git tag -a vX.Y.Z -m … && git push origin vX.Y.Z` → workflow **Release**.
4. Probar en una instancia de Prism con `…/staging/pack.toml` (y el smoke test del CI para el servidor).

### Desplegar
Actions → **Deploy** → `version=X.Y.Z` → aprobar en `production`.
- Con jugadores conectados, `deploy.sh` no hace nada (código 10). `kick_players` avisa 60 s y reinicia: solo con su acuerdo.
- La EC2 queda prendida tras el deploy y el cron la apaga a los ~10 min sin jugadores (el contador se reinicia al terminar).

`deploy.sh` en la instancia, en orden:
1. Valida versión y sha256 (regex), descarga el `.mrpack` a `cd-state/releases/<v>/` y exige el sha del pipeline; rechaza otro Minecraft/NeoForge (12), downgrades (13), `.jar` embebidos, rutas raras y hosts fuera de Modrinth/CurseForge; descarga y verifica con sha512 **todos** los archivos de servidor. Hasta aquí el server no se tocó.
2. Lock (`flock`) + flag de mantenimiento (`idle-shutdown.sh` no apaga; un flag de más de 3 h se ignora). Si el server está arrancando, espera; si hay jugadores, sale.
3. Detiene el servicio y comprueba que ningún proceso tiene archivos abiertos en `data/` y que nada se escribe en 5 s.
4. Backup completo verificado (checksums + prueba del archivo comprimido + `level.dat` presente) y copia del mundo a S3.
5. Activa el pack (S3 + local, atómico) y arranca.
6. Healthcheck: `Done (` en un `latest.log` posterior al arranque (falla rápido ante crash, error de carga de mods o del instalador), Server List Ping real al 25565 con versión 1.21.1, RCON `list`, mods instalados = mods de servidor de la release, pack activo = versión pedida.
7. Registra `cd-state/active-release.json`, `history.jsonl` y el log en `/var/log/vanilla-tech-cd/`. Libera lock y reinicia el contador de inactividad.
8. Si falla después de activar el pack: detiene, aparta los datos a `failed/`, restaura el backup completo y el pack anterior, arranca y verifica (código 2). Si eso también falla: código 3, intervención manual.

### Rollback
Actions → **Rollback** → `target=previous` (backup tomado antes del deploy activo) o un id. **El mundo vuelve al momento del backup.** Antes se guarda un backup de seguridad del estado actual; deshacer = rollback a ese id. Para volver solo el pack conservando el mundo (cambios sin registros nuevos): Deploy con la versión anterior y `allow_downgrade`.

Desde tu Linux, sin GitHub: `./vt-control.sh cd-status`, `./vt-control.sh cd-drill`, y para rollback manual por SSM `ops/github/ssm-run.sh rollback --target previous` con `INSTANCE_ID` (credenciales de admin).

### Ensayo de restauración
`drill.sh [id|latest]` extrae un backup a un directorio temporal y comprueba `level.dat` (NBT), regiones por dimensión, playerdata, mods y archivos clave; no toca el servidor. Recomendado tras instalar el pipeline y una vez al mes.

## 5. Backups y retención

| Copia | Dónde | Cuándo | Retención | Costo aprox. |
|---|---|---|---|---|
| Completa (datos + pack) | EBS, `/opt/vanilla-tech/backups/<fecha>-<versión>/` | antes de cada deploy/rollback | 3 más recientes + la de "previous" y la de seguridad | 0 extra (cabe en los 27 GB libres: ~0.5–1 GB cada una) |
| Mundo | `s3://…/backups/world.tar.gz` (versionado) | cada apagado por inactividad y antes de cada deploy | 10 versiones anteriores (lifecycle existente) | ~USD 0.03/mes (≈1.4 GB) |
| Datos reemplazados por una restauración | `/opt/vanilla-tech/failed/` | al revertir | 2 más recientes | 0 extra |
| Packs desplegados | `cd-state/releases/`, S3 `modpack/releases/`, GitHub Release, Pages | por release | indefinida (KB) | ~0 |

No se crearon buckets nuevos ni snapshots de EBS.

## 6. FTB Quests (para la release que lo agregue)

- Versión que está evaluando la sesión de Codex: **FTB Quests 2101.1.36** (rama `1.21.1/main`), con FTB Library/Teams/Architectury ya presentes.
- **Definiciones**: `config/ftbquests/quests/**.snbt` (+ `lang/`). Van en el pack como configs: se versionan e itzg las reescribe en cada arranque.
- **Progreso**: `world/ftbquests/<equipo>.snbt` en el servidor. Está dentro de `world/`: lo cubren los backups y ningún deploy lo sobrescribe.
- **IDs**: el progreso apunta a los IDs hex de las definiciones. `check-quests.py` (CI) falla si una release quita IDs, salvo `ALLOW_QUEST_ID_REMOVAL=1`. Editar el libro en el editor del juego conserva los IDs; regenerarlo desde cero no.
- **Recarga sin reinicio**: `/ftbquests reload quests` (op) relee `config/ftbquests/quests` y sincroniza a todos sin tocar el progreso. Es viable para releases que solo cambian el libro, pero **no se implementó**: saltaría el manifiesto de itzg y el propio mod advierte que la recarga es para desarrollo. Hoy un cambio del libro se despliega como `low` (reinicio ~3 min). Revisar cuando el libro exista.

## 7. Seguridad

- Sin llaves de AWS en GitHub: OIDC con `aud` y `sub` fijos (`repo:<owner>/<repo>:environment:production`); `mask-aws-account-id` activo.
- El rol no puede apagar, terminar, cambiar red, ni leer el token de Cloudflare.
- `production` exige aprobación manual y solo acepta la rama `main`. El ARN del rol y el ID de la instancia son secrets **de ese environment**: no existen para PRs ni forks, solo después de aprobar, y se enmascaran en los logs (públicos en un repo público).
- El sitio solo publica lo que lista `index.toml` (metafiles, configs, `options.txt`) + `.mrpack` + `release.json`. `check-pack.py` rechaza JARs, mundos, logs y cadenas con forma de credencial.
- Las Lambdas, el DNS, el security group, `mc.env` y `user-data.sh` no cambian. En la instancia solo se agrega `/opt/vanilla-tech/cd/` y una línea en `idle-shutdown.sh` (con copia `.bak`).

## 8. Costos

| Concepto | Costo |
|---|---|
| GitHub Actions + Pages (repo público) | 0 |
| IAM, OIDC, SSM Run Command, documento SSM | 0 |
| S3 adicional | centavos/mes |
| EC2 durante un deploy | ~USD 0.14/h mientras esté prendida; un deploy toma ~5–8 min + el apagado por inactividad (~10 min) |

## 9. Pruebas

Resultados, fallas encontradas y pendientes: [cicd-test-results.md](cicd-test-results.md).

## 10. Configuración pendiente (requiere autorización)

| Paso | Quién | Comando / lugar |
|---|---|---|
| Iniciar sesión en GitHub CLI | ✅ hecho | `gh auth login` |
| Repo **público** con `main`, `release/*` y etiquetas (historial con correo noreply) | ✅ hecho 2026-10-10 | github.com/Alexis01000011/vanilla-tech |
| Pages desde `gh-pages`; variables `PACK_SITE_URL`, `AWS_REGION` | ✅ hecho | https://alexis01000011.github.io/vanilla-tech/ |
| Environment `production`: revisor obligatorio Alexis01000011, solo rama `main` | ✅ hecho | Settings → Environments |
| Publicar 0.5.0-alpha.1 como base (bootstrap) | Claude con tu OK | Actions → Release → `tag=v0.5.0-alpha.1`, `bootstrap=true` |
| OIDC + rol + documento SSM | ✅ hecho 2026-10-10 (autorizado) | `GITHUB_REPO=Alexis01000011/vanilla-tech INSTANCE_ID=<id> ops/aws/setup-aws.sh` |
| Instalar `ops/ec2` en la instancia (no reinicia Minecraft) | Claude con tu OK, instancia prendida | `ops/aws/install-on-instance.sh`, luego `drill.sh latest` |
| Secrets del environment `production`: `AWS_DEPLOY_ROLE_ARN`, `EC2_INSTANCE_ID` | ✅ hecho | enmascarados en los logs públicos |
| Configurar Prism del amigo | el amigo | [auto-update-prism.md](auto-update-prism.md) |
| Primer deploy real por el pipeline | tú apruebas | Deploy de la próxima versión |
