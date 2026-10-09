#!/usr/bin/env python3
import pathlib,zipfile,json,tomllib
from common import ROOT
rows=[];critical=[]
for p in sorted((ROOT/'mods').glob('*.pw.toml')):
 m=tomllib.loads(p.read_text())
 if m['side']=='client':continue
 z=zipfile.ZipFile(ROOT/'.cache/artifacts'/m['filename'])
 paths=[n for n in z.namelist() if n.endswith('.json') and n.startswith('data/') and any(k in n for k in ['/worldgen/structure/','/worldgen/structure_set/','/worldgen/biome/','/worldgen/noise_settings/','/dimension/'])]
 overrides=[n for n in paths if n.startswith('data/minecraft/')]
 critical.extend((m['name'],n) for n in overrides)
 rows.append({'mod':m['name'],'worldgen_paths':paths,'vanilla_overrides':overrides})
(ROOT/'docs/worldgen-audit.json').write_text(json.dumps(rows,indent=2)+'\n')
print('Vanilla worldgen JSON overrides:',critical)
print('This does not prove absence of code-level changes or farm functionality.')
