#!/usr/bin/env python3
"""Canonicalize packwiz export; route options.txt and shader settings to client-only overrides."""
import hashlib,json,pathlib,tomllib,zipfile
from common import ROOT
p=tomllib.loads((ROOT/'pack.toml').read_text());out=ROOT/'releases'/('vanilla-tech-'+p['version']+'.mrpack')
with zipfile.ZipFile(ROOT/'.cache/export.mrpack') as src:
 entries={n:src.read(n) for n in src.namelist() if not n.endswith('/')}
 assert not any(n.endswith('.jar') for n in entries),'Refusing to redistribute embedded jars'
 if 'overrides/options.txt' in entries:entries['client-overrides/options.txt']=entries.pop('overrides/options.txt')
 for n in [n for n in entries if n.startswith('overrides/shaderpacks/')]:entries['client-'+n]=entries.pop(n)
 manifest=json.loads(entries['modrinth.index.json']);manifest['files'].sort(key=lambda f:f['path']);entries['modrinth.index.json']=(json.dumps(manifest,sort_keys=True,indent=2)+'\n').encode()
 with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
  for n,b in sorted(entries.items()):
   i=zipfile.ZipInfo(n,(2026,10,9,0,0,0));i.compress_type=zipfile.ZIP_DEFLATED;i.external_attr=0o644<<16;z.writestr(i,b)
print(out)
(ROOT/'releases'/f'{out.name}.sha256').write_text(hashlib.sha256(out.read_bytes()).hexdigest()+'  '+out.name+'\n')
