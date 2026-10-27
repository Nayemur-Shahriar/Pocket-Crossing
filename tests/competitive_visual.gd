extends Node
var game: ModeGame
func shot(label: String) -> void:
	for i in range(4):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/m147_screenshots")
	get_viewport().get_texture().get_image().save_png("res://docs/m147_screenshots/"+label+".png")
func _ready() -> void:
	Profiles.storage_path="user://visual.cfg"
	game=preload("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Host_Player");game.friends=true;game.session.host(Account.identity())
	for i in range(2,5):game.session.members[i]={"name":"Player_"+str(i),"ready":true,"connected":true,"seen":game.session.now(),"id":str(i).repeat(32),"skin":"pip"}
	game.session.select_rules(90,"score");game.ui.lobby(game.session)
	await shot("lobby")
	var rows: Array=[]
	for i in range(4):rows.append({"peer":i+1,"name":"Player_"+str(i+1),"rank":i+1,"safe":5-i,"coins":12-i,"deaths":i,"time":68.42 if i==0 else 0,"score":9450-i*1750,"status":"finished" if i==0 else "time_up","timed_out":true})
	game.session.phase="results";game.session.set_process(false)
	game.ui.race_results(rows,true,"Local Best Time and map unlocks are unchanged.","score",LanMatchRules.awards(rows),1)
	await get_tree().create_timer(1.7).timeout
	await shot("score_results")
	var effect: ResultCelebration=game.ui.map_celebration
	var samples: Array[float]=[];var peak:=0;var nodes:=0;var count_min:=100000;var start:=Time.get_ticks_msec()
	var duration:=2000 if "quick" in OS.get_cmdline_user_args() else 120000
	while Time.get_ticks_msec()-start<duration:
		await get_tree().process_frame
		samples.append(get_process_delta_time()*1000)
		peak=maxi(peak,effect.bursts.size());nodes=maxi(nodes,effect.get_child_count());count_min=mini(count_min,effect.get_child_count())
	samples.sort()
	print("RENDER duration_ms=",duration," frames=",samples.size()," median_ms=",samples[samples.size()/2]," p95_ms=",samples[int(samples.size()*0.95)]," max_records=",peak," wave_count=",effect.waves," nodes=",count_min,"..",nodes," audio_events=",effect.sound_events)
	await shot("score_120s")
	game.ui.race_results(rows,false,"Waiting for host.","time",LanMatchRules.awards(rows),2)
	await shot("time_results_guest")
	assert(game.ui.map_celebration==null,"No guest winner celebration")
	game.ui.hide_screen();await get_tree().process_frame
	assert(not is_instance_valid(effect),"Celebration freed")
	game.leave_friends();print("RESULT rendered ",duration/1000," seconds; cleanup PASS")
	get_tree().quit()
