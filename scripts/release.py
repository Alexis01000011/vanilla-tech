#!/usr/bin/env python3
"""Release metadata, impact classification and the static update site (stdlib only).

  release.py meta    --root DIR --mrpack F [--commit SHA] [--out release.json]
  release.py impact  BASE.json NEW.json [--github-output FILE] [--summary FILE]
  release.py publish --site SITE --root DIR --mrpack F [--commit SHA]
  release.py alias   --site SITE --name stable|staging --version V
  release.py server  --site SITE --version V            (record what the EC2 server runs)
  release.py verify  --site SITE
  release.py render  --site SITE

Site layout (served over HTTPS, e.g. GitHub Pages):
  releases/<v>/        immutable packwiz tree + vanilla-tech-<v>.mrpack + release.json
  stable/, staging/    full copies of one release tree (packwiz-installer cannot follow ".."
                       out of the folder that holds pack.toml, so an alias cannot be a pointer)
  server/release.json  release currently deployed on the EC2 server
Every published tree is hash-chained (pack.toml -> index.toml -> files); `verify` checks it.
"""
import argparse,hashlib,html,json,pathlib,re,shutil,sys,tomllib,zipfile
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent))
import preserve

VERSION_RE=re.compile(r'^[0-9]+\.[0-9]+\.[0-9]+(-(alpha|beta|rc)\.[0-9]+)?$')
ALIASES=('stable','staging')
sha256=lambda b:hashlib.sha256(b).hexdigest()

def canon(o):return json.dumps(o,sort_keys=True,separators=(',',':')).encode()

def version_key(v):
 m=VERSION_RE.match(v);assert m,v
 core,_,pre=v.partition('-');rank={'alpha':0,'beta':1,'rc':2}
 return tuple(map(int,core.split('.')))+((rank[pre.split('.')[0]],int(pre.split('.')[1])) if pre else (3,0))

# ---------------------------------------------------------------- metadata
def metafile_keys(root):
 """mrpack path -> packwiz metafile key (e.g. 'mods/create'), so updates are told apart from adds."""
 keys={}
 for p in pathlib.Path(root).glob('*/*.pw.toml'):
  m=tomllib.loads(p.read_text());keys[f'{p.parent.name}/{m["filename"]}']=f'{p.parent.name}/{p.name[:-len(".pw.toml")]}'
 return keys

def meta(root,mrpack,commit=None):
 root=pathlib.Path(root);mrpack=pathlib.Path(mrpack);data=mrpack.read_bytes()
 pack=tomllib.loads((root/'pack.toml').read_text());keys=metafile_keys(root)
 with zipfile.ZipFile(mrpack) as z:
  idx=json.loads(z.read('modrinth.index.json'))
  ov={n:sha256(z.read(n)) for n in z.namelist() if not n.endswith('/') and n.split('/')[0] in ('overrides','server-overrides','client-overrides')}
 assert idx['versionId']==pack['version'],(idx['versionId'],pack['version'])
 assert idx['dependencies']==pack['versions'],(idx['dependencies'],pack['versions'])
 sides={}
 for side,other in (('server','client'),('client','server')):
  mods={keys.get(f['path'],f['path']):{'file':f['path'],'sha512':f['hashes']['sha512']} for f in idx['files'] if f['env'][side]!='unsupported'}
  overrides={}
  for prefix in ('overrides/',side+'-overrides/'):  # later prefix wins, as installers apply it last
   overrides.update({n[len(prefix):]:h for n,h in sorted(ov.items()) if n.startswith(prefix)})
  fp={'dependencies':idx['dependencies'],'mods':{k:v['sha512'] for k,v in mods.items()},'overrides':overrides}
  sides[side]={'fingerprint':sha256(canon(fp)),'mods':dict(sorted(mods.items())),'overrides':overrides}
 return {'schema':1,'name':pack['name'],'version':pack['version'],'commit':commit,
  'minecraft':pack['versions']['minecraft'],'neoforge':pack['versions']['neoforge'],
  'mrpack':{'file':mrpack.name,'sha256':sha256(data),'sha512':hashlib.sha512(data).hexdigest(),'size':len(data)},
  'server':sides['server'],'client':sides['client'],
  'counts':{'server':len(sides['server']['mods']),'client':len(sides['client']['mods'])}}

