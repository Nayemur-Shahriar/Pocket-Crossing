extends Node
var game: ModeGame
var prefix := ""
func shot(label: String) -> void:
	await get_tree().create_timer(.28).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/polish_screenshots/"+prefix+label+".png")
func _ready() -> void:
	Profiles.storage_path="user://polish_visual.cfg"
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Crossing_Tester");SaveData.coins=1000;SaveData.sound_enabled=false
	DirAccess.make_dir_recursive_absolute("res://docs/polish_screenshots")
	for dims in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2340,1080),Vector2i(960,540),Vector2i(640,360)]:
		get_window().size=dims;prefix="%dx%d_"%[dims.x,dims.y]
		game.ui.mode_menu();await shot("home")
		game.ui.settings_screen();await shot("settings")
		game.show_menu();await shot("maps")
		var rows: Array=[]
		for i in range(4):rows.append({"peer":i+1,"rank":i+1,"name":"LongPlayerName16" if i==0 else "Player_"+str(i),"safe":5 if i<2 else 4,"coins":20,"deaths":2,"time":65.23+i,"score":1200-i*30,"status":"finished" if i<2 else "time_up","timed_out":i>=2})
		game.ui.race_results(rows,true,"Results saved","score",[],0);await shot("results")
	get_window().size=Vector2i(1280,720);prefix="1280x720_"
	for map in game.CAMPAIGN.levels:Profiles.purchase(map)
	game.ui.show_characters();await shot("characters")
	game.ui.friends_menu();await shot("friends")
	game.ui.join_screen();await shot("join")
	game.ui.manual_screen();await shot("manual")
	game.ui.local_pause();await shot("pause")
	game.ui.confirmation("EXIT POCKET CROSSING?","Your saved progress will be kept.","EXIT");await shot("exit");game.ui.close_confirmation()
	game.session.members={1:{"name":"HostPlayer", "ready":true},2:{"name":"LongPlayerName16","ready":true}}
	game.ui.lobby(game.session);await shot("lobby");game.session.members.clear()
	game.select_level(0);game.start_run(42)
	await shot("gameplay")
	game.set_physics_process(false);game.world.set_active(false)
	game.ui.show_map_result(false,71,65,20,3,false);await shot("failure")
	game.ui.show_map_result(true,60,60,25,5,true);await shot("complete")
	game.ui.mode_menu();game.ui.set_process(false);game.ui.apply_control_safe_area(Rect2(70,25,1140,660));game.ui.overlay.modulate.a=1;await shot("safe_area")
	game.ui.set_process(true)
	game.ui.navigate(func():game.show_menu())
	await get_tree().create_timer(.19).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/polish_screenshots/transition.png")
	await get_tree().create_timer(.6).timeout
	game.queue_free();await get_tree().process_frame;get_tree().quit()
