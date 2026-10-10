#!/usr/bin/env python3
"""Local end-to-end test of Prism auto-update on a simulated player instance.

Publishes three releases to a throwaway site served on 127.0.0.1, imports the base .mrpack into a
fake Prism instance (as Prism does), customises it like a player would, and then moves `stable`
through an update, a client-only release, a broken publication and a client rollback, running the
real packwiz-installer each time. No network besides the mod CDNs for newly added mods.

  autoupdate-scenario.py --work DIR --base-tag v0.4.0 --base-mrpack A.mrpack \
                         --next-tag v0.5.0-alpha.1 --next-mrpack B.mrpack
"""
import argparse,functools,hashlib,http.server,importlib.util,io,json,os,pathlib,shutil,subprocess,sys,tarfile,threading,zipfile
HERE=pathlib.Path(__file__).resolve().parent;SCRIPTS=HERE.parent;ROOT=SCRIPTS.parent
sys.path.insert(0,str(SCRIPTS))
from common import download
import release
spec=importlib.util.spec_from_file_location('check_install',SCRIPTS/'check-install.py');ci=importlib.util.module_from_spec(spec);spec.loader.exec_module(ci)
results=[]

def step(name,ok,detail=''):
 results.append({'step':name,'ok':bool(ok),'detail':detail});print(('PASS ' if ok else 'FAIL ')+name+(f' — {detail}' if detail else ''),flush=True)

def tag_tree(tag,dest):
 dest.mkdir(parents=True);data=subprocess.run(['git','-C',str(ROOT),'archive',tag],capture_output=True,check=True).stdout
 tarfile.open(fileobj=io.BytesIO(data)).extractall(dest,filter='data')

def build_client_only(src,dest):
 """Release C = B minus Dynamic FPS (client-only) + a new default in options.txt."""
 shutil.copytree(src,dest);(dest/'mods/dynamic-fps.pw.toml').unlink()
 (dest/'options.txt').write_text((dest/'options.txt').read_text()+'scenarioDefault:true\n')
 pt=dest/'pack.toml';pt.write_text(pt.read_text().replace('version = "0.5.0-alpha.1"','version = "0.5.1-alpha.1"'))
 (dest/'.tools').mkdir();shutil.copy2(ROOT/'.tools/packwiz',dest/'.tools/packwiz');(dest/'.cache').mkdir()
 pw=lambda *a:subprocess.run([str(dest/'.tools/packwiz'),'--cache',str(ROOT/'.cache/packwiz'),*a],cwd=dest,check=True,capture_output=True)
 pw('refresh');subprocess.run([sys.executable,str(SCRIPTS/'preserve.py'),str(dest)],check=True);pw('refresh')
 pw('modrinth','export','--restrictDomains=false','-o','.cache/export.mrpack')
 (dest/'releases').mkdir();subprocess.run([sys.executable,'scripts/package.py'],cwd=dest,check=True,capture_output=True)
 return dest/'releases/vanilla-tech-0.5.1-alpha.1.mrpack'

def prism_import(mrpack,inst):
 """What Prism does with a .mrpack: download env.client files, then overrides/ and client-overrides/."""
 game=inst/'minecraft';game.mkdir(parents=True)
 with zipfile.ZipFile(mrpack) as z:
  idx=json.loads(z.read('modrinth.index.json'))
  for f in idx['files']:
   if f['env']['client']=='unsupported':continue
   src=download(f['downloads'][0],ROOT/'.cache/artifacts'/pathlib.Path(f['path']).name,f['hashes'])
   (game/f['path']).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,game/f['path'])
  for prefix in ('overrides/','client-overrides/'):
   for n in z.namelist():
    if n.startswith(prefix) and not n.endswith('/'):
     out=game/n[len(prefix):];out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(z.read(n))
 deps=idx['dependencies']
 (inst/'mmc-pack.json').write_text(json.dumps({'formatVersion':1,'components':[
  {'uid':'net.minecraft','version':deps['minecraft'],'important':True},{'uid':'net.neoforged','version':deps['neoforge']}]},indent=1))
 (inst/'instance.cfg').write_text('InstanceType=OneSix\nname=Vanilla Tech\n')
 return game

def snapshot(game,paths):return {p:hashlib.sha256((game/p).read_bytes()).hexdigest() for p in paths if (game/p).exists()}
def whole(game):return snapshot(game,[p.relative_to(game).as_posix() for p in game.rglob('*') if p.is_file()])

