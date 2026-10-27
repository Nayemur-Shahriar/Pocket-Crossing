class_name SectionActivation
extends Node
## Retains existing nodes and their timers/pools. No catch-up or spawn burst.
## Large ROAD/WATER bands activate by lane; railway batches stay together.
const AHEAD_ROWS := 4
const BEHIND_ROWS := 3
const RETAIN_ROWS := 2
var camera: LevelCamera
var player: CrossingPlayer
var entries: Array[Dictionary] = []
var window := Vector2i(-1, -1)
var streaming := false
var configured := false

func _ready() -> void:
	process_physics_priority = -30 # Before water motion/support and all hazards.

func clear() -> void:
	configured = false
	entries.clear()
	window = Vector2i(-1, -1)

func register(node: Node2D, first_row: int, last_row: int) -> void:
	entries.append({"node": node, "first": first_row, "last": last_row, "active": true, "initialized": false})

func setup(view: LevelCamera, actor: CrossingPlayer, long_level: bool) -> void:
	camera = view
	player = actor
	streaming = long_level
	configured = true
	refresh(true)

func _physics_process(_delta: float) -> void:
	refresh()

func refresh(force: bool = false) -> void:
	if not configured or camera == null or camera.config == null:
		return
	var rows := camera.visible_rows()
	var desired := Vector2i(mini(rows.x, player.cell.y) - BEHIND_ROWS, maxi(rows.y, player.cell.y) + AHEAD_ROWS)
	if not force and desired == window:
		return
	window = desired
	for entry in entries:
		if not is_instance_valid(entry.node):
			continue
		var node: Node2D = entry.node
		if node.is_queued_for_deletion():
			continue
		var margin := RETAIN_ROWS if entry.active and entry.initialized else 0
		var active: bool = not streaming or (entry.last >= window.x - margin and entry.first <= window.y + margin)
		if not entry.initialized or active != entry.active:
			if active and entry.initialized and node is RailwaySection:
				(node as RailwaySection).prepare_reactivation()
			entry.initialized = true
			entry.active = active
			node.visible = active
			# CollisionObject2D's default DISABLE_MODE_REMOVE also removes inactive
			# vehicle/train collision objects from physics, not just their callbacks.
			node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func active_count() -> int:
	var count := 0
	for entry in entries:
		if is_instance_valid(entry.node) and entry.active:
			count += 1
	return count
