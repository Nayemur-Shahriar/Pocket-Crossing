extends Node
var game: CrossingGame
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	game = load("res://tools/water_preview.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	game.world.set_active(false)
	game.hud.show_tip("Hop onto the light decks. Boats carry you; open water is dangerous.", 30)
	await capture("water_overview")
	var lane := game.world.water_lanes[0]
	for deck in lane.platforms:
		if deck.position.x>450 and deck.position.x<850:
			game.world.player.cell = Vector2i(roundi((deck.position.x-96)/64),lane.row)
			game.world.player.position = Vector2(deck.position.x,lane.position.y)
			game.world.player.invulnerable_left = 0
			game.world.water_support.check_landing()
			break
	await capture("water_riding")
	for dimensions: Vector2i in [Vector2i(1920,864),Vector2i(960,720),Vector2i(800,360)]:
		get_window().size = dimensions
		await capture("water_%dx%d" % [dimensions.x,dimensions.y])
		for button: Control in game.hud.direction_buttons.values():
			assert(get_viewport().get_visible_rect().encloses(button.get_global_rect()))
		print("WATER UI PASS ",dimensions)
	game.queue_free()
	await get_tree().process_frame
	game = null
	get_tree().quit.call_deferred()
func capture(label: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
	print("Captured ",label)
