import os,sys,subprocess,time,json
from pathlib import Path
project=Path(__file__).resolve().parents[1];godot=Path(sys.argv[1]).resolve();base=Path(os.environ.get('LAN_TEST_LOGS',project/'docs/lan_connections')).resolve();base.mkdir(parents=True,exist_ok=True)
summary=[]
for scenario in ['duplicate','version','full','lobby_disconnect','match_disconnect','host_disconnect','midmatch']:
 peers=[];files=[];count=5 if scenario=='full' else 3 if scenario=='midmatch' else 2
 try:
  for n in range(count):
   f=open(base/f'{scenario}_{n}.log','w');files.append(f)
   env=dict(os.environ,XDG_DATA_HOME=str(base/f'data_{scenario}_{n}'))
   peers.append(subprocess.Popen([str(godot),'--headless','--max-fps','60','--path',str(project),'res://tests/lan_connection_tests.tscn','--','host' if n==0 else 'client',scenario,str(n)],env=env,stdout=f,stderr=subprocess.STDOUT));time.sleep(.3)
  for n,p in enumerate(peers):
   code=p.wait(timeout=35);files[n].flush();s=(base/f'{scenario}_{n}.log').read_text();r={'scenario':scenario,'peer':n,'exit':code,'errors': 'ERROR' in s or 'FAIL' in s,'summary':[x for x in s.splitlines() if 'RESULT' in x]};summary.append(r);print(r,flush=True)
 finally:
  for p in peers:
   if p.poll() is None:p.terminate();p.wait()
  for f in files:f.close()
(base/'summary.json').write_text(json.dumps(summary,indent=2));sys.exit(int(any(r['exit'] or r['errors'] for r in summary)))
