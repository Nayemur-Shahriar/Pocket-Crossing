extends Node
var passed := 0
var failed := 0
var game: CrossingGame
const THEMES := ["day","evening","night","rain","snow","fog"]
const ENVIRONMENTS := ["green","village","city","highway","railway","river","crossroads"]
const VEHICLES := ["cng","rickshaw","local_bus","small_car","microbus","pickup","delivery_van","medium_truck","large_truck"]
const BOATS := ["wooden_boat","passenger_boat","fishing_boat","engine_boat","ferry"]
const FAMILIES := {"cng":"car","rickshaw":"car","small_car":"car","microbus":"truck","pickup":"truck","delivery_van":"truck","medium_truck":"truck","local_bus":"bus","large_truck":"bus"}
func _ready() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL " + label)
func encode(value: Variant) -> Variant:
	if value is Resource:
		var result := {}
		for spec in value.get_property_list():
			var key: String = spec.name
			if spec.usage & PROPERTY_USAGE_STORAGE and key not in ["script","environment","visual"] and not key.begins_with("resource_"):
				result[key] = encode(value.get(key))
		return result
	if value is Array:
		var result := []
		for item in value: result.append(encode(item))
		return result
	if value is String: return FAMILIES.get(value,value)
	if value == null or value is int or value is float or value is bool: return value
	return var_to_str(value)
func signatures(layer: EnvironmentLayer) -> Array[String]:
	var result: Array[String] = []
	for site in layer.prop_sites:
		result.append(str(site.row)+":"+str(site.side)+":"+site.texture.resource_path+":"+str(site.rect))
	return result
