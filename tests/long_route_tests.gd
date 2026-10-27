extends Node
## Test driver uses only ordinary hop requests and real physics. It predicts
## nearby hazards to pick a route; it never changes a lane, player position or lives.
var game: CrossingGame

func _ready() -> void:
	run.call_deferred()

func safe_step(direction: Vector2i) -> bool:
	var world := game.world
	var player := world.player
	var cell := player.cell + direction
	if not world.can_enter_cell(cell):
		return false
	var target := world.config.cell_position(cell)
	if world.water_support.lanes.has(cell.y):
		target.x = player.position.x + direction.x * world.config.cell_size
		var water: WaterLane = world.water_support.lanes[cell.y]
		var supported := false
		for deck in water.platforms:
			var future_x := deck.position.x + water.current_speed * water.config.direction * player.hop_duration
			if absf(target.x - future_x) < deck.length * 0.5 - 30:
				supported = true
		if not supported:
			return false
	# Include a short landing buffer before another hop can start.
	for sample in range(9):
		var time := sample * 0.035
		var t := minf(time / player.hop_duration, 1.0)
		var at := player.position.lerp(target,t*t*(3-2*t))
		for lane in world.lanes:
			if absf(lane.position.y - at.y) > 36:
				continue
			for vehicle: TrafficVehicle in lane.get_children():
				var x := vehicle.position.x + vehicle.speed * lane.config.direction * time
				var half_width := vehicle.visual.collision_size.x * 0.5 # Conservative bound also covers tapered convex outlines.
				if absf(x - at.x) < half_width + 22:
					return false
		for railway in world.railways:
			for track in railway.tracks:
				if absf(track.position.y - at.y) > 36:
					continue
				if track.state == RailwayTrack.State.WARNING and track.remaining < time + 0.5:
					return false
				if track.state == RailwayTrack.State.PASSING:
					var x := track.train.position.x + track.config.speed * track.config.direction * time
					if absf(x - at.x) < track.config.train_length * 0.5 + 24:
						return false
	return true

func choose_hop() -> void:
	var player := game.world.player
	if player.moving or game.state != CrossingGame.State.PLAYING:
		return
	var direction := Vector2i.ZERO
	if player.cell.y == game.world.config.goal_row - 1 and player.cell.x != 8:
		direction = Vector2i(signi(8 - player.cell.x),0)
	elif safe_step(Vector2i(0,1)):
		direction = Vector2i(0,1)
	elif not safe_step(Vector2i.ZERO):
		for candidate in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,-1)]:
			if safe_step(candidate):
				direction = candidate
				break
	elif game.world.water_support.lanes.has(player.cell.y):
		if player.position.x < 220 and safe_step(Vector2i(1,0)):
			direction = Vector2i(1,0)
		elif player.position.x > 1060 and safe_step(Vector2i(-1,0)):
			direction = Vector2i(-1,0)
	if direction != Vector2i.ZERO:
		game.controls.direction_requested.emit(direction)

func run() -> void:
	game = load("res://tools/long_level_preview.tscn").instantiate()
	add_child(game)
	SaveData.sound_enabled = false
	var failed := 0
	for seed_value in [42,2026]:
		game.start_run(seed_value)
		for frame in range(240*60):
			if game.state in [CrossingGame.State.LEVEL_COMPLETE,CrossingGame.State.GAME_OVER]:
				break
			choose_hop()
			await get_tree().physics_frame
		var ok := game.state == CrossingGame.State.LEVEL_COMPLETE
		if not ok: failed += 1
		print(("PASS " if ok else "FAIL ") + "Natural long mixed crossing seed %d: row=%d, lives=%d, remaining=%.1f" % [seed_value,game.world.player.cell.y,game.lives,game.time_left])
	game.queue_free()
	await get_tree().process_frame
	game = null
	print("LONG ROUTE RESULTS: %d passed, %d failed" % [2-failed,failed])
	get_tree().quit.call_deferred(failed)
