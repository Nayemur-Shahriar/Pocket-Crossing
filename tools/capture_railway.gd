extends Node
var game: CrossingGame
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	game = load("res://tools/railway_preview.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	game.world.set_active(false)
	await capture("railway_safe")
	var rail := game.world.railways[0]
	advance(rail,2.2)
	await capture("railway_warning")
	advance(rail,4.9)
	await capture("railway_passing")
	for dimensions: Vector2i in [Vector2i(1920,864),Vector2i(960,720),Vector2i(800,360)]:
		get_window().size = dimensions
		await capture("railway_%dx%d" % [dimensions.x,dimensions.y])
		for button: Control in game.hud.direction_buttons.values():
			assert(get_viewport().get_visible_rect().encloses(button.get_global_rect()))
		print("RAILWAY UI PASS ",dimensions)
	game.queue_free()
	await get_tree().process_frame
	game = null
	rail = null
	get_tree().quit.call_deferred()
func advance(rail: RailwaySection, seconds: float) -> void:
	for i in range(ceili(seconds*60)):
		rail._physics_process(1.0/60.0)
func capture(label: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
	print("Captured ",label)
