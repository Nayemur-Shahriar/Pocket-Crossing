extends "res://tests/long_route_tests.gd"
## Real physics and ordinary input; no teleporting, immunity or hazard edits.
func run() -> void:
	SaveData.storage_path = "user://m11_routes.cfg"
	SaveData.completed_levels = {}
	SaveData.level_scores = {}
	SaveData.level_stars = {}
	SaveData.sound_enabled = false
	game = load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	for level in game.CAMPAIGN.levels:
		SaveData.completed_levels[level.level_id] = true
	var passed := 0
	var failed := 0
	for index in range(15):
		game.select_level(index)
		var strong_runs := 0
		var power_free_runs := 0
		for seed_value in [42, 2026, 711]:
			game.start_run(seed_value)
			var used_power := false
			# Different arrival phases, ordinary waiting at Start (no clock/hazard edits).
			for wait_frame in range(({42:0,2026:4,711:9}[seed_value])*60):
				await get_tree().physics_frame
			for frame in range(240 * 60):
				if game.state in [CrossingGame.State.LEVEL_COMPLETE, CrossingGame.State.GAME_OVER]: break
				used_power = used_power or not game.powers.active.is_empty()
				choose_hop()
				await get_tree().physics_frame
			var ok := game.state == CrossingGame.State.LEVEL_COMPLETE
			if ok and not used_power: power_free_runs += 1
			if ok and game.run_stars == 3: strong_runs += 1
			if ok: passed += 1
			else: failed += 1
			print(("PASS " if ok else "FAIL ") + "Campaign %02d seed %d: row=%d lives=%d stars=%d elapsed=%.1f score=%d" % [index+1, seed_value, game.world.player.cell.y, game.lives, game.run_stars, game.world.config.time_limit-game.time_left, game.score])
		if power_free_runs > 0:
			passed += 1
			print("PASS Level %02d has %d/3 power-free routes" % [index+1,power_free_runs])
		else:
			failed += 1
			print("FAIL No power-free route for level %02d" % (index+1))
		if strong_runs > 0:
			passed += 1
			print("PASS Level %02d has %d/3 three-star routes" % [index+1,strong_runs])
		else:
			failed += 1
			print("FAIL No three-star route for level %02d" % (index+1))
	game.queue_free()
	await get_tree().process_frame
	game = null
	print("CAMPAIGN ROUTE RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit.call_deferred(1 if failed else 0)
