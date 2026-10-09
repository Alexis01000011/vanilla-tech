#!/usr/bin/env python3
"""Install into a fresh or project-owned directory. Never accepts the EULA."""
import argparse,hashlib,json,pathlib,shutil,subprocess,tomllib,zipfile
from common import ROOT,download
ap=argparse.ArgumentParser();ap.add_argument('--directory',type=pathlib.Path,default=ROOT/'server');ap.add_argument('--heap',default='5G',choices=['3G','5G','8G']);args=ap.parse_args()
dest=args.directory.resolve(); marker=dest/'.vanilla-tech-managed'
if dest.exists() and any(dest.iterdir()) and not marker.exists():raise SystemExit('Refusing unmanaged nonempty directory: '+str(dest))
dest.mkdir(parents=True,exist_ok=True);marker.touch()
jvm_existed=(dest/'user_jvm_args.txt').exists()
p=tomllib.loads((ROOT/'pack.toml').read_text());version=p['versions']['neoforge']
lock=json.loads((ROOT/'research/neoforge.json').read_text());assert version==lock['version']
pack=ROOT/'releases'/('vanilla-tech-'+p['version']+'.mrpack')
if not pack.exists():raise SystemExit('Run bash scripts/build.sh first')
jar=download(lock['url'],ROOT/'.cache/neoforge-installer.jar',{'sha256':lock['sha256']})
java=__import__('os').environ.get('JAVA','java')
if not (dest/f'libraries/net/neoforged/neoforge/{version}/unix_args.txt').exists():
    subprocess.run([java,'-Xmx768m','-jar',str(jar),'--installServer',str(dest)],cwd=dest,check=True)
with zipfile.ZipFile(pack) as z:
    manifest=json.loads(z.read('modrinth.index.json'));assert manifest['dependencies']['neoforge']==version
    files=[f for f in manifest['files'] if f['env']['server']!='unsupported']
    (dest/'mods').mkdir(exist_ok=True)
    expected={pathlib.Path(f['path']).name for f in files}
    extras={f.name for f in (dest/'mods').glob('*.jar')}-expected
    if extras:raise SystemExit('Unexpected/old jars; review and remove manually: '+str(extras))
    for f in files:
        assert f['path'].startswith('mods/') and '..' not in pathlib.PurePosixPath(f['path']).parts
        cache=download(f['downloads'][0],ROOT/'.cache/artifacts'/pathlib.Path(f['path']).name,f['hashes'])
        shutil.copy2(cache,dest/f['path'])
    for n in z.namelist():
        prefix=next((s for s in ['overrides/','server-overrides/'] if n.startswith(s)),None)
        if not prefix or n.endswith('/'):continue
        rel=pathlib.PurePosixPath(n[len(prefix):]);assert not rel.is_absolute() and '..' not in rel.parts
        out=dest/rel;data=z.read(n)
        if out.exists() and out.read_bytes()!=data:raise SystemExit('Config differs; review before replacing: '+str(out))
        out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(data)
for name in ['server.properties','user_jvm_args.txt']:
    out=dest/name
    if not out.exists() or (name=='user_jvm_args.txt' and not jvm_existed):
        data=(ROOT/'server-template'/name).read_text().replace('-Xmx5G','-Xmx'+args.heap)
        out.write_text(data)
print('Prepared',dest,'; EULA unchanged. Review properties, whitelist, then run bash run.sh nogui.')
