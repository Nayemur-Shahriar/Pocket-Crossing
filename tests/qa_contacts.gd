extends Node
## Actual Area2D contacts with every vehicle skin, plus rapid-input and skin swaps.
var passed:=0
var failed:=0
var game: CrossingGame
func _ready() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		push_error("FAIL "+label)
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
	await get_tree().process_frame
func run() -> void:
	SaveData.storage_path="user://m14_contacts.cfg"
	SaveData.sound_enabled=false
	game=load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	game.select_level(0)
	var player:=game.world.player
	for id in ["rickshaw","cng","small_car","microbus","local_bus","delivery_van","pickup","medium_truck","large_truck"]:
		for direction in [-1,1]:
			game.start_run(42)
			game.world.traffic.process_mode=Node.PROCESS_MODE_DISABLED
			player.invulnerable_left=0
			var vehicle: TrafficVehicle=load("res://scenes/actors/vehicle.tscn").instantiate()
			vehicle.vehicle_type=id
			vehicle.direction=direction
			game.world.add_child(vehicle)
			vehicle.set_physics_process(false)
			vehicle.hit_player.connect(game._on_collision)
			var extent: float=(vehicle.visual.collision_size.x+player.get_node("CollisionShape2D").shape.size.x)*0.5
			vehicle.position=player.position+Vector2(extent+3,0)
			await frames(4)
			check(game.lives==3,"Outside body collision remains safe: "+id)
			vehicle.position=player.position
			await frames(4)
			check(game.lives==2 and game.state==CrossingGame.State.RESPAWNING,"Real body collision loses one life: "+id+str(direction))
			await frames(4)
			check(game.lives==2,"No duplicate death while overlapping")
			vehicle.queue_free()
			await frames(2)
	# Every skin can be selected repeatedly without replacing the player or hitbox.
	var actor_id:=player.get_instance_id()
	var shape_id: int=player.get_node("CollisionShape2D").shape.get_instance_id()
	for cycle in range(4):
		for skin in CharacterCatalog.SKINS:
			SaveData.unlocked_characters[skin.id]=true
			check(SaveData.choose_character(skin.id),"Owned skin selection "+skin.id)
			game.start_run(42)
			check(player.art.texture.resource_path==skin.texture and player.get_instance_id()==actor_id and player.get_node("CollisionShape2D").shape.get_instance_id()==shape_id,"Skin swaps retain body/movement identity")
	# Stress a one-slot hop buffer on safe ground, using the existing input gateway.
	game.start_run(42)
	game.world.traffic.process_mode=Node.PROCESS_MODE_DISABLED
	var spawn:=player.cell
	game._on_direction(Vector2i.RIGHT)
	for i in range(100): game._on_direction(Vector2i.LEFT if i%2==0 else Vector2i.RIGHT)
	await frames(24)
	check(player.cell==spawn+Vector2i(2,0) and not player.moving,"Rapid commands produce current plus one buffered hop, no skipped cells")
	game.toggle_pause()
	var at:=player.position
	for i in range(100): game.controls.direction_requested.emit(Vector2i.LEFT)
	await frames(12)
	check(player.position==at and not player.moving,"No movement behind pause modal")
	game.toggle_pause()
	game._on_direction(Vector2i.LEFT)
	await frames(12)
	check(player.cell==spawn+Vector2i.RIGHT,"Input resumes without permanent lock")
	game.finish_game(false,"QA fixture")
	at=player.position
	for i in range(100): game.controls.direction_requested.emit(Vector2i.LEFT)
	await frames(12)
	check(player.position==at,"No movement behind failure modal")
	for voice in Audio.voices:voice.stop()
	game.queue_free()
	await frames(3)
	print("QA CONTACT RESULTS: %d passed, %d failed"%[passed,failed])
	get_tree().quit(1 if failed else 0)
