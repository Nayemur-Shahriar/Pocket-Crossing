extends Node
const DEMO := preload("res://resources/examples/long_crossing_demo.tres")
var game: CrossingGame
var passed := 0
var failed := 0

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print(("PASS " if ok else "FAIL ") + label)

func frames(count: int = 5) -> void:
	for i in range(count):
		await get_tree().physics_frame
	await get_tree().process_frame

func relocate(row: int, column: int = 8) -> void:
	var player := game.world.player
	player.stop_and_hide()
	player.cell = Vector2i(column, row)
	player.position = game.world.config.cell_position(player.cell)
	player.visible = true
	player.enabled = true
	player.invulnerable_left = 0
	game.world.camera.advance(1.0)
	game.world.activation.refresh(true)
	game.world.terrain.refresh()

func safe_level(rows: int) -> LevelConfig:
	var config := DEMO.duplicate(false) as LevelConfig
	var safe := LevelSectionConfig.new()
	safe.safe_rows = mini(512, rows - 2)
	config.sections = [DEMO.sections[0]]
	var remaining := rows - 2
	while remaining > 0:
		var band := safe.duplicate() as LevelSectionConfig
		band.safe_rows = mini(512, remaining)
		config.sections.append(band)
		remaining -= band.safe_rows
	config.sections.append(DEMO.sections[-1])
	return config

