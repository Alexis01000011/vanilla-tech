#!/usr/bin/env python3
"""Install or update a server from the release .mrpack. Never accepts the EULA.

Idempotent: records what it shipped in <dir>/.vanilla-tech-installed.json so that a later
run can tell pack changes apart from files rewritten by mods or edited by the admin.
"""
import argparse,hashlib,json,pathlib,shutil,subprocess,tomllib,zipfile
from common import ROOT,download
ap=argparse.ArgumentParser()
ap.add_argument('--directory',type=pathlib.Path,default=ROOT/'server')
ap.add_argument('--heap',default='5G',choices=['3G','5G','6G','8G','10G'])
ap.add_argument('--replace-configs',action='store_true',help='replace locally modified configs that the pack also changed (keeps a .bak copy)')
args=ap.parse_args()
dest=args.directory.resolve(); marker=dest/'.vanilla-tech-managed'; statefile=dest/'.vanilla-tech-installed.json'
if dest.exists() and any(dest.iterdir()) and not marker.exists():raise SystemExit('Refusing unmanaged nonempty directory: '+str(dest))
dest.mkdir(parents=True,exist_ok=True);marker.touch()
state=json.loads(statefile.read_text()) if statefile.exists() else {'mods':[],'overrides':{}}
jvm_existed=(dest/'user_jvm_args.txt').exists()
p=tomllib.loads((ROOT/'pack.toml').read_text());version=p['versions']['neoforge']
lock=json.loads((ROOT/'research/neoforge.json').read_text());assert version==lock['version']
pack=ROOT/'releases'/('vanilla-tech-'+p['version']+'.mrpack')
if not pack.exists():raise SystemExit('Run bash scripts/build.sh first')
jar=download(lock['url'],ROOT/'.cache/neoforge-installer.jar',{'sha256':lock['sha256']})
java=__import__('os').environ.get('JAVA','java')
if not (dest/f'libraries/net/neoforged/neoforge/{version}/unix_args.txt').exists():
    subprocess.run([java,'-Xmx768m','-jar',str(jar),'--installServer',str(dest)],cwd=dest,check=True)
sha=lambda b:hashlib.sha256(b).hexdigest()
with zipfile.ZipFile(pack) as z:
    manifest=json.loads(z.read('modrinth.index.json'));assert manifest['dependencies']['neoforge']==version
    files=[f for f in manifest['files'] if f['env']['server']!='unsupported']
    (dest/'mods').mkdir(exist_ok=True)
    expected={pathlib.Path(f['path']).name for f in files}
    extras={f.name for f in (dest/'mods').glob('*.jar')}-expected
    unknown=extras-set(state['mods'])
    if unknown:raise SystemExit('Unexpected jars not installed by this pack; review and remove manually: '+str(sorted(unknown)))
    for name in sorted(extras):print('Removing jar from previous release:',name);(dest/'mods'/name).unlink()
    for f in files:
        assert f['path'].startswith('mods/') and '..' not in pathlib.PurePosixPath(f['path']).parts
        cache=download(f['downloads'][0],ROOT/'.cache/artifacts'/pathlib.Path(f['path']).name,f['hashes'])
        shutil.copy2(cache,dest/f['path'])
    shipped={};conflicts=[]
    for n in sorted(z.namelist()):
        prefix=next((s for s in ['overrides/','server-overrides/'] if n.startswith(s)),None)
        if not prefix or n.endswith('/'):continue
        rel=pathlib.PurePosixPath(n[len(prefix):]);assert not rel.is_absolute() and '..' not in rel.parts
        out=dest/rel;data=z.read(n);new=sha(data);prev=state['overrides'].get(str(rel));shipped[str(rel)]=new
        if not out.exists() or out.read_bytes()==data:action='write'
        elif prev==new:action='keep'                       # pack unchanged; local copy was rewritten by a mod or edited
        elif prev is not None and sha(out.read_bytes())==prev:action='write'  # untouched since last install
        else:conflicts.append(out);action='replace' if args.replace_configs else 'conflict'
        if action=='replace':shutil.copy2(out,out.with_name(out.name+'.bak-'+p['version']));print('Backed up',out)
        if action in ('write','replace'):out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(data)
    if conflicts and not args.replace_configs:raise SystemExit('Configs modified locally and changed by the pack; review, then rerun with --replace-configs:\n  '+'\n  '.join(map(str,conflicts)))
for name in ['server.properties','user_jvm_args.txt']:
    out=dest/name
    if not out.exists() or (name=='user_jvm_args.txt' and not jvm_existed):
        data=(ROOT/'server-template'/name).read_text().replace('-Xmx5G','-Xmx'+args.heap)
        out.write_text(data)
statefile.write_text(json.dumps({'pack_version':p['version'],'mods':sorted(expected),'overrides':shipped},indent=2)+'\n')
print('Prepared',dest,'; EULA unchanged. Review properties, whitelist, then run bash run.sh nogui.')
