class_name RoadLevel
extends Node2D

signal collision(player: CrossingPlayer)
signal water_hazard(player: CrossingPlayer)
@export var config: LevelConfig
var source_config: LevelConfig
var layout: CompiledLevelLayout
var configuration_error: String = ""
var goals: Dictionary = {}
var rewards: RewardField
var water_support: WaterSupport
var water_lanes: Array[WaterLane] = []
var lanes: Array[TrafficLane] = []
var railways: Array[RailwaySection] = []
var decorations: EnvironmentLayer
var presentation: WorldPresentation
var camera: LevelCamera
var activation: SectionActivation
var terrain: LongLevelTerrain
var _traffic_scale: float = -1.0
@onready var player: CrossingPlayer = $Player
@onready var traffic: Node2D = $Traffic
@onready var destinations: Node2D = $Destinations

func _ready() -> void:
	camera = LevelCamera.new()
	add_child(camera)
	presentation = WorldPresentation.new()
	add_child(presentation)
	decorations = EnvironmentLayer.new()
	add_child(decorations)
	activation = SectionActivation.new()
	add_child(activation)
	terrain = LongLevelTerrain.new()
	add_child(terrain)
	move_child(terrain, 0)
	player.spawned.connect(_on_player_spawned)
	water_support = WaterSupport.new()
	add_child(water_support)
	water_support.hazard.connect(func(body: CrossingPlayer) -> void: water_hazard.emit(body))
	rewards = RewardField.new()
	rewards.z_index = 3
	add_child(rewards)
	configure(config)

func configure(next_config: LevelConfig) -> bool:
	var compiled := SectionLayoutCompiler.compile(next_config)
	var errors := compiled.runtime_errors()
	if not errors.is_empty():
		configuration_error = "; ".join(errors)
		return false
	configuration_error = ""
	source_config = next_config
	layout = compiled
	config = compiled.config
	activation.clear()
	camera.setup(config, player)
	decorations.setup(compiled, camera)
	presentation.configure(config.presentation, camera)
	for goal in destinations.get_children():
		destinations.remove_child(goal)
		goal.queue_free()
	goals.clear()
	$BoardArt.config = config
	$BoardArt.visible = not camera.is_scrolling()
	$BoardArt.queue_redraw()
	terrain.visible = camera.is_scrolling()
	terrain.set_process(terrain.visible)
	terrain.setup(layout, camera)
	player.setup(config, can_enter_cell)
	for i in range(config.goal_columns.size()):
		var column := config.goal_columns[i]
		var goal := DestinationZone.new()
		goal.number = i + 1
		if config is MapConfig:
			goal.occupied_color = config.occupied_color
			goal.occupied_border = config.occupied_border
		goal.position = config.cell_position(Vector2i(column, config.goal_row))
		destinations.add_child(goal)
		goals[column] = goal
	reset(42)
	return true

