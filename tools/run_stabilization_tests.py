"""Usage: python tools/run_stabilization_tests.py GODOT. Test saves are isolated."""
import os,subprocess,sys,time
from pathlib import Path
p=Path(__file__).resolve().parents[1];g=Path(sys.argv[1]).resolve();logs=Path(os.environ.get('LAN_TEST_LOGS',p/'docs/stabilization_logs')).resolve();logs.mkdir(parents=True,exist_ok=True)
def env(name):
 d=logs/(name+'_data');d.mkdir(exist_ok=True);return dict(os.environ,XDG_DATA_HOME=str(d),APPDATA=str(d),LOCALAPPDATA=str(d))
def good(code,s):return code==0 and 'RESULT' in s and not any(x in s for x in ['ERROR:','FAIL','SCRIPT ERROR'])
bad=False
for name in ['lan_stabilization_tests','lan_stabilization_extra']:
 r=subprocess.run([str(g),'--headless','--path',str(p),f'res://tests/{name}.tscn'],env=env(name),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=40)
 (logs/(name+'.log')).write_text(r.stdout);ok=good(r.returncode,r.stdout);bad|=not ok;print(name,ok,flush=True)
ps=[];fs=[]
try:
 for role in ['host','client']:
  f=open(logs/(role+'.log'),'w');fs.append(f);ps.append(subprocess.Popen([str(g),'--headless','--path',str(p),'res://tests/lan_replay_tests.tscn','--',role],env=env(role),stdout=f,stderr=subprocess.STDOUT));time.sleep(.5)
 for role,proc,f in zip(['host','client'],ps,fs):
  code=proc.wait(timeout=45);f.flush();ok=good(code,(logs/(role+'.log')).read_text());bad|=not ok;print('replay',role,ok,flush=True)
finally:
 for proc in ps:
  if proc.poll() is None:proc.terminate();proc.wait()
 for f in fs:f.close()
sys.exit(int(bad))
