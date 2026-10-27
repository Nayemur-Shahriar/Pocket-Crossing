class_name TrafficLane
extends Node2D
## Type-specific cruise speeds; front-to-back headway limiting prevents overtaking.
signal collision(player: CrossingPlayer)
const VEHICLE_SCENE := preload("res://scenes/actors/vehicle.tscn")
const MAX_VEHICLE_WIDTH := 144.0
var presentation_theme: LevelThemeConfig = LevelThemeConfig.new()
var fleet: Array[TrafficVehicle] = [] # Ordered front to back; maintained only on spawn/exit.
var config: LaneConfig
var level_config: LevelConfig
var rng := RandomNumberGenerator.new()
var spawn_left: float = 0.0
var active_seconds: float = 0.0
var current_speed: float = 0.0
var effect_scale: float = 1.0
var _variation_phase: float = 0.0
var _last_train_cycle: int = -1

func setup(lane: LaneConfig, seed_value: int, level: LevelConfig = null) -> void:
	process_physics_priority = -5 # Set all speeds before actor motion.
	config = lane
	level_config = level
	rng.seed = seed_value
	_variation_phase = rng.randf_range(0.0, TAU)
	active_seconds = 0.0
	_last_train_cycle = -1
	current_speed = speed_at(0.0)
	spawn_left = rng.randf_range(config.spawn_min, config.spawn_max)
	# Seed only spaced vehicles. Mirroring gives both directions an empty entry.
	var spacing := maxf(435.0, vehicle_envelope() + required_gap() + 24.0)
	var initial_phase := rng.randf_range(0.0, spacing)
	for i in range(0 if config.pattern == "railway" else 3):
		var travel_x := 100.0 + initial_phase + i * spacing
		if travel_x > 1210.0:
			break
		spawn_vehicle(travel_x if config.direction > 0 else 1280.0 - travel_x)

