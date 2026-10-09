#!/usr/bin/env python3
"""Check every declared dependency version range with Maven's own VersionRange (as FML does)."""
import json,pathlib,shutil,subprocess
from common import ROOT,download
rs=json.loads((ROOT/'docs/jar-inventory.json').read_text());out=[]
for side in ['client','server']:
 rows=[r for r in rs if r['side'] in ['both',side]];ids={r['id']:r['version'] for r in rows};ids.update(minecraft='1.21.1',neoforge='21.1.257')
 # Kotlin language provider has an unexpanded manifest placeholder in some jars.
 ids['kotlinforforge']='5.12.0'
 # JarJar chooses the compatible API shipped by ae2wtlib over ExtendedAE's older bundled copy.
 ids['ae2wtlib_api']='19.5.1'
 for r in rows:
  for d in r['dependencies']:
   if d.get('side','BOTH').lower() not in ['both',side] or d['modId'] not in ids:continue
   typ=d.get('type','required').lower()
   if typ not in ['required','optional','incompatible']:continue
   v=ids[d['modId']];rng=d.get('versionRange','*')
   if rng=='*':continue
   if v.startswith('${'):raise RuntimeError((r,d,v))
   out.append('\t'.join([side+':'+r['id']+'->'+d['modId'],v,rng,typ]))
f=ROOT/'docs/version-ranges.tsv';f.write_text('\n'.join(out)+'\n')
# Same library versions NeoForge 21.1.257 ships in its server libraries.
libs={'maven-artifact-3.8.5.jar':('https://repo.maven.apache.org/maven2/org/apache/maven/maven-artifact/3.8.5/maven-artifact-3.8.5.jar','91172bc294d6eab02fc9f45f4ea01fd0e418962d128cf489abea7b6957d988ee'),
      'commons-lang3-3.8.1.jar':('https://repo.maven.apache.org/maven2/org/apache/commons/commons-lang3/3.8.1/commons-lang3-3.8.1.jar','dac807f65b07698ff39b1b07bfef3d87ae3fd46d91bbf8a2bc02b2a831616f68')}
cp=':'.join(str(download(u,ROOT/'.cache/libs'/n,{'sha256':h})) for n,(u,h) in libs.items())
classes=ROOT/'.cache/classes'
if shutil.which('javac'):
 subprocess.run(['javac','-cp',cp,'-d',str(classes),str(ROOT/'scripts/CheckRanges.java')],check=True)
else:
 # A JRE-only Java 21 has no compiler; ECJ can still target Java 8 if its rt.jar is present.
 rt=pathlib.Path('/usr/lib/jvm/java-8-openjdk/jre/lib/rt.jar')
 if not rt.exists():raise SystemExit('check-ranges needs a full JDK 21 (javac), e.g. `pacman -S jdk21-openjdk` or Temurin/Corretto 21 JDK.')
 lock=json.loads((ROOT/'research/ecj.json').read_text());compiler=download(lock['url'],ROOT/'.tools/ecj.jar',{'sha256':lock['sha256']})
 subprocess.run(['java','-jar',str(compiler),'-proc:none','-1.8','-bootclasspath',str(rt),'-cp',cp,'-d',str(classes),str(ROOT/'scripts/CheckRanges.java')],check=True)
subprocess.run(['java','-cp',str(classes)+':'+cp,'CheckRanges',str(f)],check=True)
