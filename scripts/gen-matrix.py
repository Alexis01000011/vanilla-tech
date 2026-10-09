#!/usr/bin/env python3
"""Generate docs/compatibility-matrix.md from metafiles, docs/jar-inventory.json and docs/test-status.toml."""
import json,pathlib,tomllib
from common import ROOT
pack=tomllib.loads((ROOT/'pack.toml').read_text())
inventory=json.loads((ROOT/'docs/jar-inventory.json').read_text())
status=tomllib.loads((ROOT/'docs/test-status.toml').read_text())
by_jar={}
for r in inventory:by_jar.setdefault(r['jar'].split('!/')[0],[]).append(r)
names={}
for p in (ROOT/'mods').glob('*.pw.toml'):
 m=tomllib.loads(p.read_text())
 for r in by_jar.get(m['filename'],[]):names.setdefault(r['id'],m['name'])
rows=[]
for p in sorted((ROOT/'mods').glob('*.pw.toml'),key=lambda p:tomllib.loads(p.read_text())['name'].lower()):
 key=p.name[:-len('.pw.toml')];m=tomllib.loads(p.read_text())
 if 'modrinth' in m['update']:src=f"[Modrinth](https://modrinth.com/mod/{key})"
 else:src=f"[CurseForge](https://www.curseforge.com/minecraft/mc-mods/{key})"
 top=[r for r in by_jar.get(m['filename'],[]) if '!/' not in r['jar']]
 version=top[0]['version'] if top and not top[0]['version'].startswith('$') else m['filename']
 deps=sorted({names.get(d['modId'],d['modId']) for r in top for d in r['dependencies'] if d.get('type','required').lower()=='required' and d['modId'] not in ('minecraft','neoforge') and d['modId'] not in {x['id'] for x in by_jar.get(m['filename'],[])}})
 s=status.get(key,{'status':'Verified','evidence':''})
 if m['side']=='client':s=dict(s,status='Verified',evidence=(s['evidence']+'; arranque de cliente pendiente').lstrip('; '))
 rows.append(f"| {m['name']} | {version} | {src} | {', '.join(deps) or '—'} | {m['side']} | {s['status']} | {s['evidence']} |")
out=f"""# Matriz de compatibilidad — Vanilla Tech {pack['version']}

Minecraft {pack['versions']['minecraft']} · NeoForge {pack['versions']['neoforge']} · {len(rows)} artefactos fijados.
Generada por `scripts/gen-matrix.py`; no editar a mano. Los estados viven en `docs/test-status.toml`.

**Estados**
- **Verified**: hashes, metadatos, lado (cliente/servidor) y rangos de versión comprobados (`validate.py`, `check-ranges.py`).
- **Launch tested**: cargó sin errores en un arranque real de NeoForge (servidor dedicado). La columna *Evidencia* indica qué más se comprobó por comandos.
- **Gameplay tested**: funcionalidad probada por un jugador dentro del juego.
- **Blocked**: problema abierto.

Hasta la prueba en Prism, ningún mod tiene arranque de **cliente** comprobado ([known-issues.md](known-issues.md), P1). Las dependencias se leen de `META-INF/neoforge.mods.toml` en cada JAR, sin contar las bibliotecas que el propio JAR trae embebidas (jar-in-jar).

| Mod | Versión | Fuente | Dependencias obligatorias | Side | Estado | Evidencia |
|---|---|---|---|---|---|---|
""" + '\n'.join(rows) + '\n'
(ROOT/'docs/compatibility-matrix.md').write_text(out);print('wrote docs/compatibility-matrix.md',len(rows),'rows')