func speed_at(seconds: float) -> float:
	var start := level_config.starting_speed_scale if level_config != null else 0.72
	var finish := level_config.final_speed_scale if level_config != null else 1.0
	var ramp := level_config.difficulty_ramp_seconds if level_config != null else 60.0
	var t := clampf(seconds / maxf(ramp, 0.01), 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	# Fade in variation with challenge; a new run begins at the exact easy speed.
	var variation := sin(seconds * TAU / maxf(config.variation_period, 1.0) + _variation_phase)
	return config.speed * config.speed_modifier * lerpf(start, finish, t) * (1.0 + variation * config.speed_variation * t)

func required_gap() -> float:
	var maximum_scale := 1.0
	if level_config != null:
		maximum_scale = maxf(level_config.starting_speed_scale, level_config.final_speed_scale)
	var factor := 1.0
	for id in config.vehicle_types:
		factor = maxf(factor, VehicleLibrary.find_visual(id).base_speed / 150.0)
	var maximum_speed := config.speed * config.speed_modifier * factor * maximum_scale * (1.0 + config.speed_variation)
	return maxf(config.minimum_clear_gap, maximum_speed * config.minimum_gap_seconds)

func has_spawn_space(x: float) -> bool:
	for vehicle: TrafficVehicle in get_children():
		if vehicle.is_queued_for_deletion():
			continue
		# Conservative visual envelope, not the smaller collision rectangle.
		var clear_space := absf(vehicle.position.x - x) - vehicle_envelope()
		if clear_space < required_gap():
			return false
	return true

func spawn_vehicle(x: float) -> TrafficVehicle:
	if not has_spawn_space(x):
		return null
	var vehicle := VEHICLE_SCENE.instantiate() as TrafficVehicle
	vehicle.speed = current_speed
	vehicle.direction = config.direction
	vehicle.paint = config.vehicle_colors[rng.randi_range(0, config.vehicle_colors.size() - 1)]
	vehicle.vehicle_type = config.vehicle_types[rng.randi_range(0, config.vehicle_types.size() - 1)]
	vehicle.is_van = vehicle.vehicle_type == "truck"
	vehicle.position = Vector2(x, 0)
	vehicle.hit_player.connect(func(player: CrossingPlayer) -> void: collision.emit(player))
	add_child(vehicle)
	vehicle.apply_theme(presentation_theme)
	var index := 0
	while index < fleet.size() and fleet[index].position.x * config.direction > x * config.direction:
		index += 1
	fleet.insert(index, vehicle)
	vehicle.tree_exiting.connect(func() -> void: fleet.erase(vehicle))
	update_vehicle_speeds(1.0 / 60.0)
	return vehicle

func _physics_process(delta: float) -> void:
	active_seconds += delta
	current_speed = speed_at(active_seconds) * effect_scale
	update_vehicle_speeds(delta)
	spawn_left -= delta
	if config.pattern == "railway":
		queue_redraw()
	if spawn_left <= 0.0 and spawning_allowed():
		var vehicle := spawn_vehicle(-vehicle_envelope() if config.direction > 0 else 1280.0 + vehicle_envelope())
		# Retry next physics frame if blocked; never accumulate a spawn burst.
		if vehicle != null:
			if config.pattern == "railway":
				_last_train_cycle = int(active_seconds / config.cycle_seconds)
			spawn_left = rng.randf_range(config.spawn_min, config.spawn_max)

func vehicle_envelope() -> float:
	var width := MAX_VEHICLE_WIDTH
	for id in config.vehicle_types:
		var visual := VehicleLibrary.find_visual(id)
		if visual != null:
			width = maxf(width, visual.spacing_envelope)
	return width

func spawning_allowed() -> bool:
	if config.pattern == "steady":
		return true
	var phase := fmod(active_seconds+config.phase_offset, config.cycle_seconds)
	if config.pattern == "railway":
		return phase >= config.open_seconds + config.warning_seconds and int(active_seconds / config.cycle_seconds) != _last_train_cycle
	return phase >= config.open_seconds

func _draw() -> void:
	if config == null or config.pattern != "railway":
		return
	var phase := fmod(active_seconds+config.phase_offset, config.cycle_seconds)
	var warning := phase >= config.open_seconds or get_child_count() > 0
	var color := Color("f3b665") if warning else Color("88cbaa")
	for x in [28, 1252]:
		draw_circle(Vector2(x, 0), 10, color)
	if warning:
		draw_string(ThemeDB.fallback_font, Vector2(460, -21), "TRAIN APPROACHING — WAIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, color)

func set_speed_scale(value: float) -> void:
	effect_scale = clampf(value, 0.4, 1.0)
	current_speed = speed_at(active_seconds) * effect_scale
	update_vehicle_speeds(1.0 / 60.0)

func apply_theme(theme: LevelThemeConfig) -> void:
	presentation_theme = theme
	for vehicle: TrafficVehicle in get_children():
		vehicle.apply_theme(theme)

func desired_speed(vehicle: TrafficVehicle) -> float:
	return current_speed * vehicle.visual.base_speed / 150.0

func update_vehicle_speeds(delta: float) -> void:
	var leader: TrafficVehicle
	# The configured gap is identical for every follower in this physics update.
	var gap := required_gap() if fleet.size() > 1 else 0.0
	for vehicle in fleet:
		if vehicle.is_queued_for_deletion(): continue
		vehicle.speed = desired_speed(vehicle)
		if leader != null:
			var separation := (leader.position.x - vehicle.position.x) * config.direction
			var half_lengths := (leader.visual.visual_size.x + vehicle.visual.visual_size.x) * 0.5
			# Preserve a real crossing gap even when a fast car catches a rickshaw.
			var spare := maxf(0.0, separation - half_lengths - gap)
			vehicle.speed = minf(vehicle.speed, leader.speed + spare / maxf(delta, 0.001))
		leader = vehicle
