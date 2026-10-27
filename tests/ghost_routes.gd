extends "res://tests/map_route_tests.gd"
var passed:=0
var failed:=0
func check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func run() -> void:
	Profiles.storage_path="user://m149_ghost_routes.cfg";SaveData.storage_path="user://m149_ghost_old.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Ghost_Routes");SaveData.coins=1000;SaveData.sound_enabled=false
	var mode:=game as ModeGame
	for i in range(4):
		var map:=mode.CAMPAIGN.levels[i] as MapConfig
		Profiles.purchase(map);mode.select_level(i);mode.start_run(42)
		for frame in range(240*60):
			if mode.state in [CrossingGame.State.LEVEL_COMPLETE,CrossingGame.State.GAME_OVER]:break
			choose_hop();await get_tree().physics_frame
		check(mode.state==CrossingGame.State.LEVEL_COMPLETE,"five crossings "+map.level_id)
		check(mode.get("ghost")==null,"no replay runtime")
		check(Profiles.best_time(map.level_id)>0,"Best Time saved after real route")
		check(RunRecords.read("local",map.level_id).completions==1,"one real completion")
		print("REMOVAL ROUTE ",map.level_id," seconds=",mode.elapsed_seconds)
		mode.set_physics_process(true)
	game.queue_free();await get_tree().process_frame;game=null
	print("REMOVAL ROUTE RESULTS: %d passed, %d failed"%[passed,failed]);get_tree().quit(failed)
