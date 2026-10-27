extends Node
## Integration checks against real Godot nodes, physics, and input dispatch.
## Run after importing: godot --headless --path . tests/test_runner.tscn

var game: CrossingGame
var passed: int = 0
var failed: int = 0
var profile: Node
var previous_profile: Dictionary

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS  ", label)
	else:
		failed += 1
		push_error("FAIL  " + label)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _run() -> void:
	profile = get_tree().root.get_node("SaveData")
	previous_profile = {"path": profile.storage_path, "best": profile.best_score, "sound": profile.sound_enabled}
	profile.storage_path = "user://integration_test_profile.cfg"
	profile.best_score = 0
	profile.sound_enabled = false
	game = load("res://scenes/legacy_main.tscn").instantiate() as CrossingGame
	get_tree().root.add_child(game)
	await get_tree().process_frame
	check(game.state == CrossingGame.State.MENU, "Main menu is the initial screen")
	game.start_run(42)
	check(game.lives == 3 and game.time_left == 90.0 and game.score == 0, "Fresh run has 3 lives, 90 seconds, and zero score")
	check(game.world.lanes.size() == 4, "Four traffic lanes are instantiated")
	check(game.world.lanes[0].config.direction == 1 and game.world.lanes[1].config.direction == -1 and game.world.lanes[2].config.direction == 1 and game.world.lanes[3].config.direction == -1, "Traffic alternates direction")
	await wait(0.1) # Let initial physics processing start before sampling motion.
	var vehicle := game.world.lanes[0].get_child(0) as TrafficVehicle
	var left_vehicle := game.world.lanes[1].get_child(0) as TrafficVehicle
	var x := vehicle.position.x
	var left_x := left_vehicle.position.x
	await wait(0.12)
	check(vehicle.position.x > x and left_vehicle.position.x < left_x, "Vehicles physically move in both directions")
	game.toggle_pause()
	var paused_time := game.time_left
	x = vehicle.position.x
	await wait(0.12)
	check(game.time_left == paused_time and vehicle.position.x == x, "Pause freezes both timer and traffic")
	game.toggle_pause()
	await wait(0.05)
	check(game.time_left < paused_time, "Resume restarts the timer")
	await disable_hazards()
	var spawn := game.world.player.cell
	send_key(KEY_D, true)
	await wait(0.17)
	send_key(KEY_D, false)
	check(game.world.player.cell == spawn + Vector2i(1, 0), "D key makes exactly one right hop")
	send_key(KEY_LEFT, true)
	await wait(0.17)
	send_key(KEY_LEFT, false)
	check(game.world.player.cell == spawn, "Arrow key returns to the starting column")
	warp(Vector2i(0, 0))
	game.world.player.request_step(Vector2i(-1, 0))
	await wait(0.17)
	check(game.world.player.cell == Vector2i(0, 0), "Left boundary prevents leaving the board")
	game.world.player.request_step(Vector2i(0, -1))
	check(game.world.player.cell == Vector2i(0, 0), "Bottom boundary prevents leaving the board")
	warp(spawn)
	game.world.player.request_step(Vector2i(0, 1))
	await wait(0.17)
	check(game.score == 10, "New forward row awards ten points")
	game.world.player.request_step(Vector2i(0, -1))
	await wait(0.17)
	game.world.player.request_step(Vector2i(0, 1))
	await wait(0.17)
	check(game.score == 10, "Back-and-forth hopping cannot farm points")
	warp(Vector2i(8, 5))
	game.world.player.request_step(Vector2i(0, 1))
	check(game.world.player.cell.y == 5, "Top edge only admits empty destination columns")
	# A real Area2D / CharacterBody2D overlap must consume one life only.
	game.start_run(42)
	game.world.player.invulnerable_left = 0.0
	warp(Vector2i(8, 1))
	vehicle = game.world.lanes[0].get_child(0) as TrafficVehicle
	vehicle.speed = 0.0
	vehicle.position.x = game.world.player.position.x
	await wait(0.1)
	check(game.lives == 2 and game.state == CrossingGame.State.RESPAWNING, "Physics collision consumes one life and enters respawn")
	await wait(0.15)
	check(game.lives == 2, "Repeated collision during respawn does not consume extra lives")
	game.toggle_pause()
	var respawn_time := game._respawn_left
	await wait(0.15)
	check(game._respawn_left == respawn_time, "Pausing also freezes the respawn delay")
	game.toggle_pause()
	await wait(0.85)
	check(game.world.player.visible and game.world.player.cell == spawn and game.state == CrossingGame.State.PLAYING, "Respawn returns the visible player to the safe sidewalk")
	check(game.world.player.invulnerable_left > 0.0, "Respawn grants brief collision protection")
	game._on_collision(game.world.player)
	check(game.lives == 2, "Spawn protection rejects damage")
	game.world.player.invulnerable_left = 0.0
	game._on_collision(game.world.player)
	await wait(0.96)
	game.world.player.invulnerable_left = 0.0
	warp(Vector2i(8, 1))
	vehicle.position.x = game.world.player.position.x
	await wait(0.1)
	check(game.lives == 0 and game.state == CrossingGame.State.GAME_OVER, "Third life lost through real physics opens the game-over screen")
	game.start_run(42)
	game.time_left = 0.02
	await wait(0.08)
	check(game.state == CrossingGame.State.GAME_OVER and game.lives == 3, "Time expiry ends the run independently of lives")
	# Real event dispatch: a long swipe is one hop, with no emulated-mouse duplicate.
	game.start_run(42)
	await disable_hazards()
	send_touch(Vector2(610, 580), true)
	send_drag(Vector2(610, 535))
	send_drag(Vector2(610, 410))
	send_touch(Vector2(610, 410), false)
	await wait(0.22)
	check(game.world.player.cell == spawn + Vector2i(0, 1), "One long touch swipe creates exactly one upward hop")
	warp(spawn)
	send_touch(Vector2(610, 580), true)
	send_drag(Vector2(610, 535))
	send_touch(Vector2(80, 582), false)
	await wait(0.18)
	send_touch(Vector2(610, 580), true)
	send_drag(Vector2(610, 535))
	send_touch(Vector2(610, 535), false)
	await wait(0.18)
	check(game.world.player.cell == spawn + Vector2i(0, 2), "Ending a swipe over the UI does not lock later gestures")
	warp(spawn)
	# Pointer events exercise the exact shared button path used by touch emulation.
	send_mouse(Vector2(80, 582), true)
	await wait(0.16)
	send_mouse(Vector2(80, 582), false)
	await wait(0.03)
	check(game.world.player.cell == spawn + Vector2i(0, 1), "On-screen up button moves the player")
	warp(spawn)
	send_mouse(Vector2(80, 582), true)
	await wait(0.50)
	send_mouse(Vector2(80, 582), false)
	await wait(0.20)
	check(game.world.player.cell.y >= 2, "Holding a direction button repeats hops")
	var stopped_cell := game.world.player.cell
	await wait(0.3)
	check(game.world.player.cell == stopped_cell, "Releasing the direction button stops repeating")
	await polish_checks()
	await mobile_control_checks()
	# Complete each alternative destination in a separate run through real movement.
	game.start_run(42)
	await disable_hazards()
	for column in game.world.config.goal_columns:
		game.start_run(42)
		await disable_hazards()
		warp(Vector2i(column, 5))
		game.furthest_row = 5
		game.world.player.request_step(Vector2i(0, 1))
		await wait(0.18)
		check(game.world.goals[column].occupied, "Destination %d changes to its reached state" % column)
		check(not game.world.claim_destination(column), "Destination %d cannot be scored twice" % column)
		if game.state != CrossingGame.State.LEVEL_COMPLETE:
			await wait(0.72)
	check(game.destinations_reached == 1 and game.state == CrossingGame.State.LEVEL_COMPLETE, "Any destination opens the level-complete screen")
	check(game.score > 440 and profile.best_score == game.score, "Completion adds time/life bonuses and persists the best score")
	var final_score := game.score
	game.finish_game(true, "duplicate")
	check(game.score == final_score, "Terminal state cannot award a second completion bonus")
	paused_time = game.time_left
	await wait(0.1)
	check(game.time_left == paused_time, "Completed level freezes the timer")
	game.start_run(42)
	check(game.score == 0 and game.destinations_reached == 0 and game.lives == 3 and not game.world.goals[2].occupied, "Replay resets score, lives, and all destination states")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.state == CrossingGame.State.PAUSED, "Losing application focus automatically pauses")
	check(not get_tree().quit_on_go_back, "Android Back does not use the automatic quit behavior")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.state == CrossingGame.State.PLAYING, "Android Back notification resumes a paused run")
	var stored := ConfigFile.new()
	check(stored.load(profile.storage_path) == OK and int(stored.get_value("profile", "best_score", 0)) == final_score, "Best score is readable from the saved profile")
	profile.storage_path = previous_profile.path
	profile.best_score = previous_profile.best
	profile.sound_enabled = previous_profile.sound
	DirAccess.remove_absolute("user://integration_test_profile.cfg")
	game.queue_free()
	await get_tree().process_frame
	print("\nRESULT: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func disable_hazards() -> void:
	game.world.traffic.process_mode = Node.PROCESS_MODE_DISABLED
	for lane in game.world.lanes:
		for vehicle in lane.get_children():
			vehicle.set_deferred("monitoring", false)
	await get_tree().physics_frame
	await get_tree().physics_frame

func warp(cell: Vector2i) -> void:
	game.world.player.moving = false
	game.world.player.clear_buffer()
	game.world.player.cell = cell
	game.world.player.position = game.world.config.cell_position(cell)

func send_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)

