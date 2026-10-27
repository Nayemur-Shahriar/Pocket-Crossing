extends Node
var passed := 0
var failed := 0
var game: CrossingGame
func _ready() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error("FAIL "+label)
func run() -> void:
	SaveData.storage_path = "user://m13_balance_test.cfg"
	SaveData.sound_enabled = false
	var originals := {}
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = SaveData.PATH+suffix
		originals[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	game = load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	var expected := [5,6,7,8,8,9,9,10,11,12,14,15,17,18,20]
	var manifests: Array = []
	for i in range(15):
		var level: LevelConfig = game.CAMPAIGN.levels[i]
		SaveData.completed_levels[level.level_id] = true
		var data := {"number":i+1,"name":level.display_name,"difficulty":level.difficulty_label,"time":level.time_limit,"star_time_fraction":level.star_time_fraction,"score_target":level.score_target,"forward_points":level.forward_points,"destination_points":level.destination_points,"seconds_bonus":level.seconds_bonus,"life_bonus":level.life_bonus,"road":[],"rail":[],"water":[],"coins":[],"powers":[]}
		var hazards := 0
		var row := 0
		var directions := {}
		for section in level.sections:
			for lane in section.road_lanes:
				hazards += 1
				directions[lane.direction] = true
				check(lane.validation_errors().is_empty(),"Valid road settings")
				data.road.append({"speed":lane.speed,"modifier":lane.speed_modifier,"direction":lane.direction,"types":lane.vehicle_types,"spawn_min":lane.spawn_min,"spawn_max":lane.spawn_max,"clear_gap":lane.minimum_clear_gap,"gap_seconds":lane.minimum_gap_seconds})
			for track in section.railway_tracks:
				hazards += 1
				check(track.validation_errors().is_empty() and track.warning_seconds >= 2.5,"Full readable railway warning")
				data.rail.append({"speed":track.speed,"direction":track.direction,"warning":track.warning_seconds,"interval":track.interval_min,"safe_delay":track.safe_delay})
			for lane in section.water_lanes:
				hazards += 1
				check(lane.validation_errors().is_empty() and lane.platform_length <= 224,"Shorter valid water decks")
				check(lane.pitch_max()-lane.platform_length <= 68.01,"Bounded open water gap")
				check(lane.platform_speed*(1+lane.speed_variation)*level.hop_seconds <= (lane.platform_length-36)*0.25,"Hop drift leaves useful deck")
				var platform := FloatingPlatform.new()
				platform.setup(lane)
				check(platform.supports_x(lane.platform_length/2-18) and not platform.supports_x(lane.platform_length/2-17),"Actual support tracks resized art")
				platform.free()
				data.water.append({"type":lane.visual.display_name if lane.visual != null else lane.platform_type,"length":lane.platform_length,"speed":lane.platform_speed,"direction":lane.direction,"pitch_min":lane.pitch_min(),"pitch_max":lane.pitch_max()})
			for pickup in section.pickups:
				check(section.is_rest_area(),"Pickup only on resting ground")
				if pickup.power == null: data.coins.append([pickup.cell.x,row+pickup.cell.y])
				else: data.powers.append({"effect":pickup.power.effect,"cell":[pickup.cell.x,row+pickup.cell.y],"duration":pickup.power.duration})
			row += section.row_count()
		check(hazards == expected[i] and hazards >= 5,"Hazard count excludes rest/start/goal for level "+str(i+1))
		check(directions.size()==2,"Roads have both directions")
		check(level.playability_errors().is_empty() and level.starting_lives==3 and level.spawn_protection<=0.35,"Valid level/lives")
		check(level.rate_completion(0,1)==1 and level.rate_completion(0,2)==2 and level.rate_completion(level.time_limit*level.star_time_fraction,2)==3,"Ordered attainable star thresholds")
		check(data.coins.size()>=4 and data.coins.size()<=12 and data.powers.size()<=3,"Economy caps")
		if i>=3:check(not data.powers.is_empty(),"Authored powers preserved")
		data.hazards = hazards
		data.rows = row
		manifests.append(data)
	# Verify measurable motion, lane modifier, both directions and legacy neutral base.
	for direction in [-1,1]:
		for id in ["rickshaw","cng","small_car","microbus","local_bus","pickup","delivery_van","medium_truck","large_truck"]:
			var rules := LevelConfig.new()
			rules.starting_speed_scale = 1
			rules.final_speed_scale = 1
			var config := LaneConfig.new()
			config.vehicle_types = [id]
			config.direction = direction
			config.speed_modifier = 1.1
			config.speed_variation = 0
			var lane := TrafficLane.new()
			add_child(lane)
			lane.setup(config,42,rules)
			lane.set_physics_process(false)
			for actor in lane.get_children(): actor.free()
			var actor := lane.spawn_vehicle(640)
			actor.set_physics_process(false)
			var desired := VehicleLibrary.find_visual(id).base_speed*1.1
			actor._physics_process(1.0)
			check(is_equal_approx(actor.position.x,640+direction*desired),"Measured one-second type-specific movement: "+id)
			lane.set_speed_scale(0.65)
			check(is_equal_approx(actor.speed,desired*0.65),"Slow Traffic preserves relative type speed")
			lane.free()
	# Mixed extremes must not overtake or close the crossing window, in either direction.
	for direction in [-1,1]:
		var config := LaneConfig.new()
		config.direction = direction
		config.speed_variation = 0
		config.vehicle_types = ["rickshaw"]
		var rules := LevelConfig.new()
		rules.starting_speed_scale = 1
		rules.final_speed_scale = 1
		var lane := TrafficLane.new()
		add_child(lane)
		lane.setup(config,42,rules)
		lane.set_physics_process(false)
		for actor in lane.get_children():actor.free()
		var slow := lane.spawn_vehicle(900 if direction==1 else 380)
		config.vehicle_types = ["small_car"]
		var fast := lane.spawn_vehicle(200 if direction==1 else 1080)
		slow.set_physics_process(false)
		fast.set_physics_process(false)
		var fair := true
		for tick in range(360):
			lane.update_vehicle_speeds(1.0/60)
			slow._physics_process(1.0/60)
			fast._physics_process(1.0/60)
			var gap: float = (slow.position.x-fast.position.x)*direction-116
			fair = fair and gap >= lane.required_gap()-0.01
		check(fair and is_equal_approx(fast.speed,slow.speed),"Fast follower preserves real crossing gap")
		lane.free()
	# Continuous effect, sound synchronization, bounded objects and immediate navigation cleanup.
	for exit_action in ["retry","next","menu","hide"]:
		game.select_level(3)
		game.world.set_active(false)
		SaveData.level_scores[game.world.config.level_id] = 100
		game.score = 2000
		SaveData.sound_enabled = true
		game.finish_game(true,"test")
		var panel := game.hud.result_panel
		var effect := panel.celebration
		effect.set_process(false)
		var bounded := true
		for tick in range(1200):
			effect._process(0.05)
			bounded = bounded and effect.bursts.size()<=36 and effect.get_child_count()==1
		check(game.previous_best==100 and game.new_high_score,"Compared previous best before overwrite")
		check(bounded and effect.emitted>=40 and effect.sound_events>0 and effect.sound_events<=effect.emitted and not effect.finished,"60-second bounded repeating effect with rate-limited explosion sound")
		match exit_action:
			"retry":panel.replay_button.pressed.emit()
			"next":panel.next_button.pressed.emit()
			"menu":panel.select_button.pressed.emit()
			"hide":panel.hide()
		check(effect.finished and effect.bursts.is_empty() and not effect.voice.playing,"Immediate cleanup on "+exit_action)
		game.hud.hide_screen()
		await get_tree().process_frame
	SaveData.sound_enabled = false
	game.select_level(0)
	game.world.set_active(false)
	game.score = 1234
	game.furthest_row = 4
	game._begin_respawn(0.9)
	game._set_state(CrossingGame.State.PLAYING)
	game._on_step_completed(Vector2i(8,2))
	check(game.score==1234 and game.furthest_row==4,"Respawn cannot farm forward points")
	SaveData.unlocked_characters.coral = true
	SaveData.coins = 0
	var old_price: int = CharacterCatalog.PRICES.coral
	CharacterCatalog.PRICES.set("coral",500)
	check(SaveData.choose_character("coral") and SaveData.coins==0,"Price edits never relock owned skins")
	CharacterCatalog.PRICES.set("coral",old_price)
	check(CharacterCatalog.find_skin("coral").cost==20 and CharacterCatalog.find_skin("violet").cost==40,"Gradual prices retained")
	var bad := LaneConfig.new()
	bad.speed_modifier = NAN
	check(not bad.validation_errors().is_empty(),"Invalid modifier rejected")
	for voice in Audio.voices: voice.stop()
	game.queue_free()
	await get_tree().process_frame
	game = null
	OS.delay_msec(80)
	for path in originals:
		check((FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray())==originals[path],"Normal save untouched")
	var file := FileAccess.open("res://docs/M13_BALANCE_DATA.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifests,"\t"))
	file.close()
	print("BALANCE RESULTS: %d passed, %d failed" % [passed,failed])
	get_tree().quit.call_deferred(1 if failed else 0)
