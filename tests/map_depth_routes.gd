extends "res://tests/map_route_tests.gd"
var target_coin:=Vector2i(-1,-1)
func choose_hop() -> void:
	if target_coin.x>=0:
		var player:=game.world.player
		if player.moving or game.state!=CrossingGame.State.PLAYING:return
		# Align on each resting strip, then use the same real hazard predictor.
		var current:=game.world.layout.section_at(player.cell.y)
		if current.get("kind") in [LevelSectionConfig.Kind.START_SECTION,LevelSectionConfig.Kind.SAFE_SECTION] and player.cell.x!=target_coin.x:
			var d:=Vector2i(signi(target_coin.x-player.cell.x),0)
			if safe_step(d):game.controls.direction_requested.emit(d)
			return
		if player.cell.y>=target_coin.y and player.cell.x!=target_coin.x:
			var d:=Vector2i(signi(target_coin.x-player.cell.x),0)
			if safe_step(d):game.controls.direction_requested.emit(d);return
	super.choose_hop()
func run() -> void:
	Profiles.storage_path="user://depth_routes.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Depth_Route");SaveData.coins=1000;SaveData.sound_enabled=false
	var mode:=game as ModeGame
	var passed:=0;var failed:=0
	for i in range(4):
		var map:=game.CAMPAIGN.levels[i] as MapConfig
		Profiles.purchase(map)
		for variant in ChallengeCatalog.for_map(map.level_id):
			for seed_value in [42,2026]:
				mode.select_challenge(i,variant.challenge_id);game.start_run(seed_value)
				for frame in range(180*60):
					if game.state in [CrossingGame.State.LEVEL_COMPLETE,CrossingGame.State.GAME_OVER]:break
					choose_hop();await get_tree().physics_frame
				var ok:=game.state==CrossingGame.State.LEVEL_COMPLETE
				if ok:passed+=1
				else:failed+=1
				print(("PASS " if ok else "FAIL ")+"VARIANT %s/%s seed=%d safe=%d seconds=%.2f lives=%d"%[map.level_id,variant.challenge_id,seed_value,mode.destinations_reached,mode.elapsed_seconds,mode.lives])
		mode.select_level(i)
		var coins: Array[Vector2i]=[]
		for cell: Vector2i in game.world.rewards.pickups:
			if game.world.rewards.pickups[cell].kind=="coin":coins.append(cell)
		for cell in coins:
			var collected:=false;target_coin=cell
			for seed_value in [42,2026,1405]:
				game.start_run(seed_value)
				for frame in range(90*60):
					if not game.world.rewards.pickups.has(cell):collected=true;break
					if game.state==CrossingGame.State.GAME_OVER:break
					choose_hop();await get_tree().physics_frame
				if collected:break
			if collected:passed+=1
			else:failed+=1
			print(("PASS " if collected else "FAIL ")+"COIN %s %s"%[map.level_id,cell])
		target_coin=Vector2i(-1,-1)
	game.queue_free();await get_tree().process_frame;game=null
	print("DEPTH ROUTE RESULTS: %d passed, %d failed"%[passed,failed]);get_tree().quit(failed)
