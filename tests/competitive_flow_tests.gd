extends Node
var passed:=0
var failed:=0
var cues: Array[String]=[]
func check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:
	Profiles.storage_path="user://competitive_flow.cfg"
	var game: ModeGame=preload("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Flow_Test");game.friends=true;game.session.host(Account.identity())
	game.session.phase="racing";game.session.start_at=game.session.now()+0.001;game.session.selected_match_time=60
	game._session_changed();game.race.begin()
	SaveData.sound_enabled=true
	Audio.cue_played.connect(func(cue: String):cues.append(cue))
	for left in range(5,0,-1):
		game.session.start_at=game.session.now()-60+left-0.1
		var cursor: int=cues.size()
		game._process(0)
		check(game.ui.time_label.text=="00:0"+str(left),"countdown label "+str(left))
		check(cues.size()==cursor+1,"one tick "+str(left))
		game._process(0)
		check(cues.size()==cursor+1,"no repeated tick "+str(left))
		check(game.ui.message_label.text.begins_with("TIME RUNNING OUT!"),"small tension hint")
	SaveData.sound_enabled=false;game.last_match_second=-1
	var cursor: int=cues.size();game._process(0)
	check(cues.size()==cursor,"muted ticks")
	SaveData.sound_enabled=true
	game.session.start_at=game.session.now()-61
	var before:=game.race.rows()
	game.race.arrive(1,Vector2i(game.world.goals.keys()[0],game.world.config.goal_row))
	game.session.send_direction(Vector2i.UP)
	check(game.race.rows()==before,"deadline guard before phase transition")
	game.race.expire_match()
	check(game.session.phase=="time_up" and game.ui.countdown.text=="TIME UP!" and not game.controls.enabled,"time up presentation")
	check(cues.size()==cursor+1 and Audio.streams.time_up!=Audio.streams.ui,"distinct once-only time up cue")
	game.race.expire_match();check(cues.size()==cursor+1,"time up cue not duplicated")
	game.session.results_at=game.session.now()-1;game.race._physics_process(0)
	check(game.session.phase=="results" and game.ui.page=="race_results","delayed final results")
	game.leave_friends();game._action("local","");game.select_level(0)
	await get_tree().physics_frame
	check(game.state==game.State.PLAYING and game.world.player.enabled,"Local Play after timeout")
	for voice in Audio.voices:voice.stop()
	await get_tree().create_timer(0.6).timeout
	game.world.set_active(false);game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("RESULT ",passed," passed / ",failed," failed");get_tree().quit(failed)
