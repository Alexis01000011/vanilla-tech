#!/usr/bin/env python3
"""Validate packwiz integrity, export parity and real nested JAR requirements."""
import hashlib,io,json,pathlib,re,sys,tomllib,zipfile
from common import ROOT
pack=tomllib.loads((ROOT/'pack.toml').read_text())
idx=(ROOT/pack['index']['file']).read_bytes();assert hashlib.new(pack['index']['hash-format'],idx).hexdigest()==pack['index']['hash']
entries=tomllib.loads(idx.decode())['files'];metas=[]
for e in entries:
 b=(ROOT/e['file']).read_bytes();assert hashlib.sha256(b).hexdigest()==e['hash'],e['file']
 if e.get('metafile'):metas.append((e['file'],tomllib.loads(b.decode())))
assert pack['versions']=={'minecraft':'1.21.1','neoforge':'21.1.257'}
mr=pathlib.Path(sys.argv[1]) if len(sys.argv)>1 else ROOT/'releases'/('vanilla-tech-'+pack['version']+'.mrpack')
with zipfile.ZipFile(mr) as z:
 assert not any(n.endswith('.jar') for n in z.namelist()),'Embedded third-party jar'
 manifest=json.loads(z.read('modrinth.index.json'))
 assert manifest['dependencies']==pack['versions']
 exported={f['path']:f for f in manifest['files']}
 assert len(exported)==len(metas)
 for path,m in metas:
  assert m.get('pin') is True,path
  e=exported[str(pathlib.PurePosixPath(path).parent/m['filename'])];assert e['downloads']==[m['download']['url']]
  for side in ['client','server']:
   assert e['env'][side]==('unsupported' if m['side'] not in ['both',side] else 'required'),(path,side)
  assert not any(x in m['filename'].lower() for x in ['terralith','tectonic','structory','lootr','advancedae','aeinfinity'])
records=[]
def inspect(data,where,side):
 z=zipfile.ZipFile(io.BytesIO(data)); names=z.namelist()
 n=next((n for n in ['META-INF/neoforge.mods.toml','META-INF/mods.toml'] if n in names),None)
 if n:
  raw=z.read(n).decode();d=tomllib.loads(raw)
  # FML expands ${file.jarVersion} from the jar manifest's Implementation-Version.
  mf=z.read('META-INF/MANIFEST.MF').decode('utf-8','replace') if 'META-INF/MANIFEST.MF' in names else ''
  jv=next((l.split(':',1)[1].strip() for l in mf.splitlines() if l.startswith('Implementation-Version:')),None)
  for m in d.get('mods',[]):records.append({'id':m['modId'],'version':jv if m.get('version')=='${file.jarVersion}' and jv else m.get('version','?'),'jar':where,'side':side,'loader':d.get('modLoader'),'dependencies':d.get('dependencies',{}).get(m['modId'],[])})
 for n in names:
  if n.startswith('META-INF/jarjar/') and n.endswith('.jar'):inspect(z.read(n),where+'!/'+n,side)
for path,m in metas:
 jar=ROOT/'.cache/artifacts'/m['filename']
 if not jar.exists():raise SystemExit('Run fetch-artifacts.py before JAR validation: '+str(jar))
 data=jar.read_bytes();assert hashlib.new(m['download']['hash-format'],data).hexdigest()==m['download']['hash']
 inspect(data,m['filename'],m['side'])
 missing=[]
for side in ['client','server']:
 ids={r['id'] for r in records if r['side'] in ['both',side]}|{'minecraft','neoforge'}
 for r in records:
  if r['side'] not in ['both',side]:continue
  for d in r['dependencies']:
   if d.get('side','BOTH').lower() not in ['both',side]:continue
   if d.get('type','required').lower()=='required' and d['modId'] not in ids:missing.append((side,r['id'],d))
assert not missing,missing
(ROOT/'docs/jar-inventory.json').write_text(json.dumps(records,indent=2)+'\n')
print(f'PASS: {len(metas)} pinned artifacts, hashes, export parity, side split and required nested mod IDs.')
print('Version intervals are checked separately using Maven VersionRange and by NeoForge launch.')
