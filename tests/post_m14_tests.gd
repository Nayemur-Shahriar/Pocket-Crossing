extends Node
## Focused integration regression. Only this isolated test profile is written.
var game: CrossingGame
var passed := 0
var failed := 0
var selections := 0
var hazards := 0
func _ready() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error("FAIL "+label)
func frames(count: int = 3) -> void:
	for i in range(count): await get_tree().process_frame
func locate(row: int, column: int = 8) -> void:
	var actor := game.world.player
	actor.clear_buffer()
	actor.moving = false
	actor.visible = true
	actor.enabled = true
	actor.invulnerable_left = 0
	actor.cell = Vector2i(column,row)
	actor.position = game.world.config.cell_position(actor.cell)
	game.world.water_support.clear_support()
	game.world.camera.snap_to_player()
	game.world.activation.refresh(true)
func freeze() -> void:
	game.set_physics_process(false)
	game.world.set_active(false)
	game.world.player.set_physics_process(false)
	game.world.water_support.set_physics_process(false)
func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position=at
	event.index=3
	event.pressed=pressed
	get_viewport().push_input(event,true)
func drag(at: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.position=at
	event.relative=relative
	event.index=3
	get_viewport().push_input(event,true)
func mouse(at: Vector2, pressed: bool, emulated: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position=at
	event.button_index=MOUSE_BUTTON_LEFT
	if emulated: event.device=InputEvent.DEVICE_ID_EMULATION
	event.pressed=pressed
	get_viewport().push_input(event,true)
func run() -> void:
	SaveData.storage_path="user://post_m14_tests.cfg"
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SaveData.storage_path+suffix)
	SaveData.load_profile()
	SaveData.sound_enabled=false
	game=load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	await frames()
	game.hud.level_selected.connect(func(_index: int) -> void: selections+=1)
	game.world.water_support.hazard.connect(func(_player: CrossingPlayer) -> void: hazards+=1)
	await ui_checks()
	await water_checks()
	await destination_checks()
	await firework_checks()
	for id in ["cng","rickshaw"]:
		var art: VehicleVisualConfig=load("res://resources/vehicles/"+id+".tres")
		check(art.is_valid() and art.texture.get_size()==Vector2(116,58),id+" art and texture valid")
		check(art.collision_size==Vector2(92,38) and art.base_speed==(85 if id=="rickshaw" else 150),id+" collision and M13 speed preserved")
	game.queue_free()
	await frames()
	print("POST M14 RESULTS: %d passed, %d failed"%[passed,failed])
	get_tree().quit(1 if failed else 0)

func ui_checks() -> void:
	game.show_menu()
	await frames()
	var scroll: LevelListScroll=game.hud.overlay.find_child("LevelScroll",true,false)
	var first: Button=scroll.find_child("Level_01",true,false)
	for i in range(15):
		var card: Button=scroll.find_child("Level_%02d"%(i+1),true,false)
		check(card!=null and card.custom_minimum_size.y>=80,"Large card "+str(i+1))
		check(not card.text.contains("BEST") and not card.text.contains("Target") and not card.text.contains("\n"),"Reduced card text "+str(i+1))
		check(card.text.contains(game.CAMPAIGN.levels[i].display_name) and card.text.contains("☆☆☆"),"Name and stars "+str(i+1))
	var wheel:=InputEventMouseButton.new()
	wheel.position=first.get_global_rect().get_center()
	wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed=true
	get_viewport().push_input(wheel,true)
	await frames()
	check(scroll.scroll_vertical>0,"Native mouse wheel scroll remains available")
	scroll.scroll_vertical=0
	await frames()

	var actor_at := game.world.player.position
	var start := first.get_global_rect().get_center()
	touch(start,true)
	mouse(start,true,true) # Android touch-generated mouse must not reach Button.
	drag(start-Vector2(0,90),Vector2(0,-90))
	touch(start-Vector2(0,90),false)
	mouse(start-Vector2(0,90),false,true)
	await frames()
	check(scroll.scroll_vertical>=85 and selections==0 and game.state==CrossingGame.State.MENU,"Touch drag starting on a card scrolls without selecting")
	check(game.world.player.position==actor_at and not game.controls.enabled,"Menu gesture never moves gameplay")
	var locked: Button=scroll.find_child("Level_03",true,false)
	start=locked.get_global_rect().get_center()
	touch(start,true)
	touch(start,false)
	check(selections==0 and locked.disabled,"Locked card cannot activate")
	scroll.scroll_vertical=0
	await frames()
	start=first.get_global_rect().get_center()
	mouse(start,true)
	var motion:=InputEventMouseMotion.new()
	motion.position=start-Vector2(0,80)
	motion.relative=Vector2(0,-80)
	motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion,true)
	mouse(motion.position,false)
	await frames()
	check(scroll.scroll_vertical>=75 and selections==0,"Mouse drag scrolls without card activation")
	scroll.scroll_vertical=0
	await frames()
	start=first.get_global_rect().get_center()
	touch(start,true)
	touch(start+Vector2(2,2),false)
	await frames()
	check(selections==1 and game.state==CrossingGame.State.PLAYING,"Stationary finger tap opens level once")
	# Gameplay swipe still goes through the original input adapter.
	freeze()
	game.world.player.enabled=true
	var cell:=game.world.player.cell
	touch(Vector2(600,540),true)
	drag(Vector2(670,540),Vector2(70,0))
	touch(Vector2(670,540),false)
	check(game.world.player.cell==cell+Vector2i.RIGHT,"Gameplay swipe preserved after menu closes")
	game.start_run(42)
	game.show_menu()
	SaveData.level_stars[game.CAMPAIGN.levels[0].level_id]=2
	game.show_menu()
	await frames()
	check(game.hud.overlay.find_child("Level_01",true,false).text.contains("★★☆"),"Stored stars visible")

