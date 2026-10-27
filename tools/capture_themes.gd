extends Node
var game: CrossingGame
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	game = load("res://tools/theme_preview.tscn").instantiate()
	add_child(game)
	SaveData.sound_enabled = false
	game.hud.set_sound(false)
	game.set_physics_process(false)
	game.world.set_active(false)
	for i in range(6):
		game.select_theme(i)
		game.picker.select(i)
		for row in [0,7,13,22]:
			game.world.player.cell = Vector2i(8,row)
			game.world.player.position = game.world.config.cell_position(game.world.player.cell)
			game.world.camera.snap_to_player()
			game.world.activation.refresh(true)
			game.world.terrain.refresh()
			game.world.presentation.follow_camera()
			if row == 7:
				var tracks := game.world.railways[0].tracks
				tracks[0].state = RailwayTrack.State.SAFE
				tracks[0].remaining = 0
				tracks[0].begin_warning()
				tracks[1].state = RailwayTrack.State.PASSING
				tracks[1].train.launch(tracks[1].width)
				tracks[1].train.position.x = 640
				tracks[1].signal_art.update_state(2,true)
			await capture("m10_"+game.world.presentation.theme.theme_id+"_row_"+str(row))
	game.select_theme(3)
	game.picker.select(3)
	for dimensions: Vector2i in [Vector2i(1920,864),Vector2i(960,720),Vector2i(800,360)]:
		get_window().size = dimensions
		await capture("m10_rain_%dx%d" % [dimensions.x,dimensions.y])
		for button: Control in game.hud.direction_buttons.values():
			assert(get_viewport().get_visible_rect().encloses(button.get_global_rect()))
		print("THEME UI PASS ",dimensions)
	get_window().size = Vector2i(1280,720)
	var classic := load("res://resources/levels/level_01.tres") as LevelConfig
	game.world.configure(classic)
	game.start_run(42)
	game.world.set_active(false)
	game.hud.set_level(game.world.config,false)
	for index in [0,2,3,4]:
		game.select_theme(index)
		game.picker.select(index)
		await capture("m10_classic_"+game.world.presentation.theme.theme_id)
	game.queue_free()
	await get_tree().process_frame
	game = null
	get_tree().quit.call_deferred()
func capture(label: String) -> void:
	await get_tree().create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
	print("Captured ",label)
