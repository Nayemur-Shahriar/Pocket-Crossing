class_name WaterSupport
extends Node
## Motion/support adapter. Runs after platforms and before the existing player hop.
signal hazard(player: CrossingPlayer)
var player: CrossingPlayer
var lanes: Dictionary = {}
var support: FloatingPlatform
var level: LevelConfig

func setup(actor: CrossingPlayer, rules: LevelConfig, water_lanes: Array[WaterLane]) -> void:
	process_physics_priority = -10
	clear_support()
	player = actor
	level = rules
	lanes.clear()
	for lane in water_lanes:
		lanes[lane.row] = lane
	if not player.step_started.is_connected(clear_support):
		player.step_started.connect(clear_support)
		player.support_reset.connect(clear_support)
	player.hop_target = target_for_hop if not lanes.is_empty() else Callable()
	player.landing_check = check_landing if not lanes.is_empty() else Callable()
	set_physics_process(not lanes.is_empty())

func clear_support() -> void:
	if is_instance_valid(support): support.set_rider(get_instance_id(),false)
	support = null

func target_for_hop(cell: Vector2i, direction: Vector2i) -> Vector2:
	var target := level.cell_position(cell)
	if lanes.has(cell.y):
		# Preserve fractional X on water instead of snapping backwards to grid centers.
		target.x = player.position.x + direction.x * level.cell_size
	return target

func check_landing() -> bool:
	clear_support()
	if not lanes.has(player.cell.y):
		return true
	var lane := lanes[player.cell.y] as WaterLane
	support = lane.support_at(player.position.x)
	if support != null and not support.overlaps_playable_width(lane.width): support = null
	if support == null:
		# Synchronous: resolve before rewards, destination logic or a buffered next hop.
		hazard.emit(player)
		return false
	support.set_rider(get_instance_id(),true)
	_sync_column()
	return true

func _sync_column() -> void:
	player.cell.x = roundi((player.position.x-level.grid_origin.x)/level.cell_size)

func _physics_process(_delta: float) -> void:
	if not player.visible or not player.enabled or player.moving:
		clear_support()
		return
	if not lanes.has(player.cell.y):
		clear_support()
		return
	if is_instance_valid(support):
		player.position.x += support.motion_x
		_sync_column()
		# WaterLane width is the rendered logical world (1280), independent of window size.
		if not support.overlaps_playable_width((lanes[player.cell.y] as WaterLane).width):
			clear_support()
			hazard.emit(player)
			return
	# Covers standing still, a changed support, and externally relocated players.
	if not is_instance_valid(support) or not support.supports_x(player.position.x):
		check_landing()

func _exit_tree() -> void:
	clear_support()
