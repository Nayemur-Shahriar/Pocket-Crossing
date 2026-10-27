extends Node
const DEMO := preload("res://resources/examples/water_demo.tres")
var game: CrossingGame
var passed := 0
var failed := 0
func _ready() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print(("PASS " if ok else "FAIL ") + label)
func variant(count: int) -> LevelConfig:
	var level := DEMO.duplicate(false) as LevelConfig
	var water := LevelSectionConfig.new()
	water.kind = LevelSectionConfig.Kind.WATER_SECTION
	for i in range(count):
		water.water_lanes.append(DEMO.sections[2].water_lanes[i].duplicate(true))
	level.sections = [DEMO.sections[0],DEMO.sections[1],water,DEMO.sections[3],DEMO.sections[4]]
	return level
func clear_platforms(lane: WaterLane) -> void:
	for i in range(lane.platforms.size()):
		lane.platforms[i].travel = -10000.0-i*500
		lane.platforms[i].position.x = -10000.0-i*500 if lane.config.direction>0 else 10000.0+i*500
func deck_at(lane: WaterLane, x: float) -> FloatingPlatform:
	clear_platforms(lane)
	var deck := lane.platforms[0]
	deck.travel = x if lane.config.direction>0 else lane.width-x
	deck.position.x = x
	deck.motion_x = 0
	return deck
func position_player(row: int, x: float) -> void:
	var player := game.world.player
	player.cell = Vector2i(roundi((x-game.world.config.grid_origin.x)/64.0),row)
	player.position = Vector2(x,game.world.config.cell_position(player.cell).y)
	player.moving = false
	player.enabled = true
	player.visible = true
	player.invulnerable_left = 0
	game.world.water_support.clear_support()
func settle() -> void:
	for i in range(18):
		await get_tree().physics_frame
	await get_tree().process_frame
