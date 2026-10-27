extends Node
## Optional rendered layout checks: godot --path . tools/capture_mobile.tscn
func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveData.storage_path = "user://mobile_preview_profile.cfg"
	SaveData.sound_enabled = false
	var game := load("res://scenes/legacy_main.tscn").instantiate() as CrossingGame
	add_child(game)
	await get_tree().process_frame
	game.start_run(42)
	# Freeze this preview to compare the exact same board at every size.
	game.set_physics_process(false)
	game.world.traffic.process_mode = Node.PROCESS_MODE_DISABLED
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 864), Vector2i(960, 720), Vector2i(800, 360)]:
		get_window().size = dimensions
		await get_tree().create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		var viewport_rect := get_viewport().get_visible_rect()
		for button: Control in game.hud.direction_buttons.values():
			assert(viewport_rect.encloses(button.get_global_rect()), "Control outside viewport")
			var on_screen := get_viewport().get_screen_transform() * button.get_global_rect()
			assert(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(on_screen), "Control outside window")
		var path := "res://docs/screenshots/mobile_%dx%d.png" % [dimensions.x, dimensions.y]
		get_viewport().get_texture().get_image().save_png(path)
		print("LAYOUT PASS ", dimensions, " viewport=", viewport_rect)
		print("RENDER METRICS draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			" texture_bytes=", Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
