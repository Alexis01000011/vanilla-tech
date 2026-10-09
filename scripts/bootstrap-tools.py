#!/usr/bin/env python3
import hashlib,io,json,os,pathlib,zipfile
from common import ROOT,download
lock=json.loads((ROOT/'research/packwiz.json').read_text())
binary=ROOT/'.tools/packwiz'
if binary.exists() and hashlib.sha256(binary.read_bytes()).hexdigest()==lock['binary_sha256']:raise SystemExit(0)
archive=download(lock['artifact_url'],ROOT/'.cache/packwiz-tool.zip',{'sha256':lock['archive_sha256']})
with zipfile.ZipFile(archive) as z:data=z.read('packwiz')
assert hashlib.sha256(data).hexdigest()==lock['binary_sha256']
binary.parent.mkdir(exist_ok=True);binary.write_bytes(data);binary.chmod(0o755)
print('packwiz commit',lock['commit'])
