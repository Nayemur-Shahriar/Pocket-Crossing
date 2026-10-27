extends "res://tests/long_route_tests.gd"
func toward(row: int) -> void:
	var player := game.world.player
	if player.moving or game.state != CrossingGame.State.PLAYING: return
	var step := Vector2i(0,signi(row-player.cell.y))
	if safe_step(step):
		game.controls.direction_requested.emit(step)
	elif not safe_step(Vector2i.ZERO):
		for direction in [Vector2i(1,0),Vector2i(-1,0),-step]:
			if safe_step(direction):
				game.controls.direction_requested.emit(direction)
				break
	elif game.world.water_support.lanes.has(player.cell.y):
		if player.position.x < 250 and safe_step(Vector2i(1,0)):game.controls.direction_requested.emit(Vector2i(1,0))
		elif player.position.x > 1030 and safe_step(Vector2i(-1,0)):game.controls.direction_requested.emit(Vector2i(-1,0))
func run() -> void:
	SaveData.storage_path = "user://m13_water_routes.cfg"
	SaveData.sound_enabled = false
	game = load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	for level in game.CAMPAIGN.levels:SaveData.completed_levels[level.level_id]=true
	var passed := 0
	var failed := 0
	for index in [6,8,11,12,14]:
		game.select_level(index)
		game.start_run(2026)
		var first := game.world.water_lanes[0].row
		var last := first
		for lane in game.world.water_lanes:
			if lane.row==last+1:last=lane.row
		var ok := true
		for target in [last+1,first-1,last+1]:
			for frame in range(70*60):
				if game.state==CrossingGame.State.GAME_OVER:break
				if game.world.player.cell.y==target and not game.world.player.moving:break
				toward(target)
				await get_tree().physics_frame
			ok = ok and game.state==CrossingGame.State.PLAYING and game.world.player.cell.y==target
		if ok:passed+=1
		else:failed+=1
		print(("PASS " if ok else "FAIL ")+"M13 water forward/backtrack/recross level %d lives=%d" % [index+1,game.lives])
	game.queue_free()
	await get_tree().process_frame
	print("BALANCE WATER ROUTES: %d passed, %d failed" % [passed,failed])
	get_tree().quit.call_deferred(0 if failed==0 else 1)
