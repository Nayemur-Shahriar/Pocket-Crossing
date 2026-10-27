"""Run real ENet peers in isolated user-data directories. Usage: python tools/run_lan_tests.py GODOT [COUNT] [SOAK_SECONDS]."""
import subprocess,os,sys,json,time
from pathlib import Path
project=Path(__file__).resolve().parents[1];godot=Path(sys.argv[1]).resolve();count=int(sys.argv[2]) if len(sys.argv)>2 else 4;soak=int(sys.argv[3]) if len(sys.argv)>3 else 0
logs=Path(os.environ.get('LAN_TEST_LOGS',project/'docs'/f'lan_test_{count}_{soak}')).resolve();logs.mkdir(parents=True,exist_ok=True)
peers=[];handles=[];bad=False
try:
 for n in range(count):
  f=open(logs/f'peer_{n}.log','w');handles.append(f)
  env=dict(os.environ,XDG_DATA_HOME=str(logs/f'data_{n}'))
  peers.append(subprocess.Popen([str(godot),'--headless','--max-fps','60','--path',str(project),'res://tests/lan_peer_tests.tscn','--','host' if n==0 else 'client',str(count),str(n),str(soak)],env=env,stdout=f,stderr=subprocess.STDOUT));time.sleep(.4)
 for n,p in enumerate(peers):
  code=p.wait(timeout=145+soak);handles[n].flush();s=(logs/f'peer_{n}.log').read_text();bad|=code!=0 or 'ERROR' in s or 'FAIL' in s
  print(n,code,[x for x in s.splitlines() if 'RESULT' in x or 'ERROR' in x or 'FAIL' in x],flush=True)
 data=[json.loads((logs/f'data_{n}'/'godot/app_userdata/Pocket Crossing/peer_results.json').read_text()) for n in range(count)]
 same=all(d['results']==data[0]['results'] for d in data);bad|=not same or any(d['failed'] for d in data)
 summary={'identical_results':same,'peers':data};(logs/'summary.json').write_text(json.dumps(summary,indent=2));print('identical results',same,[(d['passed'],d['failed'],d['snapshots']) for d in data],flush=True)
finally:
 for p in peers:
  if p.poll() is None:p.terminate();p.wait()
 for f in handles:f.close()
sys.exit(int(bad))
