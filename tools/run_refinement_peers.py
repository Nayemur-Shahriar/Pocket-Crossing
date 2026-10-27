"""Four real ENet processes: authoritative dog, owner-only feedback, water and results."""
import json,os,subprocess,sys,time
from pathlib import Path
p=Path(__file__).resolve().parents[1];g=Path(sys.argv[1]).resolve();logs=Path(os.environ.get('LAN_TEST_LOGS',p/'docs/refinement_peer_logs')).resolve();logs.mkdir(parents=True,exist_ok=True)
processes=[];handles=[];results=[]
try:
 for n in range(4):
  h=open(logs/f'peer{n}.log','w');handles.append(h)
  processes.append(subprocess.Popen([str(g),'--verbose','--headless','--max-fps','60','--path',str(p),'res://tests/refinement_peer_tests.tscn','--','host' if n==0 else 'client',str(n)],env=dict(os.environ,XDG_DATA_HOME=str(logs/f'data{n}')),stdout=h,stderr=subprocess.STDOUT));time.sleep(.3)
 for n,proc in enumerate(processes):
  code=proc.wait(timeout=42);handles[n].flush();text=(logs/f'peer{n}.log').read_text()
  row={'peer':n,'exit':code,'summary':[s for s in text.splitlines() if 'RESULT' in s or 'ERROR' in s or 'FAIL' in s]};results.append(row);print(json.dumps(row),flush=True)
finally:
 for proc in processes:
  if proc.poll() is None:proc.terminate();proc.wait()
 for h in handles:h.close()
(logs/'summary.json').write_text(json.dumps(results,indent=2))
sys.exit(int(len(results)!=4 or any(r['exit'] or any('ERROR' in s or 'FAIL' in s for s in r['summary']) for r in results)))