def main():
 ap=argparse.ArgumentParser()
 for k in ('work','base-tag','base-mrpack','next-tag','next-mrpack'):ap.add_argument('--'+k,required=True)
 a=ap.parse_args();work=pathlib.Path(a.work).resolve()
 if work.exists():shutil.rmtree(work)
 site=work/'site';tag_tree(a.base_tag,work/'src-a');tag_tree(a.next_tag,work/'src-b')
 c_mrpack=build_client_only(work/'src-b',work/'src-c')
 rels={}
 for key,root,mp in (('A',work/'src-a',a.base_mrpack),('B',work/'src-b',a.next_mrpack),('C',work/'src-c',c_mrpack)):
  rels[key]=release.publish(site,root,mp,commit='scenario')
 release.verify(site)
 imp=release.impact(rels['B'],rels['C']);step('impact B->C is client-only, no EC2 deploy',imp['severity']=='client' and not imp['server_deploy'],imp['severity'])
 imp=release.impact(rels['A'],rels['B']);step('impact A->B needs EC2 deploy',imp['server_deploy'] and imp['severity']=='high',imp['severity'])

 class Quiet(http.server.SimpleHTTPRequestHandler):
  def log_message(self,*a):pass
 srv=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=str(site)))
 threading.Thread(target=srv.serve_forever,daemon=True).start()
 url=f'http://127.0.0.1:{srv.server_port}/stable/pack.toml'
 def promote(v):release.alias(site,'stable',v)
 def run(label):
  rc,out,secs=ci.install(url,'client',game);(work/f'log-{len(results):02d}-{label}.txt').write_text(out);return rc,out,secs

 # --- player instance: imported from A, then used for a while
 inst=work/'prism/instances/VanillaTech';game=prism_import(pathlib.Path(a.base_mrpack),inst)
 (game/'options.txt').write_text((game/'options.txt').read_text()+'fov:0.85\nkey_key.jump:key.keyboard.v\n')
 shader=[p.relative_to(game).as_posix() for p in (game/'shaderpacks').glob('*.txt')][0]
 (game/shader).write_text((game/shader).read_text()+'PLAYER_SETTING=1\n')
 for p,b in (('saves/Mundo/level.dat',os.urandom(4096)),('servers.dat',b'servers'),('mods/mi-mod-personal.jar',b'PK\x05\x06'+bytes(18)),
             ('config/jei/jei-client.ini',b'[x]\n'),('xaero/minimap/waypoints.txt',b'base:700:64:700\n')):
  (game/p).parent.mkdir(parents=True,exist_ok=True);(game/p).write_bytes(b)
 player=['options.txt',shader,'saves/Mundo/level.dat','servers.dat','mods/mi-mod-personal.jar','config/jei/jei-client.ini','xaero/minimap/waypoints.txt']
 before=snapshot(game,player);jars={p.name:p.stat().st_mtime_ns for p in (game/'mods').glob('*.jar')}

 promote(rels['A']['version']);rc,out,secs=run('adopt-A')
 step('first run on an imported instance (stable=A) succeeds',rc==0,f'{secs}s')
 step('existing mods adopted without re-download',all((game/'mods'/n).stat().st_mtime_ns==t for n,t in jars.items()),'mtimes unchanged')
 step('player files untouched after first run',snapshot(game,player)==before)
 step('instance matches release A',not ci.check(game,rels['A'],'client'),', '.join(ci.check(game,rels['A'],'client'))[:300])
 state=whole(game);rc,out,secs=run('noop-A')
 # Preserved files the player changed are re-validated (not rewritten) on every launch, so it is not a pure "already up to date".
 changed=sorted(k for k in set(state)|set(whole(game)) if state.get(k)!=whole(game).get(k) and k!='packwiz.json')
 step('second run changes nothing',rc==0 and not changed,f'{secs}s; changed: {changed}')

 promote(rels['B']['version']);rc,out,secs=run('update-B')
 step('update A->B succeeds',rc==0,f'{secs}s')
 step('instance matches release B (new mods, new configs)',not ci.check(game,rels['B'],'client'),', '.join(ci.check(game,rels['B'],'client'))[:300])
 cfg=(work/'src-b/config/cataclysm-common.toml').read_bytes()==(game/'config/cataclysm-common.toml').read_bytes()
 step('pack-owned config updated',cfg)
 step('player options/keybinds/shader settings/saves/personal mod preserved',snapshot(game,player)==before)

 promote(rels['C']['version']);rc,out,secs=run('update-C')
 step('client-only update B->C succeeds',rc==0,f'{secs}s')
 dfps=rels['B']['client']['mods']['mods/dynamic-fps']['file']
 step('mod removed from the pack is deleted',not (game/dfps).exists(),dfps)
 step('player files still preserved (options.txt not replaced by new default)',snapshot(game,player)==before)

 # --- client rollback C->B through a broken publication: stable/ serves a stale metafile whose bytes
 #     no longer match the index (what a half-propagated CDN would do)
 promote(rels['B']['version']);meta=site/'stable/mods/dynamic-fps.pw.toml';good=meta.read_bytes()
 meta.write_bytes(good.replace(b'side = "client"',b'side = "both"'))
 state=whole(game);rc,out,secs=run('broken')
 step('stale/corrupt metafile rejected: installer exits non-zero, Prism does not launch',rc!=0 and 'Invalid mod file hash' in out,f'exit {rc}')
 changed=sorted(k for k in set(state)|set(whole(game)) if state.get(k)!=whole(game).get(k) and k!='packwiz.json')
 step('nothing from the broken publication written to the instance',not changed and not (game/dfps).exists(),str(changed))
 meta.write_bytes(good);rc,out,secs=run('rollback-B')
 step('after the site is fixed, client rollback C->B restores the removed mod',rc==0 and (game/dfps).exists() and not ci.check(game,rels['B'],'client'),f'{secs}s')
 step('player files preserved through rollback',snapshot(game,player)==before)

 # --- dedicated-server side of the same tree: client-only mods must not land on a server
 rc,out,secs=ci.install(f'http://127.0.0.1:{srv.server_port}/releases/{rels["B"]["version"]}/pack.toml','server',work/'server-side')
 bad=ci.check(work/'server-side',rels['B'],'server')
 step('server-side install has exactly the server mods',rc==0 and not bad,f"{rels['B']['counts']['server']} mods; "+', '.join(bad)[:200])
 srv.shutdown()
 (work/'results.json').write_text(json.dumps(results,indent=1)+'\n')
 failed=[r for r in results if not r['ok']];print(f'{len(results)-len(failed)}/{len(results)} passed');sys.exit(1 if failed else 0)

if __name__=='__main__':main()
