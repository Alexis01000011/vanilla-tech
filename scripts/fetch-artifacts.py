#!/usr/bin/env python3
"""Fetch the exported lock without embedding or redistributing third-party jars."""
import concurrent.futures,json,pathlib,sys,zipfile
from common import ROOT,download
pack=pathlib.Path(sys.argv[1])
with zipfile.ZipFile(pack) as z:
    files=json.loads(z.read('modrinth.index.json'))['files']
    assert not any(n.endswith('.jar') for n in z.namelist()), 'Export embeds jars; fix provider URLs first'
def fetch(f):
    p=ROOT/'.cache/artifacts'/pathlib.Path(f['path']).name
    download(f['downloads'][0],p,f['hashes']);return p.name
for n in concurrent.futures.ThreadPoolExecutor(max_workers=4).map(fetch,files):print(n,flush=True)
