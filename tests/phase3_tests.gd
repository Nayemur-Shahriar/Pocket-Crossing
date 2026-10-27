extends Node
var passed := 0
var failed := 0
var game: CrossingGame
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	SaveData.storage_path = "user://phase3_test.cfg"
	SaveData.completed_levels = {}
	SaveData.level_scores = {}
	SaveData.best_score = 0
	SaveData.sound_enabled = false
	SaveData.save()
	game = load("res://scenes/legacy_main.tscn").instantiate()
	game.CAMPAIGN = load("res://tests/fixtures/legacy_campaign.tres")
	add_child(game)
	await get_tree().process_frame
	check(game.CAMPAIGN.levels.size() == 5, "Five resource-defined campaign levels")
	check(game.state == CrossingGame.State.MENU, "Starts at level selection")
	game.select_level(4)
	check(game.state == CrossingGame.State.MENU and game.level_index == 0, "Locked level cannot be started")
	for i in range(5):
		var config: LevelConfig = game.CAMPAIGN.levels[i]
		check(config.validation_errors().is_empty(), "Valid geometry and routes: " + config.display_name)
		check(SaveData.is_unlocked(i, game.CAMPAIGN), "Previous completion unlocks level %d" % (i + 1))
		game.select_level(i)
		check(game.level_index == i and game.world.config == config, "Correct resource selected")
		check(game.world.lanes.size() == config.lanes.size() and game.world.goals.size() == config.goal_columns.size(), "No stale lanes or destinations")
		check(game.world.player.cell == config.spawn_cell and game.score == 0 and game.lives == 3 and game.time_left == config.time_limit, "Fresh level state")
		check(game.world.player.config == config, "Player uses current level rules")
		for cell in config.obstacles:
			check(not game.world.can_enter_cell(cell), "Obstacle rejects entry")
		game.toggle_pause()
		var clock := game.time_left
		await get_tree().create_timer(0.05).timeout
		check(game.time_left == clock, "Pause freezes current level")
		game.toggle_pause()
		# Drive actual destination callbacks, bypassing traffic to test campaign flow deterministically.
		for column in config.goal_columns:
			game._set_state(CrossingGame.State.PLAYING)
			game._on_step_completed(Vector2i(column, config.goal_row))
		check(game.state == CrossingGame.State.LEVEL_COMPLETE, "All goals finish level")
		check(SaveData.completed_levels.get(config.level_id, false), "Completion recorded by stable ID")
		var result := game.score
		game.finish_game(true, "duplicate")
		check(game.score == result, "Duplicate completion cannot award reward twice")
		SaveData.completed_levels = {}
		SaveData.level_scores = {}
		SaveData.load_profile()
		check(SaveData.completed_levels.get(config.level_id, false) and SaveData.level_scores.get(config.level_id, 0) == result, "Save reload restores completion and best")
		game._on_primary()
		check(game.level_index == mini(i + 1, 4) and game.state == CrossingGame.State.PLAYING, "Next level or final replay")
		game.start_run(42)
		check(game.score == 0 and game.destinations_reached == 0, "Retry clears run state")
		game.show_menu()
		check(game.state == CrossingGame.State.MENU and not game.controls.enabled, "Return to selection disables movement")
	# A failed run does not unlock anything.
	SaveData.completed_levels = {}
	game.select_level(0)
	game.finish_game(false, "test")
	check(not SaveData.is_unlocked(1, game.CAMPAIGN), "Failure never unlocks next level")
	# Spacing and railway signals over deterministic simulated time.
	for level: LevelConfig in game.CAMPAIGN.levels:
		for lane_config in level.lanes:
			var lane := TrafficLane.new()
			add_child(lane)
			lane.setup(lane_config, 24, level)
			lane.set_physics_process(false)
			for child in lane.get_children():
				child.set_physics_process(false)
			var fair := true
			for tick in range(1800):
				for vehicle: TrafficVehicle in lane.get_children():
					vehicle.set_physics_process(false)
					vehicle.position.x += vehicle.speed * vehicle.direction * 0.05
					if vehicle.position.x < -400 or vehicle.position.x > 1680:
						lane.remove_child(vehicle)
						vehicle.free()
				lane._physics_process(0.05)
				var vehicles := lane.get_children()
				for a in range(vehicles.size()):
					for b in range(a + 1, vehicles.size()):
						if absf(vehicles[a].position.x - vehicles[b].position.x) - lane.vehicle_envelope() < lane.required_gap() - 0.1:
							fair = false
			check(fair, "90-second spacing simulation: %s row %d" % [level.display_name, lane_config.row])
			if lane_config.pattern == "railway":
				lane._last_train_cycle = -1
				lane.active_seconds = 0
				check(not lane.spawning_allowed(), "Railway begins with safe crossing interval")
				lane.active_seconds = lane_config.open_seconds + 1
				check(not lane.spawning_allowed(), "Warning precedes train spawning")
				lane.active_seconds = lane_config.open_seconds + lane_config.warning_seconds
				check(lane.spawning_allowed(), "Train arrives only after warning")
			lane.free()
	# Migration from pre-campaign profile.
	var old := ConfigFile.new()
	old.set_value("profile", "best_score", 1234)
	old.set_value("settings", "sound", false)
	old.save(SaveData.storage_path)
	SaveData.load_profile()
	check(SaveData.best_score == 1234 and not SaveData.sound_enabled and SaveData.completed_levels.is_empty(), "Old profile migrates without losing score/settings")
	check(SaveData.is_unlocked(0, game.CAMPAIGN) and not SaveData.is_unlocked(1, game.CAMPAIGN), "Migrated profile starts at level one")
	DirAccess.remove_absolute(SaveData.storage_path)
	print("PHASE 3 RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed else 0)
