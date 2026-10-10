#!/usr/bin/env python3
"""Warn about server files that itzg/minecraft-server would silently skip.

The EC2 server installs the .mrpack with itzg's TYPE=MODRINTH, which also drops every file matching
its built-in client-only list (files/modrinth-exclude-include.json). A server mod that lands on that
list would make the server differ from the clients, so the release must not rely on it.
  check-itzg.py RELEASE.mrpack [--list modrinth-exclude-include.json]
"""
import argparse,json,re,urllib.request,zipfile
URL='https://raw.githubusercontent.com/itzg/docker-minecraft-server/master/files/modrinth-exclude-include.json'
def matcher(p):
 p=p.lower()
 if len(p)>=2 and p.startswith('/') and p.endswith('/'):rx=re.compile(p[1:-1]);return lambda s:bool(rx.search(s))
 return lambda s:p in s
ap=argparse.ArgumentParser();ap.add_argument('mrpack');ap.add_argument('--list');a=ap.parse_args()
data=json.load(open(a.list)) if a.list else json.load(urllib.request.urlopen(urllib.request.Request(URL,headers={'User-Agent':'VanillaTech-CI'}),timeout=60))
ex=[matcher(p) for p in data.get('globalExcludes',[])];inc=[matcher(p) for p in data.get('globalForceIncludes',[])]
idx=json.loads(zipfile.ZipFile(a.mrpack).read('modrinth.index.json'))
skipped=[f['path'] for f in idx['files'] if f['env']['server']!='unsupported' and any(m(f['path'].lower()) for m in ex) and not any(m(f['path'].lower()) for m in inc)]
forced=[f['path'] for f in idx['files'] if f['env']['server']=='unsupported' and any(m(f['path'].lower()) for m in inc)]
for p in skipped:print(f'::warning::itzg would NOT install server file {p} (client-only list); fix its side or the server will differ')
for p in forced:print(f'::warning::itzg would force-install client-only file {p} on the server')
print(f'itzg exclusion check: {len(skipped)} skipped, {len(forced)} forced')
raise SystemExit(1 if skipped or forced else 0)
