class_name LevelCamera
extends Camera2D
## Landscape framing in logical canvas coordinates. UI remains on its CanvasLayer.
## Grid Y grows forward; world Y grows downward. scroll_y is the viewport's top.
const PLAY_TOP := 108.0
const PLAY_BOTTOM := 616.0
const FORWARD_LINE := 400.0
const BACKWARD_LINE := 528.0
const RESPONSE := 12.0
var config: LevelConfig
var player: CrossingPlayer
var minimum_scroll: float = 0.0
var maximum_scroll: float = 0.0
var target_scroll: float = 0.0

func _ready() -> void:
	anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	position_smoothing_enabled = false
	process_physics_priority = -40

func setup(rules: LevelConfig, actor: CrossingPlayer) -> void:
	config = rules
	player = actor
	# Preserve the original Start and destination garden margins at either end.
	maximum_scroll = config.cell_position(config.spawn_cell).y + 40.0 - PLAY_BOTTOM
	minimum_scroll = minf(maximum_scroll, config.cell_position(Vector2i(0, config.goal_row)).y - 84.0 - PLAY_TOP)
	snap_to_player()

func snap_to_player() -> void:
	if config == null:
		return
	target_scroll = clampf(player.position.y - FORWARD_LINE, minimum_scroll, maximum_scroll)
	position = Vector2(0.0, target_scroll)
	force_update_scroll()

func _physics_process(delta: float) -> void:
	if config == null or not player.visible:
		return
	advance(delta)

func advance(delta: float) -> void:
	var screen_y := player.position.y - target_scroll
	if screen_y < FORWARD_LINE:
		target_scroll = player.position.y - FORWARD_LINE
	elif screen_y > BACKWARD_LINE:
		target_scroll = player.position.y - BACKWARD_LINE
	target_scroll = clampf(target_scroll, minimum_scroll, maximum_scroll)
	var next := lerpf(position.y, target_scroll, 1.0 - exp(-RESPONSE * delta))
	# Even rapid movement/relocation must not hide the player behind the HUD.
	next = clampf(next, player.position.y - (PLAY_BOTTOM - 32.0), player.position.y - (PLAY_TOP + 32.0))
	position = Vector2(0.0, clampf(next, minimum_scroll, maximum_scroll))
	force_update_scroll()

func visible_rows() -> Vector2i:
	var first := floori((config.grid_origin.y - (position.y + PLAY_BOTTOM)) / config.cell_size)
	var last := ceili((config.grid_origin.y - (position.y + PLAY_TOP)) / config.cell_size)
	return Vector2i(maxi(0, first), mini(config.goal_row, last))

func is_scrolling() -> bool:
	return minimum_scroll < maximum_scroll