func reset(seed_value: int = 0) -> void:
	activation.clear()
	_traffic_scale = -1.0
	water_support.clear_support()
	for lane in water_lanes:
		traffic.remove_child(lane)
		lane.queue_free()
	water_lanes.clear()
	traffic.process_mode = Node.PROCESS_MODE_INHERIT
	for lane in lanes:
		traffic.remove_child(lane)
		lane.queue_free()
	lanes.clear()
	for railway in railways:
		traffic.remove_child(railway)
		railway.queue_free()
	railways.clear()
	for column: int in goals:
		goals[column].set_occupied(false)
	var run_seed := seed_value if seed_value != 0 else int(Time.get_ticks_usec())
	for i in range(config.lanes.size()):
		var lane := TrafficLane.new()
		lane.position.y = config.cell_position(Vector2i(0, config.lanes[i].row)).y
		traffic.add_child(lane)
		lane.collision.connect(func(body: CrossingPlayer) -> void: collision.emit(body))
		lane.setup(config.lanes[i], run_seed + i * 7919, config)
		lanes.append(lane)
		activation.register(lane, lane.config.row, lane.config.row)
	for descriptor in layout.sections:
		if descriptor.kind == LevelSectionConfig.Kind.RAILWAY_SECTION:
			var railway := RailwaySection.new()
			traffic.add_child(railway)
			railway.collision.connect(func(body: CrossingPlayer) -> void: collision.emit(body))
			railway.setup(descriptor.resource, descriptor.first_row, config, run_seed + descriptor.first_row * 104729)
			railways.append(railway)
			activation.register(railway, descriptor.first_row, descriptor.first_row + descriptor.row_count - 1)
		if descriptor.kind == LevelSectionConfig.Kind.WATER_SECTION:
			for i in range(descriptor.resource.water_lanes.size()):
				var lane := WaterLane.new()
				traffic.add_child(lane)
				lane.setup(descriptor.resource.water_lanes[i], descriptor.first_row + i, config, run_seed + (descriptor.first_row+i)*104729)
				water_lanes.append(lane)
				activation.register(lane, lane.row, lane.row)
	water_support.setup(player, config, water_lanes)
	player.reset_to_spawn()
	player.apply_skin(SaveData.selected_character)
	var authored := false
	for descriptor in layout.sections:
		authored = authored or not descriptor.resource.pickups.is_empty()
	if authored:
		rewards.setup([], 0, [])
		for descriptor in layout.sections:
			for pickup: PickupPlacement in descriptor.resource.pickups:
				var cell := pickup.cell + Vector2i(0, descriptor.first_row)
				rewards.add_pickup({"key": cell, "position": config.cell_position(cell)}, "coin" if pickup.power == null else pickup.power.effect, pickup.power, pickup.coin_value)
	else:
		rewards.setup(reward_sites(), config.coin_count, config.power_ups)
	for key: Vector2i in rewards.pickups:
		activation.register(rewards.pickups[key], key.y, key.y)
	activation.register(destinations, config.goal_row, config.goal_row)
	# Destinations may have been inactive at the end of the previous run.
	destinations.visible = true
	destinations.process_mode = Node.PROCESS_MODE_INHERIT
	activation.setup(camera, player, camera.is_scrolling())
	terrain.refresh()
	decorations.refresh(true)
	apply_theme(presentation.requested_theme)

func apply_theme(settings: LevelThemeConfig) -> void:
	presentation.configure(settings, camera)
	var theme := presentation.theme
	decorations.set_theme(theme)
	$BoardArt.theme = theme
	$BoardArt.queue_redraw()
	terrain.theme = theme
	terrain.queue_redraw()
	player.presentation_highlight = theme.player_highlight
	player.queue_redraw()
	for goal: DestinationZone in goals.values():
		goal.theme = theme
		goal.queue_redraw()
	for lane in lanes:
		lane.apply_theme(theme)
	for railway in railways:
		for track in railway.tracks:
			track.theme = theme
			track.train.theme = theme
			track.train.queue_redraw()
			track.queue_redraw()
	for lane in water_lanes:
		lane.theme = theme
		lane.queue_redraw()

func _on_player_spawned() -> void:
	if camera.config == null:
		return
	camera.snap_to_player()
	presentation.follow_camera()
	activation.refresh(true)
	terrain.refresh()
	decorations.refresh(true)

func can_enter_cell(cell: Vector2i) -> bool:
	if not config.is_in_bounds(cell) or config.obstacles.has(cell):
		return false
	if cell.y == config.goal_row:
		return goals.has(cell.x) and not goals[cell.x].occupied
	return true

func claim_destination(column: int) -> bool:
	if not goals.has(column) or goals[column].occupied:
		return false
	goals[column].set_occupied(true)
	return true

func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func set_traffic_scale(value: float) -> void:
	if is_equal_approx(_traffic_scale, value):
		return
	_traffic_scale = value
	for lane in lanes:
		lane.set_speed_scale(value)
	for railway in railways:
		railway.set_speed_scale(value)

func reward_sites() -> Array[Dictionary]:
	# Long routes distribute candidates across safe rows, independent of the camera.
	var sites: Array[Dictionary] = []
	if camera.is_scrolling():
		for column in range(2, config.columns - 2, 2):
			for row in layout.safe_rows:
				var cell := Vector2i(column, row)
				if cell != config.spawn_cell and can_enter_cell(cell):
					sites.append({"key": cell, "position": config.cell_position(cell)})
		return sites
	for row in layout.safe_rows:
		for column in range(2, config.columns - 2, 2):
			var cell := Vector2i(column, row)
			var at := config.cell_position(cell)
			if cell == config.spawn_cell or not can_enter_cell(cell):
				continue
			# Keep icons clear of the current fixed-board HUD and thumb controls.
			if Rect2(180, 210, 900, 384).has_point(at):
				sites.append({"key": cell, "position": at})
	return sites