func water_checks() -> void:
	for level in game.CAMPAIGN.levels: SaveData.completed_levels[level.level_id]=true
	for direction in [-1,1]:
		for length in [128.0,176.0,224.0]:
			for speed in [60.0,120.0]:
				game.select_level(6)
				freeze()
				var lane:=game.world.water_lanes[0]
				lane.config=lane.config.duplicate() as WaterLaneConfig
				lane.config.direction=direction
				lane.config.platform_speed=speed
				lane.config.speed_variation=0
				lane.config.platform_length=length
				for i in range(lane.platforms.size()):
					var item:=lane.platforms[i]
					item.length=length
					item.travel=-10000-i*500
					item.position.x=-10000 if direction>0 else 10000
				var deck:=lane.platforms[0]
				var half:=deck.support_half_width()
				var center:=lane.width+half-2 if direction>0 else -half+2
				deck.position.x=center
				deck.travel=center if direction>0 else lane.width-center
				deck.motion_x=0
				locate(lane.row)
				game.world.player.position.x=center
				var support:=game.world.water_support
				var before:=hazards
				check(support.check_landing() and deck.carrying_player,"Partial deck remains valid beyond player/boat center boundary")
				lane._physics_process(1.0/speed)
				support._physics_process(1.0/speed)
				check(game.lives==3 and support.support==deck,"Survives last meaningful pixel of support both directions/sizes/speeds")
				# Normal pause does not advance the pool or lose its pin.
				game.toggle_pause()
				var paused_at:=deck.position
				await frames()
				check(deck.position==paused_at and deck.carrying_player,"Pause at edge preserves support")
				game.toggle_pause()
				freeze()
				# Deliberately huge step beyond pool cutoff: carrying pin prevents teleport.
				lane._physics_process(2.0)
				check(deck.carrying_player and deck.travel>lane.width,"Carrying platform not recycled before hazard resolution")
				support._physics_process(2.0)
				check(game.lives==2 and hazards==before+1 and support.support==null and not deck.carrying_player,"Fully cleared deck causes exactly one normal death and unpins")
				support._physics_process(0.1)
				check(game.lives==2 and hazards==before+1,"No repeated death callback")
				lane._physics_process(0.1)
				check(deck.travel<lane.width,"Pool reclaims exited boat after rider resolution")
				game._physics_process(2)
				check(game.world.player.cell==game.world.config.spawn_cell,"Normal respawn at Start")
				await frames()
	# Retry detaches an active support and replaces the old pool.
	game.select_level(6)
	freeze()
	var lane:=game.world.water_lanes[0]
	var deck:=lane.platforms[3]
	deck.position.x=608
	locate(lane.row)
	game.world.player.position.x=608
	check(game.world.water_support.check_landing(),"Retry fixture supported")
	game.start_run(42)
	await frames()
	check(not is_instance_valid(deck) and game.world.water_support.support==null,"Retry clears rider and old boat pool")

	# Near-edge hops must retain fractional water X, then snap safely onto land.
	for x in [90.0,1190.0]:
		game.select_level(6)
		freeze()
		var world:=game.world
		var first:=world.water_lanes[0]
		var second:=world.water_lanes[1]
		for water in [first,second]:
			for item in water.platforms: item.position.x=-10000
			water.platforms[0].position.x=x
			water.platforms[0].motion_x=0
		locate(first.row,0 if x<100 else 17)
		world.player.position.x=x
		check(world.water_support.check_landing(),"Supported near-edge jump fixture")
		var old:=world.water_support.support
		world.player.request_step(Vector2i(0,1))
		world.player._physics_process(world.player.hop_duration+0.01)
		check(game.lives==3 and world.water_support.support==second.platforms[0] and not old.carrying_player,"Near-edge jump transfers to next valid platform")
		world.player.request_step(Vector2i(0,1))
		world.player._physics_process(world.player.hop_duration+0.01)
		check(game.lives==3 and world.water_support.support==null and not second.platforms[0].carrying_player,"Near-edge jump back to land clears boat support")
		# A long route deactivates and reactivates the SAME pool.
		var retained:=second.platforms[0]
		locate(world.config.goal_row-1)
		locate(first.row-1)
		check(second.platforms[0]==retained and is_instance_valid(retained),"Backtracking retains platform identity")
		await frames()

