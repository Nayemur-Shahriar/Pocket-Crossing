extends Node
func _ready() -> void:
	Profiles.storage_path="user://stability_visual.cfg"
	var game: ModeGame=load("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Visual_Check");SaveData.coins=5000
	DirAccess.make_dir_recursive_absolute("res://docs/stability_screenshots")
	for i in range(4):
		Profiles.purchase(game.CAMPAIGN.levels[i]);game.select_level(i);game.start_run(42)
		await get_tree().create_timer(.6).timeout
		game.set_physics_process(false);game.world.set_active(false)
		var row:=game.world.layout.safe_rows[1]
		game.world.player.cell=Vector2i(8,row);game.world.player.position=game.world.config.cell_position(game.world.player.cell)
		game.world.camera.snap_to_player();game.world.decorations.refresh(true)
		game.dog_view.display({"phase":"warning","origin":game.world.player.position,"warning_id":i+1,"warning_left":.7},.1,false)
		for j in range(6):await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/stability_screenshots/"+game.CAMPAIGN.levels[i].level_id+".png")
	game.queue_free();await get_tree().process_frame
	print("STABILITY VISUAL: four maps rendered");get_tree().quit()
