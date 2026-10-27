"""Run the preserved Local suites and account tests; pass the Godot executable path."""
from concurrent.futures import ThreadPoolExecutor
import subprocess,os,json,time,sys
from pathlib import Path
project=Path(__file__).resolve().parents[1];base=Path(os.environ.get('LAN_TEST_LOGS',project/'docs/local_regression_logs')).resolve();base.mkdir(parents=True,exist_ok=True);godot=Path(sys.argv[1]).resolve()
names=['test_runner','phase3_tests','phase4_tests','section_tests','railway_tests','water_tests','water_route_tests','long_level_tests','long_route_tests','theme_tests','theme_route_tests','campaign_route_tests','campaign_tests','identity_tests','balance_tests','balance_water_routes','qa_validation','qa_contacts','qa_stress','qa_repro','qa_perf','post_m14_tests','map_campaign_tests','map_route_tests','lan_account_tests']
def run(name):
 env=dict(os.environ,XDG_DATA_HOME=str(base/('data_'+name)))
 begin=time.monotonic()
 r=subprocess.run([str(godot),'--headless','--path',str(project),'--fixed-fps','60',f'res://tests/{name}.tscn'],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=300)
 (base/(name+'.log')).write_text(r.stdout)
 summary=[s for s in r.stdout.splitlines() if 'RESULT' in s or 'FAIL' in s or 'SCRIPT ERROR' in s]
 return {'suite':name,'exit':r.returncode,'seconds':round(time.monotonic()-begin,2),'summary':summary}
results=[]
with ThreadPoolExecutor(max_workers=2) as pool:
 for result in pool.map(run,names):
  results.append(result);print(json.dumps(result),flush=True)
(base/'regression_results.json').write_text(json.dumps(results,indent=2))

raise SystemExit(int(any(r["exit"]!=0 or any("FAIL" in s or "SCRIPT ERROR" in s for s in r["summary"]) for r in results)))