func destination_checks() -> void:
	SaveData.completed_levels.clear()
	for i in range(15):
		var source:=game.CAMPAIGN.levels[i]
		check(source.playability_errors().is_empty() and source.environment.destination_art!=null,"Valid layout and destination facade level "+str(i+1))
		for column in [4,8,12]:
			game.select_level(i)
			freeze()
			var world:=game.world
			check(world.config.goal_columns==[4,8,12] and world.goals.size()==3,"Three reachable alternatives level "+str(i+1))
			var nodes:=world.destinations.get_child_count()
			locate(world.config.goal_row-1,column)
			world.decorations.refresh(true)
			check(world.can_enter_cell(Vector2i(column,world.config.goal_row)),"Alternative entry permitted")
			locate(0)
			locate(world.config.goal_row-1,column)
			check(world.destinations.get_child_count()==nodes,"Backtrack/reactivation does not duplicate goals")
			# Actual player hop calls landing/completion, not finish_game fixture.
			world.player.request_step(Vector2i.UP*-1)
			world.player._physics_process(world.player.hop_duration+0.01)
			check(game.state==CrossingGame.State.LEVEL_COMPLETE and game.destinations_reached==1,"Any one actual goal hop finishes level "+str(i+1)+" column "+str(column))
			var score:=game.score
			var coins:=SaveData.coins
			var panel:=game.hud.result_panel
			game._on_step_completed(Vector2i(column,world.config.goal_row))
			game.finish_game(true,"duplicate")
			check(game.score==score and SaveData.coins==coins and game.hud.result_panel==panel,"Completion/reward/result once only")
			await frames()
	for index in [0,14]:
		game.select_level(index)
		freeze()
		locate(game.world.config.goal_row-1,4)
		game._on_collision(game.world.player)
		check(game.lives==2 and game.state==CrossingGame.State.RESPAWNING,"Death near short/long destination uses normal reset")
		game._physics_process(game.world.config.hit_reset_seconds+0.1)
		freeze()
		check(game.world.player.cell==game.world.config.spawn_cell and game.world.goals.size()==3,"Death reset retains three unclaimed choices")
		locate(game.world.config.goal_row-1,12)
		game.world.player.request_step(Vector2i(0,1))
		game.world.player._physics_process(game.world.player.hop_duration+0.01)
		check(game.state==CrossingGame.State.LEVEL_COMPLETE,"Another finish works after death/respawn")
		await frames()

	SaveData.load_profile()
	check(SaveData.completed_levels.size()==15,"Stable completion IDs survive save reload")

func firework_checks() -> void:
	for exit_action in ["retry","next","menu","hide","free"]:
		game.select_level(0)
		freeze()
		SaveData.level_scores[game.world.config.level_id]=100
		game.score=1000
		game.finish_game(true,"record")
		var panel:=game.hud.result_panel
		var effect:=panel.celebration
		check(effect!=null and game.previous_best==100,"Genuine previous-best record starts celebration")
		effect.set_process(false)
		effect._process(0.1)
		check(effect.bursts.size()>=4 and effect.bursts.size()<=6 and effect.emitted==0 and effect.sound_events==0,"Four to six rockets launch before any explosion/audio")
		for rocket in effect.bursts:
			check(rocket.start.y>720 and rocket.center.y<300,"Rocket starts below screen and travels upward")
		var bounded:=true
		for tick in range(2400):
			effect._process(0.05)
			bounded=bounded and effect.bursts.size()<=36 and effect.get_child_count()==1
		check(bounded and effect.waves>=25 and effect.emitted>=75,"Two simulated minutes of bounded repeating waves")
		match exit_action:
			"retry": panel.replay_button.pressed.emit()
			"next": panel.next_button.pressed.emit()
			"menu": panel.select_button.pressed.emit()
			"hide": panel.hide()
			"free": game.hud.hide_screen()
		check(effect.finished and effect.bursts.is_empty() and not effect.voice.playing,"Immediate firework cleanup "+exit_action)
		await frames()
	for completed in [false,true]:
		game.select_level(0)
		freeze()
		SaveData.level_scores[game.world.config.level_id]=99999
		game.score=1
		game.finish_game(completed,"no record")
		check(game.hud.result_panel.celebration==null,"No celebration on failure or worse completion")

	var detached:=ResultCelebration.new()
	add_child(detached)
	detached._process(0.1)
	remove_child(detached)
	check(detached.finished and detached.bursts.is_empty() and not detached.voice.playing,"Scene-tree removal stops celebration")
	detached.free()
