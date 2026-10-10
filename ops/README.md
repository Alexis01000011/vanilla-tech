# ops — despliegue del servidor Vanilla Tech

Contexto, decisiones y runbooks: [../docs/cicd.md](../docs/cicd.md).

| Carpeta | Contenido | Dónde corre |
|---|---|---|
| `ec2/` | `deploy.sh`, `rollback.sh`, `healthcheck.sh`, `status.sh`, `drill.sh`, `lib.sh`, `mc_tools.py`, `install.sh`, `cd.env.example` | En la instancia, en `/opt/vanilla-tech/cd/` (root, por SSM). Python 3.9 + bash, sin dependencias extra (zstd opcional). |
| `aws/` | `ssm-document.yaml` (VanillaTech-Deploy), plantillas IAM (trust OIDC + política mínima), `setup-aws.sh`, `install-on-instance.sh` | Tu Linux, con credenciales de admin y **autorización** del dueño. |
| `github/` | `ssm-run.sh`: corre el documento SSM y espera el resultado | GitHub Actions (OIDC) o tu Linux |
| `tests/` | `e2e-local.sh` + `local-runtime.sh`/`fake-container.sh` (emulan systemd+itzg con mc-image-helper y NeoForge real), `idle-shutdown.fixture.sh` | Tu Linux, sin AWS ni root |

Códigos de salida de `deploy.sh`/`rollback.sh`: `0` ok · `1` error sin cambios · `2` falló y se revirtió · `3` intervención manual · `10` hay jugadores · `11` lock ocupado · `12` cambio de Minecraft/NeoForge sin autorización · `13` downgrade sin autorización.

## Prueba local de punta a punta
```bash
python3 scripts/tests/make-variant.py --tag v0.5.0-alpha.1 --version 0.5.1-alpha.2 --out /tmp/r2 \
  --remove mods/chunky.pw.toml --append 'config/lithium.properties=# e2e\n'
python3 scripts/tests/make-variant.py --tag v0.5.0-alpha.1 --version 0.5.1-alpha.3 --out /tmp/r3 \
  --remove mods/architectury-api.pw.toml          # release rota a propósito
bash ops/tests/e2e-local.sh /tmp/e2e <mc-image-helper>/bin/mc-image-helper <modrinth-exclude-include.json> \
  . releases/vanilla-tech-0.5.0-alpha.1.mrpack /tmp/r2 /tmp/r3 <árbol v0.4.0> <vanilla-tech-0.4.0.mrpack>
```
`mc-image-helper` es el instalador que usa la imagen itzg (github.com/itzg/mc-image-helper/releases) y la lista de exclusiones es `files/modrinth-exclude-include.json` de itzg/docker-minecraft-server. Necesita ~2.5 GiB de RAM libre (heap 2G).
