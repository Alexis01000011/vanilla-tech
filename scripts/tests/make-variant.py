#!/usr/bin/env python3
"""Build a throwaway release variant from a git tag, for pipeline tests only.

  make-variant.py --tag v0.5.0-alpha.1 --version 0.5.1-alpha.1 --out DIR
                  [--remove mods/x.pw.toml ...] [--append path=text ...]

Writes DIR/tree (packwiz tree) and DIR/vanilla-tech-<version>.mrpack using the repo's packwiz
binary and the tag's own package.py, exactly like build.sh does. Prints the .mrpack path.
"""
import argparse,io,pathlib,shutil,subprocess,sys,tarfile
SCRIPTS=pathlib.Path(__file__).resolve().parents[1];ROOT=SCRIPTS.parent

def build(tag,version,out,remove=(),append=()):
 out=pathlib.Path(out);tree=out/'tree'
 if tree.exists():shutil.rmtree(tree)
 tree.mkdir(parents=True)
 data=subprocess.run(['git','-C',str(ROOT),'archive',tag],capture_output=True,check=True).stdout
 tarfile.open(fileobj=io.BytesIO(data)).extractall(tree,filter='data')
 for r in remove:(tree/r).unlink()
 for a in append:
  path,_,text=a.partition('=');p=tree/path;p.write_text(p.read_text()+text.replace('\\n','\n'))
 pt=tree/'pack.toml';s=pt.read_text();old=[l for l in s.splitlines() if l.startswith('version = ')][0]
 pt.write_text(s.replace(old,f'version = "{version}"',1))
 (tree/'.tools').mkdir();shutil.copy2(ROOT/'.tools/packwiz',tree/'.tools/packwiz');(tree/'.cache').mkdir(exist_ok=True)
 pw=lambda *a:subprocess.run([str(tree/'.tools/packwiz'),'--cache',str(ROOT/'.cache/packwiz'),*a],cwd=tree,check=True,capture_output=True)
 pw('refresh');subprocess.run([sys.executable,str(SCRIPTS/'preserve.py'),str(tree)],check=True,capture_output=True);pw('refresh')
 pw('modrinth','export','--restrictDomains=false','-o','.cache/export.mrpack')
 (tree/'releases').mkdir(exist_ok=True);subprocess.run([sys.executable,'scripts/package.py'],cwd=tree,check=True,capture_output=True)
 mr=out/f'vanilla-tech-{version}.mrpack';shutil.copy2(tree/'releases'/mr.name,mr)
 shutil.rmtree(tree/'.tools');shutil.rmtree(tree/'.cache');shutil.rmtree(tree/'releases')
 return mr

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--tag',required=True);ap.add_argument('--version',required=True);ap.add_argument('--out',required=True)
 ap.add_argument('--remove',nargs='*',default=[]);ap.add_argument('--append',nargs='*',default=[])
 a=ap.parse_args();print(build(a.tag,a.version,a.out,a.remove,a.append))
