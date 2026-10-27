extends Node
var passed:=0
var failed:=0
var game: ModeGame
func check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:run.call_deferred()
func stop() -> void:game.set_physics_process(false);game.world.set_active(false)
func run() -> void:
	Profiles.storage_path="user://m149_records.cfg";SaveData.storage_path="user://m149_old.cfg"
	for path in [Profiles.storage_path,SaveData.storage_path]:
		for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	check(Account.create("Records_Test").is_empty(),"account created")
	SaveData.coins=1000;SaveData.sound_enabled=false
	for map: MapConfig in game.CAMPAIGN.levels:
		Profiles.purchase(map)
		check(map.ambience!=null,"map ambience "+map.level_id)
		check(RunRecords.read("local",map.level_id).plays==0,"legacy defaults")
	var map:=game.CAMPAIGN.levels[0] as MapConfig
	var id:=map.level_id
	var row:={"safe":5,"coins":12,"deaths":1,"score":6000,"time":65.0,"rank":2}
	check(RunRecords.apply("friends",id,"example"),"start saved")
	check(RunRecords.apply("friends",id,"example"),"duplicate start ignored")
	check(RunRecords.apply("friends",id,"example",row),"finish saved")
	check(RunRecords.apply("friends",id,"example",row),"duplicate finish ignored")
	check(RunRecords.read("friends",id)=={"plays":1,"completions":1,"first":0,"second":1,"third":0,"score":6000,"coins":12,"deaths":1,"time":65.0},"complete record contents")
	check(RunRecords.read("local",id).plays==0,"Friends isolated")
	var slower:=row.duplicate();slower.time=70.0;slower.deaths=2;slower.coins=4;slower.score=4000
	RunRecords.apply("friends",id,"slower",slower)
	check(RunRecords.read("friends",id).time==65 and RunRecords.read("friends",id).coins==12,"max/min records")
	var incomplete:=row.duplicate();incomplete.safe=4;incomplete.deaths=0;incomplete.time=40
	RunRecords.apply("local",id,"incomplete",incomplete)
	check(RunRecords.read("local",id).time==0 and RunRecords.read("local",id).deaths==-1,"incomplete cannot set finish best")
	var invalid:=row.duplicate();invalid.time=NAN
	check(not RunRecords.apply("local",id,"bad",invalid),"nonfinite rejected")
	var original: Dictionary=Profiles.profiles[Profiles.active_key].duplicate(true)
	Profiles.profiles[Profiles.active_key].records_v1="broken"
	check(RunRecords.read("local",id).plays==0,"corrupt optional fields ignored")
	RunRecords.apply("local",id,"repair",row)
	check(RunRecords.read("local",id).plays==1,"optional records repaired")
	Profiles.profiles[Profiles.active_key]=original;Profiles.save_active()
	check(RunRecords.set_option("music",false) and not RunRecords.option("music"),"music toggle saved")
	RunRecords.set_option("ambience",false);Profiles.load_profiles()
	check(not RunRecords.option("music") and not RunRecords.option("ambience"),"options reload")
	check(RunRecords.read("friends",id).plays==2,"records reload")
	game.select_level(0);stop()
	check(game.get("ghost")==null,"no ghost runtime")
	game.destinations_reached=5;game.elapsed_seconds=45;game.finish_game(true,"")
	game.finish_game(true,"")
	check(RunRecords.read("local",id).completions==1,"duplicate completion guarded")
	check(Profiles.best_time(id)==45,"Best Time retained")
	game.friends=true
	game.run_presentation.begin(map)
	for i in range(100):game.run_presentation.emit_effect("coin",Vector2.ZERO)
	check(game.run_presentation.bursts.size()==RunPresentation.LIMIT,"effects bounded")
	check(game.run_presentation.ambient.max_polyphony==1 and game.run_presentation.ambient.volume_db<=-25,"quiet single ambience voice")
	game.leave_friends()
	check(not game.run_presentation.ambient.playing and game.run_presentation.bursts.is_empty(),"Friends cleanup")
	game._action("settings","");check(game.ui.page=="settings","settings opens")
	game.clear_challenge();game.select_level(0);stop()
	var player:=game.world.player
	player.invulnerable_left=0
	game.powers.activate(load("res://resources/powerups/shield.tres"))
	var lives:=game.lives
	game._on_collision(player)
	check(game.lives==lives and game.run_stats.deaths==0,"shield does not add death record")
	player.invulnerable_left=0;game._on_collision(player)
	check(game.lives==lives-1 and game.run_stats.deaths==1,"actual damage adds one death")
	game._on_collision(player)
	check(game.run_stats.deaths==1,"duplicate damage ignored during respawn")
	check(not game.run_presentation.bursts.is_empty(),"impact feedback emitted")
	game.pause_local()
	var age: float=game.run_presentation.bursts[0].age
	game.run_presentation._process(0.1)
	check(game.run_presentation.bursts[0].age==age,"pause freezes impact effects")
	game.resume_local();stop()
	game.run_presentation.end_run();game.run_presentation._process(0.6)
	check(game.run_presentation.bursts.is_empty() and not game.run_presentation.running,"result effects expire and stop")
	for i in range(5):game.start_run(42);stop()
	check(game.run_presentation.get_child_count()==1,"retry reuses ambience voice")
	var profile: Dictionary=Profiles.profiles[Profiles.active_key]
	var wallet:=SaveData.coins;var skin:=SaveData.selected_character
	profile.presentation_options="bad";profile.records_v1["local/"+id]={"plays":NAN,"coins":-8,"time":"bad"}
	check(RunRecords.option("ambience") and RunRecords.read("local",id).coins==0,"corrupt scalar fields fall back")
	check(Profiles.save_active(),"old profile schema accepts additive fields")
	Profiles.load_profiles()
	check(SaveData.coins==wallet and SaveData.selected_character==skin,"reload preserves wallet and selected character")
	check(Profiles.best_time(id)==45 and RunRecords.read("local",id).time==45,"legacy best survives invalid optional records")
	game.show_menu()
	game.queue_free();await get_tree().process_frame;game=null
	print("RECORDS RESULTS: %d passed, %d failed"%[passed,failed]);get_tree().quit(failed)
