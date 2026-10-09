#!/usr/bin/env python3
"""Refresh research only; does not modify the locked pack."""
import concurrent.futures, json, pathlib, urllib.request
ROOT = pathlib.Path(__file__).resolve().parents[1]
NAMES = 'create ae2 applied-create applied-energistics-2-wireless-terminals extended-ae waystones excessive-utilities explorify yungs-extras yungs-bridges jei inventory-profiles-next crafting-tweaks xaeros-minimap xaeros-world-map sodium lithium ferrite-core modernfix immediatelyfast entityculling dynamic-fps spark chunky'.split()
def get(url):
    req = urllib.request.Request(url, headers={'User-Agent':'VanillaTech/0.1 research'})
    with urllib.request.urlopen(req, timeout=60) as r: return json.load(r)
def fetch(n):
    p=get('https://api.modrinth.com/v2/project/'+n)
    vs=get('https://api.modrinth.com/v2/project/'+n+'/version?loaders=%5B%22neoforge%22%5D&game_versions=%5B%221.21.1%22%5D')
    vs=[v for v in vs if v['date_published']<'2026-10-10' and v['version_type']=='release']
    if not vs: raise RuntimeError('No release: '+n)
    d={'project':p,'version':vs[0]}
    (ROOT/'research'/f'{n}.json').write_text(json.dumps(d,indent=2)+'\n')
    return n,vs[0]['id'],vs[0]['version_number']
if __name__=='__main__':
    for row in concurrent.futures.ThreadPoolExecutor(max_workers=6).map(fetch,NAMES): print(*row,flush=True)
