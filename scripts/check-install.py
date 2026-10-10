#!/usr/bin/env python3
"""Install a published pack.toml with the real packwiz-installer and check the result.

  check-install.py --pack URL/pack.toml --side client|server --dir DIR [--expect release.json]

Runs packwiz-installer-bootstrap headless (pinned jars from research/packwiz-installer.json),
exactly like Prism's pre-launch command does, then checks that DIR holds every mod of that side
with the right sha512 and none of the other side's. Exit status 1 on any mismatch.
"""
import argparse,hashlib,json,pathlib,subprocess,sys,time
from common import ROOT,download

def tools():
 lock=json.loads((ROOT/'research/packwiz-installer.json').read_text())
 return [download(lock[k]['url'],ROOT/'.cache/tools'/pathlib.Path(lock[k]['url']).name,{'sha256':lock[k]['sha256']}) for k in ('bootstrap','installer')]

def install(pack,side,game_dir,java='java'):
 """Same invocation as the Prism pre-launch command, minus the GUI and self-update."""
 boot,inst=tools();game_dir=pathlib.Path(game_dir);game_dir.mkdir(parents=True,exist_ok=True);t=time.monotonic()
 p=subprocess.run([java,'-jar',str(boot),'-g','--bootstrap-no-update','--bootstrap-main-jar',str(inst),'-s',side,pack],
  cwd=game_dir,capture_output=True,text=True)
 return p.returncode,p.stdout+p.stderr,round(time.monotonic()-t,1)

def check(game_dir,release,side):
 game_dir=pathlib.Path(game_dir);other='client' if side=='server' else 'server';bad=[]
 for k,m in release[side]['mods'].items():
  f=game_dir/m['file']
  if not f.exists():bad.append(f'missing {m["file"]}')
  elif hashlib.sha512(f.read_bytes()).hexdigest()!=m['sha512']:bad.append(f'hash {m["file"]}')
 for k,m in release[other]['mods'].items():
  if k not in release[side]['mods'] and (game_dir/m['file']).exists():bad.append(f'wrong side {m["file"]}')
 if not (game_dir/'packwiz.json').exists():bad.append('packwiz.json missing')
 return bad

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--pack',required=True);ap.add_argument('--side',choices=['client','server'],required=True)
 ap.add_argument('--dir',type=pathlib.Path,required=True);ap.add_argument('--expect',type=pathlib.Path)
 a=ap.parse_args();rc,out,secs=install(a.pack,a.side,a.dir)
 print(out[-3000:]);print(f'packwiz-installer exit={rc} in {secs}s')
 if rc:sys.exit(1)
 if a.expect:
  bad=check(a.dir,json.loads(a.expect.read_text()),a.side)
  if bad:print('FAIL:',*bad,sep='\n  ');sys.exit(1)
  print(f'PASS: {a.side} install matches {a.expect.name}')
