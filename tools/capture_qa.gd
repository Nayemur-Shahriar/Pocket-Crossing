extends Node
## Linux rendered QA evidence; not a substitute for native Windows/phone testing.
var game: CrossingGame
var passed := 0
var failed := 0
var frames := 0
var largest := 0
var effect: ResultCelebration
func _ready() -> void: run.call_deferred()
func _process(_delta: float) -> void:
	frames += 1
	if is_instance_valid(effect): largest=maxi(largest,effect.bursts.size())
func check(ok: bool, message: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		push_error("FAIL "+message)
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/post_m14_regression_"+label+".png")
func run() -> void:
	SaveData.storage_path="user://m14_render.cfg"
	SaveData.load_profile()
	SaveData.sound_enabled=false
	game=load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	for level in game.CAMPAIGN.levels: SaveData.completed_levels[level.level_id]=true
	if OS.get_cmdline_user_args().has("--rail-only"):
		game.select_level(14)
		game.set_physics_process(false)
		game.world.set_active(false)
		var railway := game.world.railways[0]
		var track := railway.tracks[0]
		var row := roundi((game.world.config.grid_origin.y-track.position.y)/64)
		game.world.player.cell = Vector2i(8,row-1)
		game.world.player.position = game.world.config.cell_position(game.world.player.cell)
		game.world.camera.snap_to_player()
		game.world.activation.refresh(true)
		game.world.terrain.refresh()
		game.world.decorations.refresh(true)
		for preset in ["day","evening","night","rain","snow","fog"]:
			game.world.apply_theme(load("res://resources/themes/"+preset+".tres"))
			track.state = RailwayTrack.State.SAFE
			track.remaining = 0
			track.begin_warning()
			await get_tree().create_timer(0.2).timeout
			await shot("rail_warning_"+preset)
			track.state = RailwayTrack.State.PASSING
			track.train.launch(1280)
			track.train.position.x = 640
			track.signal_art.update_state(track.state,true)
			await get_tree().create_timer(0.2).timeout
			await shot("rail_passing_"+preset)
			track.train.park()
		game.queue_free()
		await get_tree().process_frame
		print("QA RAIL CAPTURES: 12 rendered screenshots")
		get_tree().quit()
		return
	for size: Vector2i in [Vector2i(1280,720),Vector2i(1366,768),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(1920,864),Vector2i(800,360)]:
		get_window().size=size
		game.show_menu()
		await get_tree().create_timer(0.25).timeout
		await shot("menu_%dx%d"%[size.x,size.y])
		var rect:=get_viewport().get_visible_rect()
		for button: Control in game.hud.direction_buttons.values():
			check(rect.encloses(button.get_global_rect()),"Logical touch target fits "+str(size))
			check(Rect2(Vector2.ZERO,Vector2(size)).encloses(get_viewport().get_screen_transform()*button.get_global_rect()),"Physical target fits "+str(size))
		game.select_level(14)
		await get_tree().create_timer(0.12).timeout
		game.toggle_pause()
		check(game.state==CrossingGame.State.PAUSED,"Pause modal state")
		await get_tree().create_timer(0.25).timeout
		await shot("pause_%dx%d"%[size.x,size.y])
		game.toggle_pause()
		game.score=10000
		game.finish_game(false,"QA failure")
		await shot("failure_%dx%d"%[size.x,size.y])
		check(game.hud.result_panel.get_global_rect().encloses(game.hud.result_panel.replay_button.get_global_rect()),"Failure button inside panel")
		game.show_menu()
		game.hud.show_characters()
		await get_tree().create_timer(0.08).timeout
		await shot("characters_%dx%d"%[size.x,size.y])
	get_window().size=Vector2i(1280,720)
	game.select_level(14)
	game.set_physics_process(false)
	game.world.player.stop_and_hide()
	var water:=game.world.water_lanes[0]
	game.world.player.cell=Vector2i(8,water.row-1)
	game.world.player.position=game.world.config.cell_position(game.world.player.cell)
	game.world.player.visible=true
	game.world.player.enabled=false
	game.world.camera.snap_to_player()
	game.world.activation.refresh(true)
	game.world.decorations.refresh(true)
	game.world.terrain.refresh()
	for name in ["day","evening","night","rain","snow","fog"]:
		game.world.apply_theme(load("res://resources/themes/"+name+".tres"))
		await get_tree().create_timer(0.6).timeout
		await shot("theme_"+name)
		check(game.world.presentation.get_child_count()==2,"Theme owner reused: "+name)
		print("RENDER_THEME ",name," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," particles=",game.world.presentation.weather.positions.size()," nodes=",get_tree().get_node_count())
	# Profile six representative levels: live scene motion, camera relocated by fixture.
	for index in [0,4,6,9,11,14]:
		game.select_level(index)
		game.world.player.enabled=false
		game.world.player.cell=Vector2i(8,game.world.config.goal_row/2)
		game.world.player.position=game.world.config.cell_position(game.world.player.cell)
		game.world.camera.snap_to_player()
		game.world.activation.refresh(true)
		game.world.terrain.refresh()
		await get_tree().create_timer(0.5).timeout
		var frame_times: Array[float]=[]
		var start:=Time.get_ticks_usec()
		var last:=start
		var calls:=0.0
		while Time.get_ticks_usec()-start<2000000:
			await get_tree().process_frame
			var now:=Time.get_ticks_usec()
			frame_times.append((now-last)/1000.0)
			last=now
			calls=maxf(calls,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		frame_times.sort()
		print("RENDER_PROFILE level=",index+1," frames=",frame_times.size()," p50_ms=",frame_times[frame_times.size()/2]," p95_ms=",frame_times[int(frame_times.size()*0.95)]," max_draw_calls=",calls," nodes=",get_tree().get_node_count()," active_sections=",game.world.activation.active_count()," total_entries=",game.world.activation.entries.size())
	if OS.get_cmdline_user_args().has("--ui-only"):
		game.queue_free()
		await get_tree().process_frame
		print("QA UI RENDER RESULTS: %d passed, %d failed"%[passed,failed])
		get_tree().quit(1 if failed else 0)
		return
	game.select_level(3)
	game.world.set_active(false)
	SaveData.level_scores[game.world.config.level_id]=1
	game.score=2000
	SaveData.sound_enabled=true
	game.hud.set_sound(true)
	game.finish_game(true,"QA record fixture")
	effect=game.hud.result_panel.celebration
	await get_tree().create_timer(1.0).timeout
	var begin:=Time.get_ticks_msec()
	var begin_frames:=frames
	var nodes:=get_tree().get_node_count()
	var memory:=OS.get_static_memory_usage()
	await shot("fireworks_start")
	for sample in range(4):
		await get_tree().create_timer(30.0).timeout
		print("FIREWORK_SAMPLE seconds=",(Time.get_ticks_msec()-begin)/1000.0," nodes=",get_tree().get_node_count()," memory=",OS.get_static_memory_usage()," bursts=",effect.emitted," sounds=",effect.sound_events," active=",effect.bursts.size())
		await shot("fireworks_%03d"%((sample+1)*30))
	check(effect.emitted>80 and effect.sound_events>0 and effect.sound_events<=effect.emitted and largest<=3,"Two-minute repeating bounded audiovisual triggers")
	check(get_tree().get_node_count()==nodes and OS.get_static_memory_usage()<memory+1024*1024,"Two-minute node/memory bound")
	print("FIREWORK_WALL seconds=",(Time.get_ticks_msec()-begin)/1000.0," frames=",frames-begin_frames," max_bursts=",largest," nodes=",nodes)
	game.hud.result_panel.replay_button.pressed.emit()
	check(effect.finished and effect.bursts.is_empty() and not effect.voice.playing,"Rendered Replay cleans effect immediately")
	effect=null
	await get_tree().process_frame
	await shot("fireworks_exit")
	for voice in Audio.voices: voice.stop()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	print("QA RENDER RESULTS: %d passed, %d failed"%[passed,failed])
	get_tree().quit(1 if failed else 0)