# ---------------------------------------------------------------- impact
def diff_side(a,b):
 am,bm=a['mods'],b['mods']
 return {'added':sorted(set(bm)-set(am)),'removed':sorted(set(am)-set(bm)),
  'updated':sorted(k for k in set(am)&set(bm) if am[k]['sha512']!=bm[k]['sha512']),
  'overrides':sorted(k for k in set(a['overrides'])|set(b['overrides']) if a['overrides'].get(k)!=b['overrides'].get(k))}

def impact(base,new):
 s,c=diff_side(base['server'],new['server']),diff_side(base['client'],new['client'])
 loader=(base['minecraft'],base['neoforge'])!=(new['minecraft'],new['neoforge'])
 server=base['server']['fingerprint']!=new['server']['fingerprint']
 client=base['client']['fingerprint']!=new['client']['fingerprint']
 reasons=[]
 if loader:reasons.append(f"loader {base['minecraft']}/{base['neoforge']} -> {new['minecraft']}/{new['neoforge']}")
 if s['added'] or s['removed']:reasons.append('server mods added/removed (new registries, blocks or dimensions are possible)')
 if s['updated']:reasons.append('server mods updated')
 if s['overrides']:reasons.append('server configs changed')
 severity=('high' if loader or s['added'] or s['removed'] else 'medium' if s['updated'] else 'low' if server
  else 'client' if client else 'none')
 return {'base':base['version'],'new':new['version'],'severity':severity,'server_deploy':server,'client_update':client,
  'loader_change':loader,'downgrade':version_key(new['version'])<version_key(base['version']),
  'reasons':reasons or (['client-only changes'] if client else ['identical content']),'server':s,'client':c}

def impact_markdown(r):
 out=[f"### Impacto {r['base']} → {r['new']}: **{r['severity']}**",'',
  f"- Despliegue al servidor EC2: **{'sí' if r['server_deploy'] else 'no'}**",
  f"- Actualización de clientes: **{'sí' if r['client_update'] else 'no'}**"]
 if r['downgrade']:out.append('- ⚠️ Versión anterior a la base (downgrade)')
 out+=[f'- {x}' for x in r['reasons']]
 for side in ('server','client'):
  for k in ('added','removed','updated','overrides'):
   if r[side][k]:out.append(f"- {side} {k}: "+', '.join(f'`{x}`' for x in r[side][k]))
 return '\n'.join(out)+'\n'

# ---------------------------------------------------------------- site
def tree_files(root):
 """Every path a packwiz tree serves: pack.toml, index.toml and each indexed file."""
 root=pathlib.Path(root);pack=tomllib.loads((root/'pack.toml').read_text())
 idx=tomllib.loads((root/pack['index']['file']).read_text())
 return ['pack.toml',pack['index']['file']]+[f['file'] for f in idx['files']]

def check_tree(root):
 root=pathlib.Path(root);pack=tomllib.loads((root/'pack.toml').read_text());idxb=(root/pack['index']['file']).read_bytes()
 assert pack['index']['hash-format']=='sha256' and sha256(idxb)==pack['index']['hash'],f'{root}: index hash'
 idx=tomllib.loads(idxb.decode())
 for f in idx['files']:
  p=pathlib.PurePosixPath(f['file']);assert not p.is_absolute() and '..' not in p.parts,f['file']
  assert sha256((root/f['file']).read_bytes())==f['hash'],f'{root}: {f["file"]}'
  if f.get('metafile'):tomllib.loads((root/f['file']).read_text())
 for p in root.rglob('*'):
  if p.is_file() and p.relative_to(root).as_posix() not in set(tree_files(root))|{'release.json'} and not p.name.endswith(('.mrpack','.mrpack.sha256')):
   raise AssertionError(f'{root}: unexpected file {p.relative_to(root)}')
 return pack

def same_tree(a,b):
 fa=sorted(p.relative_to(a).as_posix() for p in pathlib.Path(a).rglob('*') if p.is_file())
 fb=sorted(p.relative_to(b).as_posix() for p in pathlib.Path(b).rglob('*') if p.is_file())
 return fa==fb and all((pathlib.Path(a)/f).read_bytes()==(pathlib.Path(b)/f).read_bytes() for f in fa)

