#!/usr/bin/env python3
"""Mark player-owned client files as `preserve = true` in a packwiz index.

packwiz-installer (Prism pre-launch auto-update) then writes them only when they are missing,
so a release never overwrites the player's options, keybinds or shader settings.

  preserve.py [ROOT]          edit ROOT/index.toml in place (build.sh; then `packwiz refresh`)
  preserve.py ROOT --repack   also rewrite the index hash in ROOT/pack.toml (published trees)
"""
import fnmatch,hashlib,pathlib,re,sys,tomllib
PATTERNS=['options.txt','shaderpacks/*.txt','config/litematica.json']

def apply(root,repack=False):
 root=pathlib.Path(root);pack=tomllib.loads((root/'pack.toml').read_text())
 index=root/pack['index']['file'];blocks=re.split(r'(?m)^(?=\[\[files\]\]\n)',index.read_text());changed=[]
 for i,b in enumerate(blocks):
  if not b.startswith('[[files]]'):continue
  f=tomllib.loads(b)['files'][0]
  if f.get('metafile') or f.get('preserve') or not any(fnmatch.fnmatchcase(f['file'],p) for p in PATTERNS):continue
  blocks[i]=b.rstrip('\n')+'\npreserve = true\n'+('\n' if b.endswith('\n\n') else '');changed.append(f['file'])
 if changed:index.write_text(''.join(blocks))
 data=index.read_bytes();assert pack['index']['hash-format']=='sha256'
 if repack:
  pt=root/'pack.toml';new=hashlib.sha256(data).hexdigest()
  pt.write_text(re.sub(r'(?m)^hash = "[0-9a-f]{64}"$',f'hash = "{new}"',pt.read_text(),count=1))
  assert tomllib.loads(pt.read_text())['index']['hash']==new
 missing=[f['file'] for f in tomllib.loads(data.decode())['files'] if not f.get('metafile') and not f.get('preserve') and any(fnmatch.fnmatchcase(f['file'],p) for p in PATTERNS)]
 assert not missing,missing
 return changed

if __name__=='__main__':
 args=[a for a in sys.argv[1:] if not a.startswith('--')]
 for f in apply(args[0] if args else pathlib.Path(__file__).resolve().parents[1],'--repack' in sys.argv):print('preserve:',f)
