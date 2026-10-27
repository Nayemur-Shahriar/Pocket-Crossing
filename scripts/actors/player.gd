class_name CrossingPlayer
extends CharacterBody2D

signal step_completed(cell: Vector2i)
signal step_started
signal support_reset
signal spawned
signal step_blocked

@export var hop_duration: float = 0.14
var contact_cause: String="car"
var config: LevelConfig
var can_enter: Callable
# Optional world adapters; empty in the unchanged road/rail campaign.
var hop_target: Callable
var landing_check: Callable
var cell := Vector2i.ZERO
var moving: bool = false
var enabled: bool = false
var shield_visible: bool = false
var presentation_highlight: bool = false
var invulnerable_left: float = 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _elapsed: float = 0.0
var _landing_left: float = 0.0
var _queued := Vector2i.ZERO
@onready var art: Sprite2D = $Art

func setup(level_config: LevelConfig, entry_rule: Callable) -> void:
	config = level_config
	hop_duration = config.hop_seconds
	can_enter = entry_rule
	reset_to_spawn()

func reset_to_spawn(protection: float = -1.0) -> void:
	support_reset.emit()
	contact_cause="car"
	cell = config.spawn_cell
	position = config.cell_position(cell)
	moving = false
	enabled = true
	visible = true
	_queued = Vector2i.ZERO
	invulnerable_left = config.spawn_protection if protection < 0.0 else protection
	_landing_left = 0.0
	art.scale = Vector2.ONE
	art.position = Vector2(0, -5)
	art.rotation = 0.0
	art.modulate.a = 1.0
	queue_redraw()
	spawned.emit()

func stop_and_hide() -> void:
	support_reset.emit()
	enabled = false
	moving = false
	_queued = Vector2i.ZERO
	visible = false

func clear_buffer() -> void:
	_queued = Vector2i.ZERO

func request_step(direction: Vector2i) -> void:
	if not enabled or absi(direction.x) + absi(direction.y) != 1:
		return
	if moving:
		_queued = direction
		return
	var next_cell := cell + direction
	if not can_enter.call(next_cell):
		step_blocked.emit()
		return
	cell = next_cell
	_from = position
	_to = hop_target.call(cell, direction) if hop_target.is_valid() else config.cell_position(cell)
	_elapsed = 0.0
	_landing_left = 0.0
	art.scale = Vector2.ONE
	moving = true
	art.rotation = -0.09 if direction.x < 0 else (0.09 if direction.x > 0 else 0.0)
	step_started.emit()

func _physics_process(delta: float) -> void:
	if _landing_left > 0.0:
		_landing_left = maxf(0.0, _landing_left - delta)
		var amount := sin((_landing_left / 0.12) * PI) * 0.08
		art.scale = Vector2(1.0 + amount, 1.0 - amount)
		queue_redraw()
	if invulnerable_left > 0.0:
		invulnerable_left = maxf(0.0, invulnerable_left - delta)
		art.modulate.a = 0.55 if fmod(invulnerable_left, 0.18) < 0.09 else 1.0
		queue_redraw()
	else:
		art.modulate.a = 1.0
	if not moving:
		return
	_elapsed += delta
	var progress := minf(_elapsed / hop_duration, 1.0)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	position = _from.lerp(_to, eased)
	art.position.y = -5.0 - sin(progress * PI) * config.hop_height
	queue_redraw()
	if progress >= 1.0:
		moving = false
		position = _to
		art.position.y = -5.0
		_landing_left = 0.12
		art.rotation = 0.0
		if landing_check.is_valid() and not landing_check.call():
			_queued = Vector2i.ZERO
			return
		step_completed.emit(cell)
		var buffered := _queued
		_queued = Vector2i.ZERO
		if enabled and buffered != Vector2i.ZERO:
			request_step(buffered)

func _draw() -> void:
	if presentation_highlight:
		draw_circle(Vector2(0, 2), 25, Color(0.85, 0.92, 0.73, 0.16))
		draw_arc(Vector2(0, 2), 25, 0, TAU, 32, Color(0.91, 0.96, 0.8, 0.65), 1.5, true)
	draw_set_transform(Vector2(0, 11), 0.0, Vector2(1.0, 0.42))
	var height := clampf((-art.position.y - 5.0) / maxf(config.hop_height, 1.0), 0, 1) if config != null else 0.0
	draw_circle(Vector2.ZERO, 20.0 - height * 3.0, Color(0.04, 0.12, 0.15, 0.26 - height * 0.08))
	draw_circle(Vector2.ZERO, 14.0 - height * 2.0, Color(0.04, 0.12, 0.15, 0.08))
	draw_set_transform(Vector2.ZERO)
	if _landing_left > 0.0:
		var fade := _landing_left / 0.12
		draw_arc(Vector2(0, 12), 15.0 + (1.0 - fade) * 12.0, 0, TAU, 24, Color(0.96, 0.92, 0.73, fade * 0.45), 2.0, true)
	if shield_visible:
		draw_arc(Vector2.ZERO, 31.0, 0.0, TAU, 40, Color("91d6ec"), 3.0, true)
	if invulnerable_left > 0.0:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 40, Color("e2f6a6"), 2.0, true)

func apply_skin(id: String) -> void:
	var skin := CharacterCatalog.find_skin(id)
	if skin.is_empty():
		skin = CharacterCatalog.find_skin("pip")
	art.texture = load(skin.texture)

func set_shield_visual(value: bool) -> void:
	if shield_visible != value:
		shield_visible = value
		queue_redraw()