func run() -> void:
	var normal := {}
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = SaveData.PATH + suffix
		normal[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	game = load("res://tools/long_level_preview.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	SaveData.sound_enabled = false
	check(game.state == CrossingGame.State.PLAYING and game.world.config.level_id == DEMO.level_id, "Long preview starts directly")
	check(SaveData.storage_path == "user://section_preview_profile.cfg", "Long preview uses isolated profile")
	var world := game.world
	check(world.layout.total_rows == 24 and world.config.goal_row == 23, "24 ordered rows compiled without screen-height limit")
	check(world.lanes.size() == 12 and world.railways[0].tracks.size() == 2 and world.water_lanes.size() == 3, "Existing road/rail/water factories reused")
	var next_row := 0
	for band in world.layout.sections:
		check(band.first_row == next_row, "Section starts at deterministic row %d" % next_row)
		next_row += band.row_count
	check(next_row == 24, "Sections cover world without overlaps or gaps")
	for lane in world.lanes:
		check(lane.position.y == world.config.cell_position(Vector2i(0,lane.config.row)).y, "Road world position row %d" % lane.config.row)
	check(world.railways[0].tracks[0].position.y == world.config.cell_position(Vector2i(0,8)).y, "Railway at world row eight")
	check(world.water_lanes[0].position.y == world.config.cell_position(Vector2i(0,14)).y, "Water at world row fourteen")
	check(world.goals[8].position.y == world.config.cell_position(Vector2i(8,23)).y, "Destination at final world row")
	for length in [8,17,64,1024]:
		var config := safe_level(length)
		check(config.playability_errors().is_empty() and config.compile_layout().total_rows == length, "%d-row layout valid/playable" % length)
	var bad := DEMO.duplicate(false) as LevelConfig
	bad.sections = [DEMO.sections[0],DEMO.sections[0],DEMO.sections[-1]]
	check(not bad.validation_errors().is_empty(), "Malformed section order still rejected")
	check(world.camera.position == Vector2.ZERO, "Start framing unchanged")
	check(world.activation.active_count() < world.activation.entries.size(), "Far world components inactive at Start")
	var far_lane := world.water_lanes[0]
	var deck := far_lane.platforms[0]
	var deck_x := deck.position.x
	await frames()
	check(far_lane.elapsed == 0 and deck.position.x == deck_x and not far_lane.visible, "Far water timer and platform pool frozen/hidden")
	var hud_position := game.hud.root.get_global_transform_with_canvas()
	relocate(7)
	var camera_y := world.camera.position.y
	check(camera_y < 0 and world.camera.position.x == 0, "Camera advances vertically with stable horizontal framing")
	check(is_equal_approx(world.player.get_global_transform_with_canvas().origin.y, world.player.position.y - camera_y), "Camera transform applies to player world position")
	relocate(6)
	check(is_equal_approx(world.camera.position.y,camera_y), "One backward row remains inside dead zone")
	relocate(0)
	check(world.camera.position.y > camera_y and world.player.get_global_transform_with_canvas().origin.y <= 584, "Larger backtracking reveals player before footer")
	world.player.reset_to_spawn()
	check(world.camera.position == Vector2.ZERO, "Respawn snaps camera to Start immediately")
	relocate(22)
	check(world.camera.position.y >= world.camera.minimum_scroll and world.camera.position.y <= world.camera.maximum_scroll, "Camera clamped at destination end")
	check(world.camera.position.y + LevelCamera.PLAY_TOP >= world.config.cell_position(Vector2i(0,23)).y - 84.0, "No empty space beyond destination garden")
	check(game.hud.root.get_global_transform_with_canvas() == hud_position, "HUD transform independent of camera")
	check(not game.hud.destination_label.visible and game.hud.bays_label.position.y == 684, "Long-route destination counter stays in footer")
	for button: Control in game.hud.direction_buttons.values():
		check(get_viewport().get_visible_rect().encloses(button.get_global_rect()), "Touch button remains screen-space and visible")
	var first_lane := world.lanes[0]
	var first_vehicle := first_lane.get_child(0) as TrafficVehicle
	var lane_clock := first_lane.active_seconds
	var vehicle_x := first_vehicle.position.x
	await frames()
	check(not first_lane.can_process() and not first_lane.visible, "Distant passed road deactivated")
	check(first_lane.active_seconds == lane_clock and first_vehicle.position.x == vehicle_x, "Inactive road and child vehicle clocks freeze")
	relocate(0)
	await frames()
	check(first_lane.can_process() and first_lane.visible and first_lane.active_seconds > lane_clock, "Backtracking resumes same road nodes")
	check(first_vehicle == first_lane.get_child(0), "Reactivation preserves vehicle identity")
	# Railway warning clock survives leaving the useful window and returning.
	relocate(7)
	var railway := world.railways[0]
	var track := railway.tracks[0]
	track.remaining = 0
	track.begin_warning()
	var warning_left := track.remaining
	relocate(22)
	await frames()
	check(track.remaining == warning_left and track.state == RailwayTrack.State.WARNING, "Inactive railway retains warning without ticking or spawning")
	relocate(7)
	await frames()
	check(track.remaining < warning_left and track.state == RailwayTrack.State.WARNING, "Reactivated railway resumes its remaining warning")
	# Pause freezes camera, hazards, and player; resume retains the same state.
	game.toggle_pause()
	var paused_camera := world.camera.position
	var paused_warning := track.remaining
	var paused_time := game.time_left
	await frames()
	check(world.camera.position == paused_camera and track.remaining == paused_warning and game.time_left == paused_time, "Pause freezes camera, train warning and game clock")
	game.toggle_pause()
	await frames()
	check(track.remaining < paused_warning, "Resume continues warning normally")
	# Train Area2D interactions still use the shield/life pipeline in a scrolled world.
	track.state = RailwayTrack.State.PASSING
	track.train.launch(track.width)
	relocate(8)
	track.train.position.x = world.player.position.x
	game.powers.activate(load("res://resources/powerups/shield.tres"))
	await frames()
	check(game.lives == 3 and not game.powers.active.has("shield"), "Scrolled train collision consumes shield once")
	relocate(7)
	await frames()
	relocate(8)
	world.player.position.x = track.train.position.x
	await frames()
	check(game.lives == 2 and game.state == CrossingGame.State.RESPAWNING, "Scrolled train collision uses existing life loss")
	game.start_run(42)
	far_lane = world.water_lanes[0]
	deck = far_lane.platforms[0]
	# Reenter long-world water, then exercise actual moving-platform support.
	relocate(13)
	await frames()
	check(far_lane.can_process() and far_lane.platforms[0] == deck and far_lane.elapsed > 0, "Water pool resumes unchanged near player")
	var riding: FloatingPlatform
	for candidate in far_lane.platforms:
		if candidate.position.x > 350 and candidate.position.x < 950:
			riding = candidate
			break
	check(riding != null, "Visible support available on long-world water")
	if riding != null:
		relocate(14)
		world.player.position.x = riding.position.x
		check(world.water_support.check_landing(), "Support resolves at long-world row")
		var before_x := world.player.position.x
		await frames()
		check(world.player.position.x > before_x and world.water_support.support == riding, "Platform carries player while camera scrolled")
	game.powers.activate(load("res://resources/powerups/shield.tres"))
	game._on_water_hazard(world.player)
	check(game.lives == 3 and world.player.cell == world.config.spawn_cell and world.camera.position == Vector2.ZERO, "Water shield rescue retains lives and resets camera/activation")
	relocate(14)
	world.player.position.x = -10000 # No platform support; crossing a grid-center bound alone is now safe.
	world.water_support.check_landing()
	check(game.lives == 2 and game.state == CrossingGame.State.RESPAWNING, "Long-water fall routes through normal life loss")
	game._physics_process(world.config.hit_reset_seconds + 0.1)
	check(world.camera.position == Vector2.ZERO, "Water death resets camera on respawn")
	game.start_run(42)
	# Actual road Area2D contact while far from Start uses original life-loss flow.
	relocate(20)
	var road: TrafficLane
	for lane in world.lanes:
		if lane.config.row == 20:
			road = lane
	var vehicle := road.get_child(0) as TrafficVehicle
	vehicle.position.x = world.player.position.x
	await frames()
	check(game.lives == 2 and game.state == CrossingGame.State.RESPAWNING, "Real scrolled road collision costs exactly one life")
	game._physics_process(world.config.hit_reset_seconds + 0.1)
	check(world.player.cell == world.config.spawn_cell and world.camera.position == Vector2.ZERO, "Death respawn returns world camera to Start")
	# Collected pickups do not respawn by deactivating/reactivating a section.
	var coin_cell := Vector2i(-1,-1)
	for key: Vector2i in world.rewards.pickups:
		if key.y > 7 and world.rewards.pickups[key].kind == "coin":
			coin_cell = key
			break
	check(coin_cell.y > 7, "Coins distributed beyond first screen")
	if coin_cell.y > 7:
		relocate(coin_cell.y,coin_cell.x)
		var coins := SaveData.coins
		game._collect_reward(coin_cell)
		await frames(24) # The collected icon is now freed; registry must tolerate it.
		relocate(0)
		relocate(coin_cell.y,coin_cell.x)
		check(SaveData.coins == coins + 1 and not world.rewards.pickups.has(coin_cell), "Coin remains collected after streaming round trip")
	game.start_run(42)
	check(game.score == 0 and game.lives == 3 and world.camera.position == Vector2.ZERO, "Retry resets gameplay and camera")
	check(world.railways[0].tracks[0].state == RailwayTrack.State.SAFE and world.water_lanes[0].elapsed == 0, "Retry rebuilds original hazard state")
	# Real hops on a long safe route exercise end-to-end camera and destination flow.
	check(world.configure(safe_level(24)), "Long safe route loads")
	game.start_run(42)
	for row in range(1,24):
		game._on_direction(Vector2i(0,1))
		await frames(10)
		check(world.player.cell.y == row, "Real forward hop reaches row %d" % row)
		var screen_y := world.player.get_global_transform_with_canvas().origin.y
		check(screen_y >= 140 and screen_y <= 584, "Player stays inside useful viewport at row %d" % row)
	check(game.state == CrossingGame.State.LEVEL_COMPLETE, "Long route completes through existing destination logic")
	SaveData.load_profile()
	check(SaveData.level_stars.has(DEMO.level_id) and SaveData.level_scores.has(DEMO.level_id), "Long route stars/high score saved by stable ID")
	game.start_run(42)
	check(world.camera.position == Vector2.ZERO and game.state == CrossingGame.State.PLAYING, "Retry after completion returns to Start")
	var two_bays := safe_level(24)
	two_bays.sections[-1] = two_bays.sections[-1].duplicate() as LevelSectionConfig
	two_bays.sections[-1].destination_columns = [6,8]
	world.configure(two_bays)
	game.start_run(42)
	relocate(23,6)
	game._on_step_completed(world.player.cell)
	check(game.state == CrossingGame.State.LEVEL_COMPLETE and world.goals[6].occupied, "First alternative bay completes long route")
	game.start_run(42)
	check(world.player.cell == world.config.spawn_cell and world.camera.position == Vector2.ZERO, "Replay restarts camera at Start")
	relocate(23,8)
	game._on_step_completed(world.player.cell)
	check(game.state == CrossingGame.State.LEVEL_COMPLETE and world.goals[8].occupied and not world.goals[6].occupied, "Other bay independently completes replay")
	for original: LevelConfig in load("res://tests/fixtures/legacy_campaign.tres").levels:
		check(world.configure(original), "Campaign still loads: " + original.display_name)
		check(world.camera.position == Vector2.ZERO and not world.activation.streaming, "Original level keeps fixed framing/full activity: " + original.display_name)
	for path: String in normal:
		var current := FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
		check(current == normal[path], "Normal profile/backup/temp untouched")
	game.queue_free()
	await get_tree().process_frame
	print("LONG LEVEL RESULTS: %d passed, %d failed" % [passed,failed])
	get_tree().quit(1 if failed else 0)
