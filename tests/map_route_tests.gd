extends "res://tests/long_route_tests.gd"
func choose_hop() -> void:
	var player:=game.world.player
	if player.moving or game.state!=CrossingGame.State.PLAYING:return
	var direction:=Vector2i.ZERO
	if player.cell.y==game.world.config.goal_row-1:
		var nearest: int=-1
		for col: int in game.world.goals:
			if not game.world.goals[col].occupied and (nearest<0 or absi(col-player.cell.x)<absi(nearest-player.cell.x)):nearest=col
		if nearest!=player.cell.x:direction=Vector2i(signi(nearest-player.cell.x),0)
		else:direction=Vector2i(0,1)
	elif safe_step(Vector2i(0,1)):direction=Vector2i(0,1)
	elif not safe_step(Vector2i.ZERO):
		for candidate in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,-1)]:
			if safe_step(candidate):
				direction=candidate
				break
	elif game.world.water_support.lanes.has(player.cell.y):
		if player.position.x<220 and safe_step(Vector2i(1,0)):direction=Vector2i(1,0)
		elif player.position.x>1060 and safe_step(Vector2i(-1,0)):direction=Vector2i(-1,0)
	if direction!=Vector2i.ZERO:game.controls.direction_requested.emit(direction)
func run() -> void:
	Profiles.storage_path="user://map_route.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=load("res://scenes/m145_main.tscn").instantiate()
	add_child(game)
	Profiles.create_profile("RouteTester")
	SaveData.sound_enabled=false
	SaveData.coins=1000
	var failures:=0
	for map_index in range(4):
		Profiles.purchase(game.CAMPAIGN.levels[map_index])
		for seed_value in [42,2026,1405]:
			game.select_level(map_index)
			game.start_run(seed_value)
			for frame in range(240*60):
				if game.state in [CrossingGame.State.LEVEL_COMPLETE,CrossingGame.State.GAME_OVER]:break
				choose_hop()
				await get_tree().physics_frame
			var ok:=game.state==CrossingGame.State.LEVEL_COMPLETE
			if not ok:failures+=1
			print(("PASS " if ok else "FAIL ")+"MAP ROUTE %s seed=%d safe=%d time=%.2f lives=%d coins=%d"%[game.world.config.level_id,seed_value,game.destinations_reached,game.elapsed_seconds,game.lives,game.run_coins])
	game.queue_free()
	await get_tree().process_frame
	game=null
	print("MAP ROUTE RESULTS: %d passed, %d failed"%[12-failures,failures])
	get_tree().quit(failures)
