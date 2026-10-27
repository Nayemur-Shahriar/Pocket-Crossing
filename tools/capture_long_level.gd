extends Node
var game: CrossingGame

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	game = load("res://tools/long_level_preview.tscn").instantiate()
	add_child(game)
	SaveData.sound_enabled = false # Capture harness has no audio device.
	game.hud.set_sound(false)
	game.set_physics_process(false)
	game.world.set_active(false)
	game.hud.show_tip("Long Crossing: roads, railway, water, and a destination beyond the first screen.",30)
	await capture("m9_start")
	for row in [7,13,17,22]:
		place(row)
		if row == 7:
			for track in game.world.railways[0].tracks:
				track.remaining = 0
				track.begin_warning()
		await capture("m9_row_%d" % row)
	place(13)
	for dimensions: Vector2i in [Vector2i(1920,864),Vector2i(960,720),Vector2i(800,360)]:
		get_window().size = dimensions
		await capture("m9_%dx%d" % [dimensions.x,dimensions.y])
		for button: Control in game.hud.direction_buttons.values():
			assert(get_viewport().get_visible_rect().encloses(button.get_global_rect()))
		print("M9 UI PASS ",dimensions)
	get_window().size = Vector2i(1280,720)
	place(17)
	game.world.player.invulnerable_left = 0
	game._on_collision(game.world.player)
	await capture("m9_hit_feedback", 0.05)
	for voice in Audio.get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
	game.queue_free()
	await get_tree().process_frame
	game = null
	await get_tree().create_timer(0.1).timeout
	get_tree().quit.call_deferred()

func place(row: int) -> void:
	game.world.player.cell = Vector2i(8,row)
	game.world.player.position = game.world.config.cell_position(game.world.player.cell)
	game.world.camera.snap_to_player()
	game.world.activation.refresh(true)
	game.world.terrain.refresh()

func capture(label: String, delay: float = 0.2) -> void:
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
	print("Captured ",label)
