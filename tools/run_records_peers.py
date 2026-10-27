"""Real four-process ENet test: one full 60s expiry, one score-mode finish."""
import json, os, subprocess, sys, time
from pathlib import Path
p=Path(__file__).resolve().parents[1];g=Path(sys.argv[1]).resolve()
logs=Path(os.environ.get('LAN_TEST_LOGS',p/'docs/records_peer_logs')).resolve();logs.mkdir(parents=True,exist_ok=True)
processes=[];handles=[];bad=False
try:
 for n in range(4):
  handle=open(logs/f'peer{n}.log','w');handles.append(handle)
  env=dict(os.environ,XDG_DATA_HOME=str(logs/f'data{n}'))
  processes.append(subprocess.Popen([str(g),'--headless','--max-fps','60','--path',str(p),'res://tests/records_peer_tests.tscn','--','host' if n==0 else 'client',str(n)],env=env,stdout=handle,stderr=subprocess.STDOUT));time.sleep(.35)
 for n,proc in enumerate(processes):
  code=proc.wait(timeout=105);handles[n].flush();text=(logs/f'peer{n}.log').read_text();bad|=code!=0 or 'ERROR' in text or 'FAIL' in text
  print(n,code,[line for line in text.splitlines() if 'RESULT' in line or 'ERROR' in line or 'FAIL' in line],flush=True)
 results=[json.loads((logs/f'data{n}/godot/app_userdata/Pocket Crossing/competitive_results.json').read_text()) for n in range(4)]
 identical=all(r['records']==results[0]['records'] for r in results);bad|=not identical
 (logs/'summary.json').write_text(json.dumps({'identical':identical,'peers':results},indent=2));print('IDENTICAL',identical)
finally:
 for proc in processes:
  if proc.poll() is None:proc.terminate();proc.wait()
 for handle in handles:handle.close()
sys.exit(int(bad))
