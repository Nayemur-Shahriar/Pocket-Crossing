extends Node
## M14 lifecycle integration; isolated saves. Relocation is a test fixture, not a route proof.
var game: CrossingGame
var passed := 0
var failed := 0
var samples: Array[Dictionary] = []
var cycles := 0
func _ready() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error("FAIL " + label)
func settle(count: int = 3) -> void:
	for i in range(count): await get_tree().process_frame
func locate(row: int) -> void:
	var player := game.world.player
	player.moving = false
	player.clear_buffer()
	player.cell = Vector2i(8,row)
	player.position = game.world.config.cell_position(player.cell)
	game.world.camera.snap_to_player()
	game.world.activation.refresh(true)
func count_type(node: Node, script: Script) -> int:
	var count := int(node.get_script() == script)
	for child in node.get_children(): count += count_type(child,script)
	return count
func owners() -> void:
	for script in ["actors/player", "ui/game_hud", "world/level_camera", "presentation/world_presentation", "presentation/weather_effects", "world/section_activation"]:
		check(count_type(game,load("res://scripts/"+script+".gd"))==1,"Single owner: "+script)
	var world := game.world
	check(world.traffic.get_child_count()==world.lanes.size()+world.railways.size()+world.water_lanes.size(),"One spawner per configured lane/section")
	for railway in world.railways:
		for track in railway.tracks:
			check(count_type(track,load("res://scripts/actors/railway_train.gd"))==1,"One pooled train per track")
	for lane in world.water_lanes:
		check(lane.get_child_count()==lane.platforms.size(),"Water pool has no duplicate children")
