extends Node
## Rendered inspection fixtures. Uses isolated saves, not the normal player database.
var game: MapGame
func _ready() -> void:run.call_deferred()
func settle() -> void:
	for i in range(6):await get_tree().process_frame
func shot(label: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/map_"+label+".png")
func run() -> void:
	Profiles.storage_path="user://capture_maps.cfg"
	SaveData.storage_path="user://capture_maps_legacy.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	SaveData.load_profile()
	game=load("res://scenes/m145_main.tscn").instantiate()
	add_child(game)
	await shot("profiles")
	game._create_profile("CrossingFan")
	SaveData.sound_enabled=false
	await shot("select_locked")
	SaveData.coins=500
	for map: MapConfig in game.CAMPAIGN.levels:Profiles.purchase(map)
	game.show_menu()
	await shot("select_unlocked")
	game.hud.show_characters()
	await shot("characters")
	for index in range(4):
		game.select_level(index)
		game.start_run(42)
		await get_tree().create_timer(1).timeout
		game.set_physics_process(false)
		game.world.set_active(false)
		await shot("start_"+game.current_map.level_id)
		var actor:=game.world.player
		actor.cell=Vector2i(8,game.world.config.goal_row-1)
		actor.position=game.world.config.cell_position(actor.cell)
		game.world.camera.snap_to_player()
		game.world.activation.refresh(true)
		game.world.terrain.refresh()
		game.world.decorations.refresh(true)
		var goal: DestinationZone=game.world.goals.values()[0]
		goal.set_occupied(true)
		goal.character_texture=actor.art.texture
		game.destinations_reached=1
		game._update_hud()
		await shot("goals_"+game.current_map.level_id)
	game.elapsed_seconds=106.52
	game.destinations_reached=5
	game.finish_game(true,"")
	game.map_hud.map_celebration.set_process(false)
	game.map_hud.map_celebration._process(0.1)
	game.map_hud.map_celebration._process(1.8)
	await shot("new_best")
	game.start_run(42)
	game.toggle_pause()
	await shot("pause")
	game.toggle_pause()
	game.finish_game(false,"")
	await shot("failure")
	game.queue_free()
	await settle()
	print("MAP VISUAL CAPTURE: completed")
	get_tree().quit()
