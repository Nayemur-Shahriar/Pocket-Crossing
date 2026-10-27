extends Node
var game: ModeGame
func shot(label: String) -> void:
	for i in range(4):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/m148_screenshots")
	print("CAPTURE ",label," ",get_viewport().get_texture().get_image().get_size())
	get_viewport().get_texture().get_image().save_png("res://docs/m148_screenshots/"+label+".png")
func _ready() -> void:
	Profiles.storage_path="user://depth_visual.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Crossing_Tester");SaveData.coins=1000;SaveData.sound_enabled=false
	for map in game.CAMPAIGN.levels:Profiles.purchase(map)
	game.ui.mode_menu();await shot("home")
	game._action("local","");await shot("maps")
	game._action("challenges","");await shot("challenges")
	for i in range(4):
		game.select_level(i);game.start_run(42)
		await get_tree().create_timer(3).timeout
		await shot("map_"+str(i))
	game.select_challenge(3,"heavy_fog")
	await get_tree().create_timer(3).timeout
	await shot("night_fog")
	game.select_challenge(0,"double_coins")
	game.elapsed_seconds=50;game.destinations_reached=5;game.finish_game(true,"")
	await shot("challenge_result")
	get_window().size=Vector2i(800,360);await get_tree().process_frame
	game._action("challenges","");await shot("challenges_800x360")
	game._action("local","");await shot("maps_800x360")
	game.select_challenge(0,"heavy_fog")
	var max_nodes:=0;var samples: Array[float]=[]
	for i in range(180):
		await get_tree().process_frame
		max_nodes=maxi(max_nodes,int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		samples.append(get_process_delta_time()*1000)
	samples.sort();print("RENDER PERF 180 frames median_ms=",samples[90]," p95_ms=",samples[171]," peak_nodes=",max_nodes)
	game.leave_friends();game.queue_free();await get_tree().process_frame;await get_tree().process_frame
	print("DEPTH VISUAL RESULTS: capture and cleanup complete");get_tree().quit()