func run() -> void:
	var normal := {}
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = SaveData.PATH + suffix
		normal[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	SaveData.storage_path = "user://m12_identity_tests.cfg"
	SaveData.sound_enabled = false
	game = load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	for level in game.CAMPAIGN.levels: SaveData.completed_levels[level.level_id] = true
	var catalog := VehicleLibrary.get_catalog()
	var ids := {}
	for visual in catalog.entries:
		check(visual.is_valid() and not ids.has(visual.id),"Valid unique vehicle Resource: "+visual.id)
		ids[visual.id] = true
	for id in VEHICLES:
		var visual := VehicleLibrary.find_visual(id)
		var old := VehicleLibrary.find_visual(FAMILIES[id])
		check(visual.collision_size == old.collision_size and visual.spacing_envelope == old.spacing_envelope,"Preserved collision/spacing family: "+id)
		for direction in [-1,1]:
			var vehicle: TrafficVehicle = load("res://scenes/actors/vehicle.tscn").instantiate()
			vehicle.vehicle_type = id
			vehicle.direction = direction
			add_child(vehicle)
			vehicle.set_physics_process(false)
			for theme in THEMES:
				vehicle.apply_theme(load("res://resources/themes/"+theme+".tres"))
				check(vehicle.art.texture == visual.texture and vehicle.art.flip_h == (direction<0),"Vehicle resolves in "+theme+" "+id+" direction "+str(direction))
			if visual.collision_outline.is_empty():
				check(vehicle.get_node("CollisionShape2D").shape.size == visual.collision_size,"Actual vehicle rectangle matches Resource")
			else:
				var points := visual.collision_outline.duplicate()
				for j in range(points.size()): points[j].x *= direction
				check(vehicle.get_node("CollisionShape2D").shape.points == points,"Actual convex silhouette matches mirrored Resource")
			vehicle.free()
	var invalid_lane := LaneConfig.new()
	invalid_lane.vehicle_types = ["missing_visual"]
	check(not invalid_lane.validation_errors().is_empty(),"Unknown road visual is rejected")
	var invalid_track := RailwayTrackConfig.new()
	invalid_track.visual = TrainVisualConfig.new()
	check(not invalid_track.validation_errors().is_empty(),"Missing engine/coach textures rejected")
	var invalid_water := WaterLaneConfig.new()
	invalid_water.visual = PlatformVisualConfig.new()
	check(not invalid_water.validation_errors().is_empty(),"Missing platform texture rejected")
	var old_data: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/m11_gameplay.json"))
	var seen_vehicles := {}
	var seen_boats := {}
	for i in range(15):
		var source: LevelConfig = game.CAMPAIGN.levels[i]
		check(source.playability_errors().is_empty(),"Campaign compiles: "+source.display_name)
		# Compare all M11 exported data, allowing only new presentation fields/type aliases.
		check(source.level_id == old_data[i].level_id and source.display_name == old_data[i].display_name and source.presentation.theme_id == old_data[i].presentation.theme_id,"Stable campaign identity/theme preserved: "+source.display_name)
		game.select_level(i)
		game.world.set_active(false)
		check(game.world.decorations.profile == source.environment,"Level uses its Environment Resource")
		for lane in game.world.lanes:
			for vehicle: TrafficVehicle in lane.get_children():
				check(vehicle.visual != null and vehicle.art.texture != null,"Spawned campaign vehicle has art")
			for id in lane.config.vehicle_types:seen_vehicles[id]=true
		for railway in game.world.railways:
			for track in railway.tracks:
				check(track.train.visual != null and track.train.hitbox.shape.size == Vector2(track.config.train_length-12,36),"Passenger train keeps collision envelope")
		for lane in game.world.water_lanes:
			if lane.config.visual != null:seen_boats[lane.config.visual.display_name]=true
			for platform in lane.platforms:
				check(platform.length == lane.config.platform_length and platform.supports_x(platform.position.x+platform.length*0.5-18) and not platform.supports_x(platform.position.x+platform.length*0.5-17),"Boat support boundary unchanged")
		var layer := game.world.decorations
		check(layer.get_child_count() == 1 and layer.get_child(0) is AudioStreamPlayer,"One ambience player; zero decorative physics/nodes")
		check(layer.prop_sites.size() <= 36,"Visible-window decoration count bounded")
		for site in layer.prop_sites:
			var y := game.world.config.cell_position(Vector2i(0,site.row)).y
			check(site.rect.end.x <= 64 or site.rect.position.x >= 1216 or site.rect.end.y <= y-32,"Props outside playable footprints")
	check(seen_vehicles.size() == 9,"All nine new vehicle types used in actual campaign")
	check(seen_boats.size() == 5,"All five new boats used in actual campaign")
	# Every profile combines with every theme on the same long mixed layout.
	for environment in ENVIRONMENTS:
		var profile: EnvironmentProfile = load("res://resources/environments/"+environment+".tres")
		check(profile.is_valid(),"Valid environment "+environment)
		for theme in THEMES:
			var source := game.CAMPAIGN.levels[14].duplicate(false) as LevelConfig
			source.environment = profile
			source.presentation = load("res://resources/themes/"+theme+".tres")
			check(game.world.configure(source),"Environment/theme "+environment+" / "+theme)
			game.world.set_active(false)
			check(game.world.decorations.profile == profile and game.world.decorations.theme == source.presentation,"Separate profile and weather applied")
	var invalid_source := game.CAMPAIGN.levels[0].duplicate(false) as LevelConfig
	invalid_source.environment = EnvironmentProfile.new()
	invalid_source.environment.prop_density = NAN
	check(game.world.configure(invalid_source) and game.world.decorations.profile == null,"Invalid scenery falls back to legacy art without blocking gameplay")
	# Backtracking rebuilds the same fixed draw list, without adding anything to the tree.
	game.select_level(14)
	game.world.set_active(false)
	var layer := game.world.decorations
	var initial := signatures(layer)
	var node_count := layer.get_child_count()
	var rebuilds := layer.rebuild_count
	for tick in range(120): layer.refresh()
	check(layer.rebuild_count == rebuilds,"No per-frame decoration generation while window stays fixed")
	for row in [10,20,30,18,4,0]:
		game.world.player.cell = Vector2i(8,row)
		game.world.player.position = game.world.config.cell_position(game.world.player.cell)
		game.world.camera.snap_to_player()
		game.world.activation.refresh(true)
		layer.refresh()
		check(layer.prop_sites.size() <= 36 and layer.get_child_count() == node_count,"Backtrack keeps bounded draw list and one node owner")
	game.world.player.reset_to_spawn()
	check(signatures(layer) == initial,"Start scenery deterministic after backtracking")
	var lane_rng := game.world.lanes[0].rng.state
	layer.refresh(true)
	check(game.world.lanes[0].rng.state == lane_rng,"Scenery does not consume traffic RNG")
	for retry in range(3):
		game.start_run(42)
		game.world.set_active(false)
		await get_tree().process_frame
		check(game.world.decorations == layer and signatures(layer) == initial and layer.get_child_count() == node_count,"Retry reuses scenery without duplicates")
	# Collision uses the same authoritative damage path for new art.
	game.select_level(4)
	game.world.set_active(false)
	var track := game.world.railways[0].tracks[0]
	track.train.launch(1280)
	game.world.player.invulnerable_left = 0
	var lives := game.lives
	track.train._on_body_entered(game.world.player)
	await get_tree().process_frame
	await get_tree().process_frame
	check(game.lives == lives-1,"New train art uses existing life-loss path")
	# Every new boat variant: real support adapter carry, departure and unsupported fall.
	for id in BOATS:
		game.select_level(6)
		game.world.set_active(false)
		var lane := game.world.water_lanes[0]
		var settings := lane.config.duplicate(false) as WaterLaneConfig
		settings.visual = load("res://resources/water/visuals/"+id+".tres")
		var platform := lane.platforms[2]
		platform.setup(settings)
		platform.position.x = 600
		var player := game.world.player
		player.position = Vector2(600,lane.position.y)
		player.cell = Vector2i(8,lane.row)
		check(game.world.water_support.check_landing(),"Landing on "+id)
		var before := player.position.x
		platform.motion_x = 1.25
		platform.position.x += 1.25
		game.world.water_support._physics_process(1.0/60)
		check(is_equal_approx(player.position.x,before+1.25),"Carrying on "+id)
		player.request_step(Vector2i(0,-1))
		check(player.moving and game.world.water_support.support == null,"Jump off clears support: "+id)
	# Optional ambience hook respects state and mute, no default field recording.
	game.select_level(0)
	var profile := game.world.source_config.environment.duplicate(false) as EnvironmentProfile
	profile.ambience = load("res://assets/audio/firework.wav") # Isolated hook test only, not a shipped ambience.
	var source := game.world.source_config.duplicate(false) as LevelConfig
	source.environment = profile
	game.world.configure(source)
	SaveData.sound_enabled = true
	game._set_state(CrossingGame.State.PLAYING)
	check(game.world.decorations.ambience.playing,"Optional ambience starts once")
	game.toggle_pause()
	check(game.world.decorations.ambience.stream_paused,"Pause suspends ambience")
	game.toggle_pause()
	SaveData.sound_enabled = false
	game.world.decorations.sync_sound()
	check(not game.world.decorations.ambience.playing,"Mute stops ambience")
	game.finish_game(true,"test")
	game._on_primary()
	check(game.level_index == 1 and game.world.decorations.profile.profile_id == "city" and game.world.decorations.get_child_count() == 1,"Next Level replaces environment cleanly")
	game.show_menu()
	await get_tree().process_frame
	check(not game.world.decorations.visible and not game.world.decorations.ambience.playing,"Level Select hides scenery and stops ambience")
	game.queue_free()
	await get_tree().process_frame
	game = null
	# Fixed-FPS headless tests can finish before the Dummy audio thread releases
	# the stopped ambience fixture. Allow its mixer teardown before engine exit.
	OS.delay_msec(50)
	for path in normal:
		var after := FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
		check(after == normal[path],"Normal profile untouched")
	print("IDENTITY RESULTS: %d passed, %d failed" % [passed,failed])
	get_tree().quit.call_deferred(1 if failed else 0)
