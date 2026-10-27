extends Node
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	SaveData.storage_path = "user://m14_repro.cfg"
	SaveData.sound_enabled = false
	var game: CrossingGame = load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	for level in game.CAMPAIGN.levels: SaveData.completed_levels[level.level_id] = true
	game.select_level(14)
	game.world.set_active(false)
	var world := game.world
	var section := world.railways[0]
	var track := section.tracks[0]
	var row := roundi((world.config.grid_origin.y-track.position.y)/world.config.cell_size)
	world.player.cell = Vector2i(8,row)
	world.player.position = world.config.cell_position(world.player.cell)
	world.camera.snap_to_player()
	world.activation.refresh(true)
	track.state = RailwayTrack.State.PASSING
	track.train.launch(1280)
	track.train.position.x = world.player.position.x
	world.player.cell = Vector2i(8,world.config.goal_row)
	world.player.position = world.config.cell_position(world.player.cell)
	world.camera.snap_to_player()
	world.activation.refresh(true)
	print("REPRO rail inactive=",not section.visible)
	world.player.cell = Vector2i(8,row)
	world.player.position = world.config.cell_position(world.player.cell)
	world.camera.snap_to_player()
	world.activation.refresh(true)
	print("REPRO rail safe reentry=",track.state==RailwayTrack.State.WARNING and not track.train.running and track.remaining>=track.config.warning_seconds)
	SaveData.completed_levels = {game.CAMPAIGN.levels[5].level_id:true}
	print("REPRO own completed level unlocked=",SaveData.is_unlocked(5,game.CAMPAIGN))
	var bad: LevelConfig = game.CAMPAIGN.levels[0].duplicate(true)
	bad.hop_seconds = 0
	print("REPRO zero road hop rejected=",not bad.playability_errors().is_empty())
	SaveData.coins = 41
	SaveData.save()
	SaveData.coins = 42
	SaveData.save()
	var empty := FileAccess.open(SaveData.storage_path,FileAccess.WRITE)
	empty.close()
	SaveData.load_profile()
	print("REPRO empty primary recovers valid backup=",SaveData.coins==41)
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
