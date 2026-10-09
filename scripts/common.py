"""Shared, dependency-free helpers (Python >=3.11)."""
import hashlib, json, pathlib, urllib.request
ROOT=pathlib.Path(__file__).resolve().parents[1]
def download(url, target, hashes):
    target=pathlib.Path(target)
    def valid(b): return all(hashlib.new(k,b).hexdigest()==v for k,v in hashes.items())
    if target.exists() and valid(target.read_bytes()): return target
    req=urllib.request.Request(url,headers={'User-Agent':'VanillaTech/0.1 (+packwiz)'})
    with urllib.request.urlopen(req,timeout=120) as r: data=r.read()
    if not valid(data): raise RuntimeError('Checksum mismatch: '+url)
    target.parent.mkdir(parents=True,exist_ok=True)
    tmp=target.with_name(target.name+'.part');tmp.write_bytes(data);tmp.replace(target)
    return target
