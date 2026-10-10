#!/usr/bin/env python3
"""Fast pack lint (no downloads). Runs first in CI.

  check-pack.py [--root DIR] [--tag vX.Y.Z]

- pack.toml: release version format; Minecraft 1.21.1 + NeoForge pinned (changing them needs the
  owner's authorization: set ALLOW_LOADER_CHANGE=1 in that PR's CI run).
- index.toml in sync with the files and with pack.toml (what `packwiz refresh` would write).
- every metafile pinned, side client/server/both, sha512/sha1 hash, official CDN URL, plain filename.
- nothing private in the published tree: no jars, worlds, logs or secret-looking strings.
- player-owned client files marked preserve; CHANGELOG entry for the version; tag == version.
"""
import argparse,fnmatch,hashlib,os,pathlib,re,sys,tomllib
import preserve
VERSION_RE=re.compile(r'^[0-9]+\.[0-9]+\.[0-9]+(-(alpha|beta|rc)\.[0-9]+)?$')
HOSTS=('https://cdn.modrinth.com/','https://edge.forgecdn.net/','https://mediafilez.forgecdn.net/')
SECRET=re.compile(rb'AKIA[0-9A-Z]{16}|aws_secret_access_key|-----BEGIN [A-Z ]*PRIVATE KEY|rcon[._-]?password\s*[=:]\s*\S|ghp_[A-Za-z0-9]{30,}|xox[bp]-[0-9A-Za-z-]+',re.I)
errors=[]
def err(m):errors.append(m)

ap=argparse.ArgumentParser();ap.add_argument('--tag');ap.add_argument('--root',type=pathlib.Path,default=pathlib.Path(__file__).resolve().parents[1]);a=ap.parse_args()
ROOT=a.root.resolve()
pack=tomllib.loads((ROOT/'pack.toml').read_text());v=pack.get('version','')
if not VERSION_RE.match(v):err(f'pack.toml version {v!r} is not X.Y.Z or X.Y.Z-(alpha|beta|rc).N')
if pack.get('versions')!={'minecraft':'1.21.1','neoforge':'21.1.257'} and os.environ.get('ALLOW_LOADER_CHANGE')!='1':
 err(f"Minecraft/NeoForge changed to {pack.get('versions')}: needs explicit authorization (ALLOW_LOADER_CHANGE=1)")
if a.tag and a.tag!='v'+v:err(f'tag {a.tag} does not match pack.toml version {v}')
idxb=(ROOT/pack['index']['file']).read_bytes()
if hashlib.sha256(idxb).hexdigest()!=pack['index']['hash']:err('pack.toml index hash is stale: run bash scripts/build.sh and commit')
idx=tomllib.loads(idxb.decode());listed=set()
PUBLISHED=('mods','config','defaultconfigs','resourcepacks','shaderpacks')   # what may reach players' instances
for f in idx['files']:
 p=f['file'];listed.add(p);path=ROOT/p
 if p!='options.txt' and p.split('/')[0] not in PUBLISHED:err(f'{p} would be published to every instance: add it to .packwizignore or extend PUBLISHED on purpose')
 if not path.exists():err(f'index lists missing file {p}');continue
 data=path.read_bytes()
 if hashlib.sha256(data).hexdigest()!=f['hash']:err(f'index hash stale for {p}: run bash scripts/build.sh and commit')
 if p.lower().endswith(('.jar','.zip','.mrpack')) or p.split('/')[0] in ('saves','world','logs','crash-reports','backups'):err(f'{p} must not be published')
 if SECRET.search(data):err(f'{p} contains something that looks like a credential')
 if f.get('metafile'):
  m=tomllib.loads(data.decode());d=m.get('download',{})
  if m.get('side') not in ('client','server','both'):err(f'{p}: side must be client/server/both')
  if m.get('pin') is not True:err(f'{p}: not pinned (packwiz pin)')
  if d.get('hash-format') not in ('sha512','sha1') or not d.get('hash'):err(f'{p}: needs a sha512/sha1 hash')
  if not str(d.get('url','')).startswith(HOSTS):err(f'{p}: download must come from an official CDN, got {d.get("url") or d.get("mode")}')
  if '/' in m.get('filename','/') or '..' in m.get('filename',''):err(f'{p}: bad filename')
for p in ROOT.rglob('*'):
 rel=p.relative_to(ROOT).as_posix()
 if p.is_file() and rel.split('/')[0] in ('mods','config','resourcepacks','shaderpacks') and rel not in listed:err(f'{rel} exists but is not in index.toml (run bash scripts/build.sh)')
for f in idx['files']:
 if any(fnmatch.fnmatchcase(f['file'],pat) for pat in preserve.PATTERNS) and not f.get('preserve'):
  # Trees older than the pipeline get the flag from release.py publish; newer ones must carry it.
  if (ROOT/'scripts/preserve.py').exists():err(f"{f['file']} must be preserve = true (player-owned)")
  else:print(f"::warning::{f['file']} lacks preserve = true; release.py publish adds it to the published tree")
if not re.search(rf'(?m)^## {re.escape(v)}\b',(ROOT/'CHANGELOG.md').read_text()):err(f'CHANGELOG.md has no "## {v}" entry')
for e in errors:print(f'::error::{e}')
print(f"check-pack: {len(idx['files'])} indexed files, version {v}: {'FAIL' if errors else 'OK'}")
sys.exit(1 if errors else 0)
