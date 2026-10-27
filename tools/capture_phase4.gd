extends Node
var game: CrossingGame
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	SaveData.storage_path = "user://phase4_preview.cfg"
	SaveData.completed_levels = {}
	SaveData.level_scores = {}
	SaveData.level_stars = {}
	SaveData.coins = 32
	SaveData.selected_character = "mint"
	SaveData.sound_enabled = false
	game = load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	await capture("phase4_select")
	game.hud.characters_pressed.emit()
	await capture("phase4_characters")
	game.select_level(0)
	game.world.set_active(false)
	await capture("phase4_gameplay")
	for path in ["shield", "slow", "double"]:
		game.powers.activate(load("res://resources/powerups/" + path + ".tres"))
	game._update_hud()
	await capture("phase4_effects")
	for cell: Vector2i in game.world.rewards.pickups.keys():
		if game.world.rewards.pickups[cell].kind == "coin":
			game._collect_reward(cell)
			break
	game.score = 1250
	game.time_left = 50
	game.finish_game(true, "Time + lives bonus: 400 points.")
	await capture("phase4_results")
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 864), Vector2i(960, 720), Vector2i(800, 360)]:
		get_window().size = size
		game.show_menu()
		await get_tree().process_frame
		await capture("phase4_select_%dx%d" % [size.x, size.y])
		validate_controls(game.hud.overlay)
		game.hud.show_characters()
		await capture("phase4_characters_%dx%d" % [size.x, size.y])
		validate_controls(game.hud.overlay)
		game.start_run(42)
		game.world.set_active(false)
		await get_tree().process_frame
		for button: Control in game.hud.direction_buttons.values():
			assert(get_viewport().get_visible_rect().encloses(button.get_global_rect()), "Thumb control outside viewport")
		print("PHASE4 LAYOUT PASS ", size)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SaveData.storage_path + suffix):
			DirAccess.remove_absolute(SaveData.storage_path + suffix)
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
func validate_controls(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			assert(get_viewport().get_visible_rect().encloses(child.get_global_rect()), "Button outside viewport")
		if child is Label:
			assert(child.get_global_rect().end.x <= 1280, "Text extends outside viewport")
		validate_controls(child)
func capture(label: String) -> void:
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/" + label + ".png")
	print("Captured ", label)
