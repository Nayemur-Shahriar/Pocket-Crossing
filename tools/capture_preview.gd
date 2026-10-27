extends Node
## Captures actual rendered game screens. Requires a display, not --headless.
## godot --path . tools/capture_preview.tscn

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Preview capture needs a rendered display.")
		get_tree().quit(1)
		return
	var saved_profile := {"path": SaveData.storage_path, "best": SaveData.best_score, "sound": SaveData.sound_enabled}
	SaveData.storage_path = "user://preview_profile.cfg"
	SaveData.best_score = 0
	SaveData.sound_enabled = false
	var game := load("res://scenes/legacy_main.tscn").instantiate() as CrossingGame
	add_child(game)
	await get_tree().create_timer(0.2).timeout
	await capture("menu")
	game.start_run(42)
	await get_tree().create_timer(0.9).timeout
	await capture("level_01")
	game.world.player.request_step(Vector2i(1, 0))
	await get_tree().create_timer(0.06).timeout
	await capture("hop")
	await get_tree().create_timer(0.2).timeout
	game.hud.hit_flash(game.world.player.position)
	await get_tree().create_timer(0.04).timeout
	await capture("impact")
	await get_tree().create_timer(0.5).timeout
	game.toggle_pause()
	await capture("pause")
	game.toggle_pause()
	game.lives = 0
	game.world.player.stop_and_hide()
	game.finish_game(false, "No lives left.")
	await capture("game_over")
	game.start_run(42)
	for column in game.world.config.goal_columns:
		game.world.claim_destination(column)
	game.destinations_reached = 4
	game.time_left = 88.0
	game.score = 1230
	game.finish_game(true, "Time + lives bonus: 590 points.")
	await capture("level_complete")
	SaveData.storage_path = saved_profile.path
	SaveData.best_score = saved_profile.best
	SaveData.sound_enabled = saved_profile.sound
	DirAccess.remove_absolute("user://preview_profile.cfg")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func capture(name: String) -> void:
	if name in ["menu", "pause", "game_over", "level_complete"]:
		await get_tree().create_timer(0.24).timeout
	await RenderingServer.frame_post_draw
	var path := "res://docs/screenshots/%s.png" % name
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("Captured ", name, ": ", error_string(error))