def copy_tree(src,dst,files):
 for f in files:
  (dst/f).parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src/f,dst/f)

def publish(site,root,mrpack,commit=None):
 site,root,mrpack=pathlib.Path(site),pathlib.Path(root),pathlib.Path(mrpack)
 rel=meta(root,mrpack,commit);v=rel['version'];assert VERSION_RE.match(v),v
 assert mrpack.name==f'vanilla-tech-{v}.mrpack',mrpack.name
 stage=site/'.staging'/v
 if stage.exists():shutil.rmtree(stage)
 copy_tree(root,stage,tree_files(root))
 preserve.apply(stage,repack=True)      # also safe for tags built before preserve existed
 shutil.copyfile(mrpack,stage/mrpack.name)
 (stage/(mrpack.name+'.sha256')).write_text(f"{rel['mrpack']['sha256']}  {mrpack.name}\n")
 rel['packwiz']={'pack_sha256':sha256((stage/'pack.toml').read_bytes()),'index_sha256':tomllib.loads((stage/'pack.toml').read_text())['index']['hash']}
 (stage/'release.json').write_text(json.dumps(rel,indent=1,sort_keys=True)+'\n')
 check_tree(stage);dest=site/'releases'/v
 if dest.exists():
  same=same_tree(stage,dest);shutil.rmtree(site/'.staging')
  if not same:raise SystemExit(f'Refusing to overwrite immutable release {v}: published content differs')
  print('already published:',v);return rel
 dest.parent.mkdir(parents=True,exist_ok=True);stage.rename(dest);shutil.rmtree(site/'.staging')
 (site/'.nojekyll').touch();print('published:',dest);return rel

def alias(site,name,version):
 assert name in ALIASES,name;site=pathlib.Path(site);src=site/'releases'/version
 check_tree(src);rel=json.loads((src/'release.json').read_text())
 new=site/f'.{name}.new'
 if new.exists():shutil.rmtree(new)
 copy_tree(src,new,tree_files(src))
 (new/'release.json').write_text(json.dumps({**{k:rel[k] for k in ('name','version','commit','minecraft','neoforge','mrpack','packwiz','counts')},
  'server':{'fingerprint':rel['server']['fingerprint']},'client':{'fingerprint':rel['client']['fingerprint']},
  'mrpack_url':f'../releases/{version}/{rel["mrpack"]["file"]}'},indent=1,sort_keys=True)+'\n')
 check_tree(new);dst=site/name
 if dst.exists():shutil.rmtree(dst)
 new.rename(dst);print(f'{name} -> {version}')

def server(site,version):
 site=pathlib.Path(site);rel=json.loads((site/'releases'/version/'release.json').read_text())
 (site/'server').mkdir(exist_ok=True)
 (site/'server/release.json').write_text(json.dumps({'version':version,'server':{'fingerprint':rel['server']['fingerprint']},
  'mrpack':{k:rel['mrpack'][k] for k in ('file','sha256')}},indent=1,sort_keys=True)+'\n');print('server ->',version)

def verify(site):
 site=pathlib.Path(site);n=0
 for d in sorted((site/'releases').iterdir()) if (site/'releases').exists() else []:
  pack=check_tree(d);rel=json.loads((d/'release.json').read_text())
  assert rel['version']==d.name==pack['version'],d
  assert sha256((d/rel['mrpack']['file']).read_bytes())==rel['mrpack']['sha256'],d
  assert sha256((d/'pack.toml').read_bytes())==rel['packwiz']['pack_sha256'],d;n+=1
 for a in ALIASES+('server',):
  if not (site/a).exists():continue
  v=json.loads((site/a/'release.json').read_text())['version'];src=site/'releases'/v;assert src.exists(),(a,v)
  if a!='server':
   check_tree(site/a)
   assert all((site/a/f).read_bytes()==(src/f).read_bytes() for f in tree_files(src)),f'{a} differs from releases/{v}'
  print(f'{a}: {v}')
 print(f'OK: {n} immutable releases verified')