func send_touch(position: Vector2, pressed: bool, finger: int = 0, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.canceled = canceled
	event.position = position
	event.pressed = pressed
	get_viewport().push_input(event, true)

func send_drag(position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = position
	get_viewport().push_input(event, true)

func send_mouse(position: Vector2, pressed: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	Input.parse_input_event(motion)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.global_position = position
	event.pressed = pressed
	get_viewport().push_input(event, true)

func mobile_control_checks() -> void:
	game.start_run(42)
	await disable_hazards()
	var center := Vector2i(8, 3)
	var directions: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]
	for direction in directions:
		warp(center)
		var button: Control = game.hud.direction_buttons[direction]
		var point := button.get_global_rect().get_center()
		send_touch(point, true, 3)
		send_touch(point, false, 3)
		await wait(0.18)
		check(game.world.player.cell == center + direction, "Native touch tap maps to %s exactly once" % direction)
	for direction in directions:
		warp(center)
		var origin := Vector2(640, 400)
		var end := origin + Vector2(direction.x, -direction.y) * 90
		send_touch(origin, true)
		send_drag(end)
		send_drag(end + (end - origin))
		send_touch(end, false)
		await wait(0.18)
		check(game.world.player.cell == center + direction, "Swipe maps to %s exactly once" % direction)
	warp(center)
	send_touch(Vector2(640, 400), true)
	send_drag(Vector2(650, 408))
	send_touch(Vector2(650, 408), false)
	await wait(0.18)
	check(game.world.player.cell == center, "Small accidental swipe ignored")
	send_touch(Vector2(640, 680), true)
	send_drag(Vector2(640, 600))
	send_touch(Vector2(640, 600), false)
	await wait(0.18)
	check(game.world.player.cell == center, "Footer does not start swipe")
	var up: Control = game.hud.direction_buttons[Vector2i(0, 1)]
	var right: Control = game.hud.direction_buttons[Vector2i(1, 0)]
	var up_point := up.get_global_rect().get_center()
	var right_point := right.get_global_rect().get_center()
	send_touch(up_point, true)
	send_drag(Vector2(400, 400))
	send_touch(Vector2(400, 400), false)
	await wait(0.18)
	check(game.world.player.cell == center + Vector2i(0, 1), "Dragging off a button creates no extra swipe")
	await wait(0.3)
	check(game.controls._held_touch == Vector2i.ZERO, "Release outside button clears hold")
	warp(center)
	send_touch(up_point, true, 4)
	await wait(0.18)
	send_touch(right_point, true, 5)
	await wait(0.18)
	send_touch(up_point, false, 4)
	check(game.controls._held_touch == Vector2i(1, 0), "Releasing older thumb preserves newest thumb")
	send_touch(right_point, false, 5)
	check(game.controls._held_touch == Vector2i.ZERO, "Both thumbs released clears hold")
	warp(center)
	send_touch(up_point, true, 4)
	await wait(0.18)
	send_touch(right_point, true, 5)
	await wait(0.18)
	var before_release := game.world.player.cell
	send_touch(right_point, false, 5)
	check(game.controls._held_touch == Vector2i(0, 1), "Releasing newest thumb restores older hold")
	check(game.world.player.cell == before_release, "Restoring hold does not inject a new hop")
	send_touch(up_point, false, 4, true)
	check(game.controls._held_touch == Vector2i.ZERO, "Canceled touch clears hold")
	send_touch(up_point, true, 4)
	game.toggle_pause()
	check(game.controls._held_touch == Vector2i.ZERO and game.hud._held_buttons.is_empty(), "Pause clears all button and gesture ownership")
	send_touch(up_point, false, 4)
	game.toggle_pause()
	await wait(0.18)
	game.controls.set_control_mode(InputRouter.ControlMode.SWIPE)
	check(not game.hud.split_controls.visible, "Swipe mode hides split buttons")
	warp(center)
	game.controls.set_touch_direction(Vector2i(1, 0))
	check(game.world.player.cell == center, "Swipe mode ignores button commands")
	game.controls.set_control_mode(InputRouter.ControlMode.SPLIT_BUTTONS)
	check(game.hud.split_controls.visible, "Split mode shows buttons")
	send_touch(Vector2(640, 400), true)
	send_drag(Vector2(640, 330))
	send_touch(Vector2(640, 330), false)
	check(game.world.player.cell == center, "Split-only mode ignores swipes")
	send_key(KEY_W, true)
	await wait(0.17)
	send_key(KEY_W, false)
	check(game.world.player.cell == center + Vector2i(0, 1), "Keyboard remains active in split-only mode")
	game.controls.set_control_mode(InputRouter.ControlMode.BOTH)
	# Test each existing keyboard mapping against actual player movement.
	var keys := [KEY_W, KEY_S, KEY_A, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
	for i in range(keys.size()):
		warp(center)
		send_key(keys[i], true)
		await wait(0.17)
		send_key(keys[i], false)
		check(game.world.player.cell == center + directions[i % 4], "Keyboard mapping preserved: %s" % OS.get_keycode_string(keys[i]))
	# Inject a logical safe area to exercise margins independent of OS hardware.
	game.hud.set_process(false)
	var safe := Rect2(48, 0, 1184, 688)
	game.hud.apply_control_safe_area(safe)
	await get_tree().process_frame
	await get_tree().process_frame
	for direction in directions:
		var rect: Rect2 = game.hud.direction_buttons[direction].get_global_rect()
		check(safe.encloses(rect), "Touch target %s fits simulated notch/navigation safe area" % direction)
	game.hud.set_process(true)
	await get_tree().process_frame
	check(up.get_global_rect().position.x < 160 and right.get_global_rect().position.x > 1000, "Controls anchor to opposite bottom corners")

func polish_checks() -> void:
	game.start_run(42)
	await disable_hazards()
	var center := Vector2i(8, 3)
	warp(center)
	game.world.player.request_step(Vector2i(1, 1))
	game.world.player.request_step(Vector2i(2, 0))
	game.world.player.request_step(Vector2i.ZERO)
	check(game.world.player.cell == center, "Non-cardinal and zero movement commands rejected")
	game.world.player.request_step(Vector2i(1, 0))
	await wait(0.04)
	check(game.world.player.moving and game.world.player.art.position.y < -5.0, "Hop has an animated airborne phase")
	var midway := game.world.player.position
	var lane_time := game.world.lanes[0].active_seconds
	game.toggle_pause()
	await wait(0.2)
	check(game.world.player.position == midway and game.world.lanes[0].active_seconds == lane_time, "Pause freezes an in-progress hop and difficulty clock")
	game.toggle_pause()
	await wait(0.18)
	check(game.world.player.cell == center + Vector2i(1, 0) and game.world.player.position == game.world.config.cell_position(center + Vector2i(1, 0)), "Resume finishes exactly at its target grid cell")
	game.world.player.reset_to_spawn()
	check(game.world.player.art.scale == Vector2.ONE and not game.world.player.moving, "Respawn clears animation and movement state")
	var player_shape := game.world.player.get_node("CollisionShape2D").shape as RectangleShape2D
	check(player_shape.size.x < game.world.player.art.texture.get_width() and player_shape.size.y < game.world.player.art.texture.get_height(), "Player collision shape stays inside artwork dimensions")
	var car := game.world.lanes[0].get_child(0) as TrafficVehicle
	var car_shape := car.get_node("CollisionShape2D").shape as RectangleShape2D
	check(car_shape.size.x < car.art.texture.get_width() and car_shape.size.y < car.art.texture.get_height(), "Vehicle collision shape stays inside artwork dimensions")
	for seed_value in [7, 42, 1337, 9001]:
		for lane_config: LaneConfig in game.world.config.lanes:
			var lane := TrafficLane.new()
			lane.process_mode = Node.PROCESS_MODE_DISABLED
			add_child(lane)
			lane.setup(lane_config, seed_value, game.world.config)
			var first := lane.get_child(0) as TrafficVehicle
			check(lane.spawn_vehicle(first.position.x) == null, "Overlapping spawn refused: seed %d row %d" % [seed_value, lane_config.row])
			var initial_speed := lane.current_speed
			var spacing_ok := true
			var speeds_ok := true
			var spawns := 0
			var max_jump := 0.0
			for tick in range(1800): # 90 simulated seconds at 20 Hz, conservative for spacing.
				var previous_speed := lane.current_speed
				var before := lane.get_child_count()
				lane._physics_process(0.05)
				spawns += maxi(0, lane.get_child_count() - before)
				max_jump = maxf(max_jump, absf(lane.current_speed - previous_speed))
				var xs: Array[float] = []
				for vehicle: TrafficVehicle in lane.get_children():
					vehicle._physics_process(0.05)
					if vehicle.is_queued_for_deletion():
						lane.remove_child(vehicle)
					else:
						xs.append(vehicle.position.x)
						speeds_ok = speeds_ok and is_equal_approx(vehicle.speed, lane.current_speed)
				xs.sort()
				for i in range(1, xs.size()):
					spacing_ok = spacing_ok and xs[i] - xs[i - 1] >= TrafficLane.MAX_VEHICLE_WIDTH + lane.required_gap() - 0.01
			check(spacing_ok and spawns > 5, "90-second traffic run keeps crossable lane gaps: seed %d row %d" % [seed_value, lane_config.row])
			check(speeds_ok and max_jump < 2.0 and initial_speed < lane.speed_at(60.0), "Traffic accelerates gradually without overtaking: seed %d row %d" % [seed_value, lane_config.row])
			lane.queue_free()
			await get_tree().process_frame