func run() -> void:
	var normal := {}
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = SaveData.PATH+suffix
		normal[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	game = load("res://tools/water_preview.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	check(game.state == CrossingGame.State.PLAYING and game.world.config.level_id == DEMO.level_id,"Direct water preview launch")
	check(SaveData.storage_path == "user://section_preview_profile.cfg","Preview save isolated")
	check(game.world.layout.total_rows == 7 and game.world.water_lanes.size()==3,"Three-lane demo fits static board")
	game.world.set_active(false)
	game.set_physics_process(false)
	for count in [1,2,3]:
		check(game.world.configure(variant(count)),"%d water lanes compile/load" % count)
		check(game.world.water_lanes.size()==count,"Lane count matches data")
		for lane in game.world.water_lanes:
			var original := lane.platforms.duplicate()
			var before := lane.platforms[3].position.x
			lane._physics_process(0.1)
			check(signf(lane.platforms[3].position.x-before)==lane.config.direction,"Platform moves in configured direction")
			var valid_gap := true
			var bounded_speed := true
			for i in range(7200):
				lane._physics_process(1.0/60.0)
				bounded_speed = bounded_speed and absf(lane.current_speed-lane.config.platform_speed)<=lane.config.platform_speed*lane.config.speed_variation+0.001
				if i%120==0:
					var positions: Array[float] = []
					for deck in lane.platforms: positions.append(deck.travel)
					positions.sort()
					for n in range(1,positions.size()):
						var gap := positions[n]-positions[n-1]-lane.config.platform_length
						valid_gap = valid_gap and gap>=lane.config.minimum_spacing-0.01 and gap<=96.01
			check(lane.platforms==original,"Pool identities unchanged after two minutes")
			check(valid_gap,"Recycling maintains bounded nonoverlapping spacing")
			check(bounded_speed,"Lane speed variation remains bounded")
	var invalid := WaterLaneConfig.new()
	invalid.platform_speed = NAN
	check(not invalid.validation_errors().is_empty(),"Nonfinite speed rejected")
	invalid = WaterLaneConfig.new()
	invalid.spawn_max = 12
	check(not invalid.validation_errors().is_empty(),"Unreasonably wide gaps rejected")
	invalid = WaterLaneConfig.new()
	invalid.platform_type = "unknown"
	check(not invalid.validation_errors().is_empty(),"Unknown platform type rejected")
	var slow_player := variant(3)
	slow_player.hop_seconds = 2
	check(not slow_player.playability_errors().is_empty(),"Unsafe hop/speed combination rejected")
	game.world.configure(DEMO)
	game.start_run(31)
	var first := game.world.water_lanes[0]
	var second := game.world.water_lanes[1]
	var third := game.world.water_lanes[2]
	var deck := deck_at(first,608)
	position_player(1,608)
	game.controls.direction_requested.emit(Vector2i(0,1))
	await settle()
	check(game.world.water_support.support==deck and game.world.player.cell.y==2,"Hop from bank lands on deck")
	var offset := game.world.player.position.x-deck.position.x
	var x := game.world.player.position.x
	await get_tree().create_timer(0.5).timeout
	check(game.world.player.position.x>x,"Platform carries idle player")
	check(absf(game.world.player.position.x-deck.position.x-offset)<0.01,"Riding offset stable without jitter")
	var lives := game.lives
	var target := deck_at(second,game.world.player.position.x)
	game.controls.direction_requested.emit(Vector2i(0,1))
	await settle()
	check(game.world.water_support.support==target and game.lives==lives,"Support transfers across opposite-direction lanes")
	check(not game.world.player.moving,"Hop completes normally")
	x = game.world.player.position.x
	await get_tree().create_timer(0.2).timeout
	check(game.world.player.position.x<x,"Westbound deck carries left")
	deck_at(third,game.world.player.position.x)
	game.controls.direction_requested.emit(Vector2i(0,1))
	await settle()
	check(game.world.player.cell.y==4 and game.world.water_support.support!=null,"Third-lane log supports player")
	game.controls.direction_requested.emit(Vector2i(0,1))
	await settle()
	x = game.world.player.position.x
	await get_tree().create_timer(0.2).timeout
	check(game.world.player.cell.y==5 and game.world.water_support.support==null and game.world.player.position.x==x,"Landing on bank stops carry")
	check(is_equal_approx(x,game.world.config.cell_position(game.world.player.cell).x),"Land restores grid alignment")
	deck = deck_at(first,608)
	position_player(2,608)
	game.world.water_support.check_landing()
	game.toggle_pause()
	var timer := game.time_left
	x = game.world.player.position.x
	var elapsed := first.elapsed
	await get_tree().create_timer(0.25).timeout
	check(game.world.player.position.x==x and first.elapsed==elapsed and game.time_left==timer,"Pause freezes rider, platforms and timer")
	game.toggle_pause()
	await settle()
	check(game.world.player.position.x>x and game.world.water_support.support==deck,"Resume preserves support")
	game.powers.activate(load("res://resources/powerups/slow.tres"))
	game._physics_process(0.01)
	check(first.current_speed>=first.config.platform_speed*0.94,"Slow Traffic does not slow water")
	game.powers.clear()
	# Water gap: resolve before scoring or buffered second hop.
	clear_platforms(first)
	position_player(1,608)
	game.furthest_row = 1
	var score := game.score
	game.controls.direction_requested.emit(Vector2i(0,1))
	game.controls.direction_requested.emit(Vector2i(0,1))
	await settle()
	check(game.lives==lives-1 and game.state==CrossingGame.State.RESPAWNING,"Unsupported landing loses one life")
	check(game.score==score and not game.world.player.visible,"Hazard precedes score and buffered hop")
	game._physics_process(2)
	check(game.state==CrossingGame.State.PLAYING and game.world.player.cell==game.world.config.spawn_cell and game.world.water_support.support==null,"Normal respawn detaches support")
	game.start_run(31)
	first = game.world.water_lanes[0]
	clear_platforms(first)
	position_player(1,608)
	game.powers.activate(load("res://resources/powerups/shield.tres"))
	game.controls.direction_requested.emit(Vector2i(0,1))
	await settle()
	check(game.lives==3 and not game.powers.active.has("shield") and game.world.player.cell==game.world.config.spawn_cell,"Shield consumes once and rescues to spawn")
	position_player(1,608)
	game.world.player.invulnerable_left = 1
	game.controls.direction_requested.emit(Vector2i(0,1))
	await settle()
	check(game.lives==3 and game.world.player.cell==game.world.config.spawn_cell,"Spawn protection rescues rather than leaving player on water")
	deck = deck_at(first,first.width + first.config.platform_length/2.0 - 19)
	position_player(2,deck.position.x)
	game.world.water_support.check_landing()
	await settle()
	check(game.lives==2 and game.state==CrossingGame.State.RESPAWNING,"Riding past right playable boundary loses life")
	game.start_run(31)
	second = game.world.water_lanes[1]
	deck = deck_at(second,-second.config.platform_length/2.0 + 19)
	position_player(3,deck.position.x)
	game.world.water_support.check_landing()
	await settle()
	check(game.lives==2,"Riding past left playable boundary loses life")
	var old_lane := game.world.water_lanes[0]
	var old_deck := old_lane.platforms[0]
	game.hud.retry_pressed.emit()
	await get_tree().process_frame
	check(not is_instance_valid(old_lane) and not is_instance_valid(old_deck),"Retry frees old lanes and platform pools")
	check(game.world.water_lanes.size()==3 and game.world.water_support.support==null and game.world.player.cell==game.world.config.spawn_cell,"Retry resets player, pools and support")
	check(game.world.water_lanes[0].elapsed<0.1,"Retry resets lane timers")
	game.world.set_active(false)
	var wallet := SaveData.coins
	game.powers.activate(load("res://resources/powerups/double.tres"))
	for cell in game.world.rewards.pickups.keys():
		check(cell.y not in [2,3,4],"Demo pickups are on safe land")
		if game.world.rewards.pickups[cell].kind=="coin":
			game._on_step_completed(cell)
			break
	check(SaveData.coins==wallet+2,"Coin multiplier still banks rewards")
	var catalog := LevelCatalog.new()
	catalog.levels = [DEMO,load("res://resources/examples/railway_demo.tres")]
	game.CAMPAIGN = catalog
	for column in game.world.config.goal_columns:
		game._set_state(CrossingGame.State.PLAYING)
		game._on_step_completed(Vector2i(column,game.world.config.goal_row))
	check(game.state==CrossingGame.State.LEVEL_COMPLETE,"Water level completes through destinations")
	SaveData.load_profile()
	check(SaveData.completed_levels.has(DEMO.level_id) and SaveData.level_stars.has(DEMO.level_id) and SaveData.level_scores.has(DEMO.level_id),"Completion, stars and score persist")
	game._on_primary()
	check(game.world.config.level_id=="example_railway_demo" and game.world.water_lanes.is_empty(),"Next Level transitions to railway cleanly")
	check(not game.world.player.hop_target.is_valid() and not game.world.player.landing_check.is_valid(),"Water adapters disabled on non-water levels")
	game.show_menu()
	check(game.state==CrossingGame.State.MENU,"Return to Level Select")
	game.select_level(0)
	check(game.world.water_lanes.size()==3 and game.world.water_support.support==null,"Re-enter water without duplicate pools")
	for path in normal:
		var data := FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
		check(data==normal[path],"Normal save/backup/temp unchanged")
	for voice in Audio.get_children():
		if voice is AudioStreamPlayer: voice.stop()
	game.queue_free()
	await get_tree().process_frame
	game = null
	await get_tree().create_timer(0.1).timeout
	print("WATER RESULTS: %d passed, %d failed" % [passed,failed])
	get_tree().quit.call_deferred(1 if failed else 0)