def render(site):
 site=pathlib.Path(site);rels=[]
 for d in (site/'releases').iterdir():
  r=json.loads((d/'release.json').read_text());rels.append({k:r[k] for k in ('version','commit','minecraft','neoforge','counts')}|{'mrpack':f"releases/{r['version']}/{r['mrpack']['file']}",'sha256':r['mrpack']['sha256']})
 rels.sort(key=lambda r:version_key(r['version']),reverse=True)
 aliases={a:json.loads((site/a/'release.json').read_text())['version'] for a in ALIASES+('server',) if (site/a/'release.json').exists()}
 (site/'releases.json').write_text(json.dumps({'aliases':aliases,'releases':rels},indent=1)+'\n')
 rows=''.join(f"<tr><td>{html.escape(r['version'])}</td><td>{' '.join(a for a,v in aliases.items() if v==r['version'])}</td>"
  f"<td><a href=\"{html.escape(r['mrpack'])}\">.mrpack</a></td><td><a href=\"releases/{html.escape(r['version'])}/pack.toml\">pack.toml</a></td>"
  f"<td><code>{r['sha256'][:12]}…</code></td></tr>" for r in rels)
 (site/'index.html').write_text(f"""<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Vanilla Tech Releases</title><style>body{{font:15px/1.5 system-ui,sans-serif;max-width:52rem;margin:2rem auto;padding:0 16px;color:#1b1b1b;background:#fafafa}}
table{{border-collapse:collapse;width:100%}}td,th{{text-align:left;padding:.3rem .5rem;border-bottom:1px solid #ddd}}code{{font-size:13px}}
@media (prefers-color-scheme:dark){{body{{color:#e8e8e8;background:#161616}}a{{color:#8ab4f8}}td,th{{border-color:#333}}}}</style>
<h1>Vanilla Tech</h1><p>Minecraft 1.21.1 · NeoForge. Auto-update de Prism: <code>stable/pack.toml</code> (pruebas: <code>staging/pack.toml</code>).</p>
<table><tr><th>Versión</th><th>Alias</th><th>Instalador</th><th>packwiz</th><th>sha256</th></tr>{rows}</table></html>
""")

def main():
 ap=argparse.ArgumentParser();sp=ap.add_subparsers(dest='cmd',required=True)
 m=sp.add_parser('meta');m.add_argument('--root',default='.');m.add_argument('--mrpack',required=True);m.add_argument('--commit');m.add_argument('--out')
 i=sp.add_parser('impact');i.add_argument('base');i.add_argument('new');i.add_argument('--github-output');i.add_argument('--summary')
 p=sp.add_parser('publish');p.add_argument('--site',required=True);p.add_argument('--root',default='.');p.add_argument('--mrpack',required=True);p.add_argument('--commit')
 a=sp.add_parser('alias');a.add_argument('--site',required=True);a.add_argument('--name',required=True,choices=ALIASES);a.add_argument('--version',required=True)
 s=sp.add_parser('server');s.add_argument('--site',required=True);s.add_argument('--version',required=True)
 for c in ('verify','render'):sp.add_parser(c).add_argument('--site',required=True)
 a=ap.parse_args()
 if getattr(a,'version',None):assert VERSION_RE.match(a.version),f'invalid version {a.version!r}'
 if a.cmd=='meta':
  out=json.dumps(meta(a.root,a.mrpack,a.commit),indent=1,sort_keys=True)+'\n'
  pathlib.Path(a.out).write_text(out) if a.out else print(out,end='')
 elif a.cmd=='impact':
  r=impact(json.loads(pathlib.Path(a.base).read_text()),json.loads(pathlib.Path(a.new).read_text()))
  print(json.dumps(r,indent=1))
  if a.summary:open(a.summary,'a').write(impact_markdown(r))
  if a.github_output:
   with open(a.github_output,'a') as f:
    for k in ('severity','server_deploy','client_update','loader_change','downgrade'):f.write(f'{k}={str(r[k]).lower()}\n')
 elif a.cmd=='publish':publish(a.site,a.root,a.mrpack,a.commit);render(a.site)
 elif a.cmd=='alias':alias(a.site,a.name,a.version);render(a.site)
 elif a.cmd=='server':server(a.site,a.version);render(a.site)
 elif a.cmd=='verify':verify(a.site)
 elif a.cmd=='render':render(a.site)

if __name__=='__main__':main()
