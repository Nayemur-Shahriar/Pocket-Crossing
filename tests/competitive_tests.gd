extends Node
var passed:=0
var failed:=0
func check(ok: bool, label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func row(peer: int, safe: int=5, time: float=65, score: int=8000, coins: int=2, deaths: int=1) -> Dictionary:
	return {"peer":peer,"safe":safe,"time":time,"score":score,"coins":coins,"deaths":deaths,"name":"Player_"+str(peer)}
func _ready() -> void:
	check(LanMatchRules.score(5,10,2,30.99)==8450,"exact formula and floor")
	check(LanMatchRules.score(0,0,3,120)==0,"zero floor")
	check(LanMatchRules.score(4,2,1,120)==3950,"no unfinished time/completion bonus")
	check(LanMatchRules.ranked([row(1),row(2,5,75,9500)],"time")[0].peer==1,"time example")
	check(LanMatchRules.ranked([row(1,5,65,8500),row(2,5,75,9200)],"score")[0].peer==2,"score example")
	check(LanMatchRules.ranked([row(1,4,0,5000),row(2,3,0,6000)],"time")[0].peer==1,"unfinished example")
	check(LanMatchRules.before(row(1,5,99,10),row(2,4,0,9999),"time"),"finisher above unfinished")
	for mode in LanMatchRules.MODES:
		check(LanMatchRules.before(row(1),row(2),mode),"deterministic peer tie "+mode)
		check(not LanMatchRules.before(row(1),row(1),mode),"strict ordering "+mode)
	check(LanMatchRules.before(row(1,5,65,9000),row(2),"time"),"time score tie break")
	check(LanMatchRules.before(row(1,5,65,8000,3),row(2),"time"),"time coin tie break")
	check(LanMatchRules.before(row(1,5,65,8000,2,0),row(2),"time"),"time death tie break")
	check(LanMatchRules.before(row(1,5,65,8000),row(2,4,0,8000),"score"),"score safe tie break")
	check(LanMatchRules.before(row(1),row(2,5,75),"score"),"score time tie break")
	check(LanMatchRules.before(row(1,4,0,8000,1,0),row(2,4,0,8000,8,1),"score"),"score deaths before coins")
	check(LanMatchRules.before(row(1,4,0,8000,8,0),row(2,4,0,8000,1,0),"score"),"score final coin tie break")
	check(LanMatchRules.awards([row(1,0,0,0,0,0)]).is_empty(),"omit meaningless awards")
	var awards:=LanMatchRules.awards([row(1,4,0,4000,3,0)])
	check(awards.size()==3 and awards[0].kind=="score","no fastest without finisher")
	var effect:=ResultCelebration.new();add_child(effect);effect.set_process(false);effect.rng.seed=147
	var counts:={};var peak:=0;var max_waves:=0;var last_wave:=0;var intervals: Array=[];var launch_time:=0.0;var previous_end:=0.0;var launch_ok:=true;var explosion_ok:=true;var gap_ok:=true
	for i in range(7200):
		effect._process(1.0/60.0);peak=maxi(peak,effect.bursts.size());max_waves=maxi(max_waves,effect.active_waves())
		if effect.waves!=last_wave:
			if last_wave>0:intervals.append(effect.elapsed-launch_time)
			if last_wave>0:gap_ok=gap_ok and effect.elapsed-previous_end>=1.2 and effect.elapsed-previous_end<=1.82
			launch_time=effect.elapsed;last_wave=effect.waves
			var n:=0
			for burst in effect.bursts:
				if burst.wave==effect.waves:n+=1
			counts[n]=true
			var previous_born:=-1.0;var previous_pop:=-1.0
			for b in effect.bursts:
				var pop: float=b.born+b.travel
				if previous_born>=0:
					launch_ok=launch_ok and b.born-previous_born>=0.179 and b.born-previous_born<=0.351
					explosion_ok=explosion_ok and pop-previous_pop>=0.149 and pop-previous_pop<=0.401
				previous_born=b.born;previous_pop=pop;previous_end=maxf(previous_end,pop+b.life)
	check(launch_ok,"launch stagger .18-.35")
	check(explosion_ok,"explosion stagger .15-.40")
	check(gap_ok,"full-wave breathing gap 1.2-1.8")
	check(counts.has(4) and counts.has(5) and counts.has(6) and counts.size()==3,"variable four-six")
	check(peak<=6 and max_waves<=1 and effect.get_child_count()==1,"bounded fireworks")
	check(intervals.min()>=3.5 and intervals.max()<=7.5,"full wave plus breathing gap")
	print("FIREWORK_SIM peak=",peak," waves=",effect.waves," active=",max_waves," intervals=",intervals.min(),"..",intervals.max())
	effect.stop();check(effect.bursts.is_empty() and not effect.is_processing(),"cleanup")
	print("RESULT ",passed," passed / ",failed," failed");get_tree().quit(failed)
