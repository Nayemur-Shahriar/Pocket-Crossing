extends Node
var game: CrossingGame
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	SaveData.storage_path = "user://section_capture.cfg"
	SaveData.load_profile()
	SaveData.sound_enabled = false
	game = load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	for i in range(game.CAMPAIGN.levels.size()):
		if i > 0:
			SaveData.completed_levels[game.CAMPAIGN.levels[i - 1].level_id] = true
		game.select_level(i)
		game.world.set_active(false)
		await capture("sections_legacy_%02d" % (i + 1))
	var catalog := LevelCatalog.new()
	catalog.levels = [load("res://resources/examples/road_sections_demo.tres"), load("res://resources/examples/mixed_layout_data_only.tres")]
	game.CAMPAIGN = catalog
	game.select_level(0)
	game.world.set_active(false)
	await capture("sections_example")
	for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1920,864), Vector2i(960,720), Vector2i(800,360)]:
		get_window().size = dimensions
		await capture("sections_layout_%dx%d" % [dimensions.x,dimensions.y])
		for button: Control in game.hud.direction_buttons.values():
			assert(get_viewport().get_visible_rect().encloses(button.get_global_rect()), "Control outside viewport")
			var rect := get_viewport().get_screen_transform() * button.get_global_rect()
			assert(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(rect), "Control outside physical screen")
		print("SECTION LAYOUT PASS ", dimensions)
	get_window().size = Vector2i(1280,720)
	game.show_menu()
	await capture("sections_configuration_only")
	game.queue_free()
	await get_tree().process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SaveData.storage_path + suffix):
			DirAccess.remove_absolute(SaveData.storage_path + suffix)
	get_tree().quit()
func capture(label: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/" + label + ".png")
	print("Captured ", label)
