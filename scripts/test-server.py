#!/usr/bin/env python3
"""Bounded localhost smoke test. Requires an explicitly disposable server directory."""
import argparse,json,os,pathlib,queue,subprocess,threading,time
from common import ROOT
ap=argparse.ArgumentParser();ap.add_argument('--accept-eula',action='store_true');ap.add_argument('--timeout',type=int,default=360);ap.add_argument('--heap',default='2G');ap.add_argument('--commands',type=pathlib.Path);a=ap.parse_args()
d=ROOT/'server'
if not (d/'.vanilla-tech-test-only').exists():raise SystemExit('Refusing: server/.vanilla-tech-test-only required (NEVER mark a production world).')
if not a.accept_eula and (not (d/'eula.txt').exists() or 'eula=true' not in (d/'eula.txt').read_text()):raise SystemExit('Owner must accept https://www.minecraft.net/eula; use --accept-eula only with approval.')
if a.accept_eula:(d/'eula.txt').write_text('# Owner explicitly authorized local test, 2026-10-09\neula=true\n')
props=(ROOT/'server-template/server.properties').read_text()+'\nserver-ip=127.0.0.1\nserver-port=25575\nview-distance=4\nsimulation-distance=4\nlevel-name=test-world\nlevel-seed=20261009\n'
(d/'server.properties').write_text(props)
cmd=['java','-Xms512m','-Xmx'+a.heap,'-XX:ActiveProcessorCount=2','-XX:+UseG1GC','-Xlog:gc*:file=gc-test.log:time,uptime,level,tags', '@libraries/net/neoforged/neoforge/21.1.257/unix_args.txt','nogui']
p=subprocess.Popen(cmd,cwd=d,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
q=queue.Queue();lines=[];peak=0;started=time.monotonic();ready=False;timedout=False
log=ROOT/'docs/server-smoke.log'
def reader():
 for line in p.stdout:q.put(line)
threading.Thread(target=reader,daemon=True).start()
def send(c):
 if p.poll() is None:p.stdin.write(c+'\n');p.stdin.flush()
commands=a.commands.read_text().splitlines() if a.commands else ['list','datapack list enabled','spark tps','save-all flush','stop']
nextcmd=0;nextat=0
try:
 with log.open('w') as f:
  while p.poll() is None or not q.empty():
   try:
    line=q.get(timeout=.2);lines.append(line);f.write(line);f.flush()
    if 'Done (' in line and not ready:ready=True;nextat=time.monotonic()+3;print(line.strip(),flush=True)
   except queue.Empty:pass
   try:
    status=pathlib.Path(f'/proc/{p.pid}/status').read_text();rss=int(next(x.split()[1] for x in status.splitlines() if x.startswith('VmRSS:')));peak=max(peak,rss)
   except (FileNotFoundError,StopIteration):pass
   now=time.monotonic()
   if ready and nextcmd<len(commands) and now>=nextat:
    c=commands[nextcmd];print('COMMAND',c,flush=True);send(c);nextcmd+=1;nextat=now+5
   if now-started>a.timeout:
    timedout=True;send('stop')
    try:p.wait(timeout=30)
    except subprocess.TimeoutExpired:p.terminate()
    break
finally:
 if p.poll() is None:
  send('stop')
  try:p.wait(timeout=30)
  except subprocess.TimeoutExpired:p.terminate();p.wait(timeout=15)
result={'ready':ready,'exit_code':p.returncode,'timeout':timedout,'elapsed_seconds':round(time.monotonic()-started,2),'peak_rss_mib':round(peak/1024,1),'heap':a.heap,'active_processors':2,'port':25575,'bind':'127.0.0.1','players':0,'commands_sent':commands[:nextcmd]}
(ROOT/'docs/server-smoke.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
raise SystemExit(0 if ready and p.returncode==0 and not timedout else 1)
