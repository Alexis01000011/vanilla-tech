#!/usr/bin/env python3
"""FTB Quests: keep quest/task/reward IDs stable between releases.

Team progress lives in the world (world/ftbquests/<team>.snbt) and points at the hex IDs written in
the quest book (config/ftbquests/quests/**.snbt). A release that drops or regenerates an ID silently
orphans that progress, so CI fails unless ALLOW_QUEST_ID_REMOVAL=1.

  check-quests.py BASE.mrpack NEW.mrpack
"""
import os,re,sys,zipfile
ID=re.compile(r'\bid:\s*"([0-9A-Fa-f]{16})"')
PREFIXES=('overrides/config/ftbquests/quests/','client-overrides/config/ftbquests/quests/','server-overrides/config/ftbquests/quests/')

def ids(mrpack):
 out={}
 with zipfile.ZipFile(mrpack) as z:
  for n in z.namelist():
   if n.startswith(PREFIXES) and n.endswith('.snbt'):
    for i in ID.findall(z.read(n).decode('utf-8','replace')):out[i.upper()]=n.split('/quests/',1)[1]
 return out

base,new=ids(sys.argv[1]),ids(sys.argv[2])
if not base and not new:print('check-quests: no FTB Quests book in either release');sys.exit(0)
gone=sorted(set(base)-set(new));added=sorted(set(new)-set(base))
print(f'check-quests: {len(base)} -> {len(new)} IDs; {len(added)} new, {len(gone)} removed')
for i in gone:print(f'::warning::quest object {i} ({base[i]}) removed: team progress on it is dropped')
if gone and os.environ.get('ALLOW_QUEST_ID_REMOVAL')!='1':
 print('::error::Quest IDs removed. If intentional, rerun with ALLOW_QUEST_ID_REMOVAL=1 (owner decision).');sys.exit(1)