func run() -> void:
	SaveData.storage_path = "user://m14_stress.cfg"
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SaveData.storage_path+suffix)
	SaveData.load_profile()
	SaveData.sound_enabled = false
	game = load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	for level in game.CAMPAIGN.levels: SaveData.completed_levels[level.level_id] = true
	game.select_level(14)
	# Ten consecutive real reset lifecycles on the longest mixed route.
	for retry in range(10):
		game.start_run(42)
		await settle()
		owners()
		check(game.score==0 and game.run_coins==0 and game.lives==3 and game.time_left>game.world.config.time_limit-1,"Retry resets counters")
		check(game.world.water_support.support==null and game.powers.active.is_empty(),"Retry clears support and powers")
		check(game.world.camera.position.y==game.world.camera.maximum_scroll,"Retry resets camera")
	# Same-frame duplicate contacts, repeated respawns, and shield consume/rescue.
	for kind in ["road","rail","water"]:
		game.start_run(42)
		for life in range(3):
			game.world.player.invulnerable_left = 0
			var before := game.lives
			for duplicate in range(4):
				if kind=="water": game._on_water_hazard(game.world.player)
				else: game._on_collision(game.world.player)
			check(game.lives==before-1,"Only one life per contact burst: "+kind)
			check(not game.controls.enabled and not game.world.player.enabled,"Death blocks input")
			if life<2:
				await get_tree().create_timer(game.world.config.hit_reset_seconds+0.15).timeout
				check(game.state==CrossingGame.State.PLAYING and game.world.player.visible,"Exactly one respawn: "+kind)
		check(game.state==CrossingGame.State.GAME_OVER and game.hud.result_panel.celebration==null,"Failure never celebrates")
		game.hud.result_panel.replay_button.pressed.emit()
		game.powers.activate(load("res://resources/powerups/shield.tres"))
		game.world.player.invulnerable_left = 0
		if kind=="water": game._on_water_hazard(game.world.player)
		else: game._on_collision(game.world.player)
		check(game.lives==3 and not game.powers.active.has("shield"),"Shield consumes once: "+kind)
		check(kind!="water" or game.world.player.cell==game.world.config.spawn_cell,"Shield water rescue")
		game._on_collision(game.world.player)
		check(game.lives==3,"Shield grace prevents repeat hit")
	# Actual streaming reentry into a frozen passing train gets a full new warning.
	game.start_run(42)
	game.set_physics_process(false)
	game.world.set_active(false)
	var section := game.world.railways[0]
	var track := section.tracks[0]
	var rail_row := roundi((game.world.config.grid_origin.y-track.position.y)/64)
	locate(rail_row)
	track.state = RailwayTrack.State.PASSING
	track.train.launch(1280)
	track.train.position.x = game.world.player.position.x
	locate(game.world.config.goal_row)
	check(not section.visible,"Rail leaves active window")
	locate(rail_row)
	check(track.state==RailwayTrack.State.WARNING and not track.train.running and track.remaining==track.config.warning_seconds,"Passing train reentry gets full warning")
	track.remaining = 0.01
	locate(game.world.config.goal_row)
	locate(rail_row)
	check(track.remaining==track.config.warning_seconds,"Expiring warning reentry gets full duration")
	track.state = RailwayTrack.State.SAFE
	track.remaining = 7.25
	locate(game.world.config.goal_row)
	locate(rail_row)
	check(track.state==RailwayTrack.State.SAFE and track.remaining==7.25,"Safe independent clock unchanged on reentry")
	# Pause retains time, world motion and all power durations.
	game.start_run(42)
	game.set_physics_process(true)
	for id in ["shield","slow","double"]: game.powers.activate(load("res://resources/powerups/"+id+".tres"))
	game.toggle_pause()
	var time_before := game.time_left
	var powers_before := game.powers.active.duplicate(true)
	var road_before := game.world.lanes[0].active_seconds
	await get_tree().create_timer(0.2).timeout
	check(game.time_left==time_before and game.powers.active==powers_before and game.world.lanes[0].active_seconds==road_before,"Pause freezes game, traffic and all effects")
	game.toggle_pause()
	await get_tree().create_timer(0.1).timeout
	check(game.time_left<time_before and game.powers.active.slow.left<powers_before.slow.left,"Resume continues effects")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.state==CrossingGame.State.PAUSED,"App background pauses")
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(game.state==CrossingGame.State.PAUSED,"App return waits for deliberate resume")
	game.toggle_pause()
	# Repeated transitions across all themes; no accumulated managers or result loops.
	var duration := 0.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--soak-seconds="): duration = float(arg.get_slice("=",1))
	var started := Time.get_ticks_msec()
	while cycles<18 or (Time.get_ticks_msec()-started)/1000.0<duration:
		var index: int = [0,4,6,9,11,14][cycles%6]
		game.select_level(index)
		await settle()
		owners()
		# Exercise retained activation in both directions with a hidden/disabled player.
		game.world.player.stop_and_hide()
		for row in [game.world.config.goal_row-1,0,game.world.config.goal_row/2,0]:
			locate(int(row))
			game.world.terrain.refresh()
			game.world.decorations.refresh(true)
			await settle(1)
		game.world.player.reset_to_spawn()
		var coin_cell := Vector2i(-1,-1)
		for cell: Vector2i in game.world.rewards.pickups:
			if game.world.rewards.pickups[cell].kind=="coin":
				coin_cell=cell
				break
		var wallet := SaveData.coins
		game._collect_reward(coin_cell)
		game._collect_reward(coin_cell)
		check(SaveData.coins==wallet+1,"No duplicate collection")
		if duration>0: await get_tree().create_timer(2.0).timeout
		game.toggle_pause()
		await settle()
		game.toggle_pause()
		game.score = int(SaveData.level_scores.get(game.world.config.level_id,0))+1000
		game.finish_game(true,"QA lifecycle fixture")
		check(game.hud.result_panel.celebration!=null,"Genuine new per-level score starts one celebration")
		check(count_type(game,load("res://scripts/ui/result_celebration.gd"))==1,"Single celebration loop")
		if duration>0: await get_tree().create_timer(1.0).timeout
		var effect := game.hud.result_panel.celebration
		match cycles%3:
			0: game.hud.result_panel.replay_button.pressed.emit()
			1: game.hud.result_panel.select_button.pressed.emit()
			2:
				if game.hud.result_panel.next_button!=null: game.hud.result_panel.next_button.pressed.emit()
				else: game.hud.result_panel.select_button.pressed.emit()
		check(effect.finished and effect.bursts.is_empty() and not effect.voice.playing,"Immediate result exit cleanup")
		game.show_menu()
		await settle()
		check(not game.world.presentation.visible and not game.world.decorations.ambience.playing,"No menu weather or ambience")
		check(count_type(game,load("res://scripts/ui/result_celebration.gd"))==0,"Result loop freed")
		SaveData.load_profile()
		SaveData.sound_enabled=false
		check(SaveData.coins==wallet+1,"Wallet survives reload")
		cycles += 1
		if cycles%6==0:
			# Compare identical retained worlds, not different campaign traffic pools.
			game.select_level(0)
			game.show_menu()
			await settle()
			var sample := {"seconds":(Time.get_ticks_msec()-started)/1000.0,"cycles":cycles,"nodes":get_tree().get_node_count(),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"static_bytes":OS.get_static_memory_usage()}
			samples.append(sample)
			print("SOAK_SAMPLE ",JSON.stringify(sample))
	if samples.size()>1:
		check(samples[-1].nodes<=samples[0].nodes+4,"Comparable menu node count bounded")
		check(samples[-1].orphans<=samples[0].orphans,"No orphan growth")
		check(samples[-1].static_bytes<=samples[0].static_bytes+8*1024*1024,"Static memory bounded within 8 MiB after warmup")
	var file := FileAccess.open("user://m14_soak_samples.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(samples,"\t"))
	file.close()
	for voice in Audio.voices: voice.stop()
	game.queue_free()
	await settle()
	await get_tree().create_timer(0.2).timeout
	print("QA STRESS RESULTS: %d passed, %d failed; cycles=%d; wall_seconds=%.2f" % [passed,failed,cycles,(Time.get_ticks_msec()-started)/1000.0])
	get_tree().quit(1 if failed else 0)
