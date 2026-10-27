extends Node
## Plays the unmodified demo through real hops, support and damage; no teleporting.
var game: CrossingGame
func _ready() -> void:
	run.call_deferred()
func safe_hop(direction: Vector2i) -> bool:
	var player := game.world.player
	var cell := player.cell + direction
	if not game.world.can_enter_cell(cell): return false
	if not game.world.water_support.lanes.has(cell.y): return true
	var lane: WaterLane = game.world.water_support.lanes[cell.y]
	var target := player.position.x + direction.x * game.world.config.cell_size
	for deck in lane.platforms:
		var future_x := deck.position.x + lane.current_speed * lane.config.direction * player.hop_duration
		if absf(target-future_x) < deck.length/2.0-28:
			return true
	return false
func choose_hop() -> void:
	var player := game.world.player
	if player.moving or game.state!=CrossingGame.State.PLAYING: return
	var direction := Vector2i.ZERO
	if player.cell.y<=1:
		if player.cell.x != 8: direction = Vector2i(signi(8-player.cell.x),0)
		elif safe_hop(Vector2i(0,1)): direction = Vector2i(0,1)
	elif player.cell.y<=4:
		if safe_hop(Vector2i(0,1)): direction = Vector2i(0,1)
		elif player.position.x<220 and safe_hop(Vector2i(1,0)): direction = Vector2i(1,0)
		elif player.position.x>1060 and safe_hop(Vector2i(-1,0)): direction = Vector2i(-1,0)
	else:
		var goal := game.world.config.goal_columns[game.destinations_reached]
		direction = Vector2i(signi(goal-player.cell.x),0) if player.cell.x!=goal else Vector2i(0,1)
	if direction!=Vector2i.ZERO: game._on_direction(direction)
func run() -> void:
	game = load("res://tools/water_preview.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	SaveData.sound_enabled = false
	var failed := 0
	for seed_value in [11,42,2026]:
		game.start_run(seed_value)
		for frame in range(180*60):
			if game.state in [CrossingGame.State.LEVEL_COMPLETE,CrossingGame.State.GAME_OVER]: break
			choose_hop()
			for lane in game.world.water_lanes: lane._physics_process(1.0/60.0)
			game.world.water_support._physics_process(1.0/60.0)
			game.world.player._physics_process(1.0/60.0)
			game._physics_process(1.0/60.0)
		var ok := game.state==CrossingGame.State.LEVEL_COMPLETE and game.lives==3
		if not ok: failed+=1
		print(("PASS " if ok else "FAIL ")+"Natural four-bay crossing seed %d: lives=%d, remaining=%.1f" % [seed_value,game.lives,game.time_left])
	game.world.set_active(false)
	game.queue_free()
	await get_tree().process_frame
	game = null
	print("WATER ROUTE RESULTS: %d passed, %d failed" % [3-failed,failed])
	get_tree().quit.call_deferred(failed)
