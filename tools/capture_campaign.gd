extends Node
## Reproducible render checks, isolated from the campaign profile.
var game: CrossingGame
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	game = load("res://tools/campaign_preview.tscn").instantiate()
	add_child(game)
	SaveData.sound_enabled = false
	game.set_physics_process(false)
	game.hud.set_sound(false)
	for i in range(15):
		game.select_level(i)
		game.world.set_active(false)
		var row := 0
		if not game.world.water_lanes.is_empty():
			row = game.world.water_lanes[0].row - 1
		elif not game.world.railways.is_empty():
			row = roundi((game.world.config.grid_origin.y-game.world.railways[0].tracks[0].position.y)/64.0)-1
		elif i > 1: row = 3
		game.world.player.cell = Vector2i(8,row)
		game.world.player.position = game.world.config.cell_position(game.world.player.cell)
		game.world.camera.snap_to_player()
		game.world.activation.refresh(true)
		game.world.terrain.refresh()
		game.world.presentation.follow_camera()
		if not game.world.railways.is_empty():
			var track := game.world.railways[0].tracks[0]
			track.state = RailwayTrack.State.SAFE
			track.begin_warning()
		await capture("level_%02d" % (i+1))
	for index in [0,2,3,7,9,10]:
		game.select_level(index)
		game.world.set_active(false)
		SaveData.level_scores[game.world.config.level_id] = 500
		game.score = 1000
		game.run_coins = 8
		game.finish_game(true,"render")
		game.hud.result_panel.celebration.set_process(false)
		game.hud.result_panel.celebration._process(0.98)
		await capture("record_"+game.world.presentation.theme.theme_id)
	game.start_run(42)
	game.score = 750
	game.run_coins = 5
	game.finish_game(true,"render")
	await capture("normal_complete")
	game.start_run(42)
	game.score = 420
	game.run_coins = 3
	game.finish_game(false,"No lives left.")
	await capture("failure")
	for dimensions: Vector2i in [Vector2i(1920,864),Vector2i(800,360)]:
		get_window().size = dimensions
		await capture("failure_%dx%d" % [dimensions.x,dimensions.y])
	get_window().size = Vector2i(1280,720)
	game.select_level(14)
	SaveData.level_scores[game.world.config.level_id] = 0
	game.score = 2100
	game.run_coins = 12
	game.finish_game(true,"render")
	await capture("final_complete")
	game.show_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll := game.hud.overlay.get_node("LevelScroll") as ScrollContainer
	scroll.scroll_vertical = 0
	await capture("select_top")
	scroll.scroll_vertical = 1800
	await capture("select_bottom")
	game.queue_free()
	await get_tree().process_frame
	game = null
	get_tree().quit.call_deferred()
func capture(label: String) -> void:
	await get_tree().create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/m11_"+label+".png")
	print("Captured ",label)
