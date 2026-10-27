extends "res://tests/long_route_tests.gd"
## Reuse the M9 test pilot across all six presentations, with real physics/controls.
func run() -> void:
	game = load("res://tools/theme_preview.tscn").instantiate()
	add_child(game)
	SaveData.sound_enabled = false
	var failed := 0
	for index in range(6):
		game.select_theme(index)
		game.start_run(42)
		for frame in range(240*60):
			if game.state in [CrossingGame.State.LEVEL_COMPLETE,CrossingGame.State.GAME_OVER]: break
			choose_hop()
			await get_tree().physics_frame
		var ok := game.state == CrossingGame.State.LEVEL_COMPLETE and game.lives == 3
		if not ok: failed += 1
		print(("PASS " if ok else "FAIL ")+"Mixed road/rail/water route under "+game.world.presentation.theme.display_name+": lives="+str(game.lives))
	game.queue_free()
	await get_tree().process_frame
	game = null
	print("THEME ROUTE RESULTS: %d passed, %d failed" % [6-failed,failed])
	get_tree().quit.call_deferred(failed)
