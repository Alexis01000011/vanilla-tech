#!/usr/bin/env python3
import json,pathlib,subprocess
from common import ROOT
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
jars=[next((ROOT/'server/libraries/org/apache/maven/maven-artifact').glob('*/*.jar')),next((ROOT/'server/libraries/org/apache/commons/commons-lang3').glob('*/*.jar'))]
cp=':'.join(map(str,jars))
import shutil
if shutil.which('javac'):
 subprocess.run(['javac','-cp',cp,'-d',str(ROOT/'.cache/classes'),str(ROOT/'scripts/CheckRanges.java')],check=True)
else:
 from common import download
 lock=json.loads((ROOT/'research/ecj.json').read_text());compiler=download(lock['url'],ROOT/'.tools/ecj.jar',{'sha256':lock['sha256']})
 rt=pathlib.Path('/usr/lib/jvm/java-8-openjdk/jre/lib/rt.jar')
 if not rt.exists():raise SystemExit('Full JDK 21 required for optional range checker (javac missing).')
 subprocess.run(['java','-jar',str(compiler),'-proc:none','-1.8','-bootclasspath',str(rt),'-cp',cp,'-d',str(ROOT/'.cache/classes'),str(ROOT/'scripts/CheckRanges.java')],check=True)
subprocess.run(['java','-cp',str(ROOT/'.cache/classes')+':'+cp,'CheckRanges',str(f)],check=True)
