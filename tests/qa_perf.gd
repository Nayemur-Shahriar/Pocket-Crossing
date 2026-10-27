extends Node
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	SaveData.storage_path="user://m14_perf.cfg"
	SaveData.sound_enabled=false
	var game: CrossingGame=load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	for level in game.CAMPAIGN.levels: SaveData.completed_levels[level.level_id]=true
	game.select_level(14)
	game.world.set_active(false)
	var times: Array[int]=[]
	for repeat in range(7):
		var begin:=Time.get_ticks_usec()
		for frame in range(10000):
			for lane in game.world.lanes: lane.update_vehicle_speeds(1.0/60)
		times.append(Time.get_ticks_usec()-begin)
	times.sort()
	print("PERF all 12 final-level roads, 10000 speed updates, median_us=",times[3]," samples=",times)
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
