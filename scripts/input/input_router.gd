class_name InputRouter
extends Node
## Keyboard, swipe and on-screen arrows all emit the same grid command.
## Grid Y increases upward. A swipe produces exactly one hop.

signal direction_requested(direction: Vector2i)
signal pause_requested
signal restart_requested
signal sound_requested
signal gestures_reset
signal control_mode_changed(mode: int)

enum ControlMode { BOTH, SPLIT_BUTTONS, SWIPE }
var control_mode: ControlMode = ControlMode.BOTH
# Only the board/start strip starts a swipe; HUD and footer are excluded.
var swipe_area := Rect2(0, 108, 1280, 508)

const SWIPE_THRESHOLD := 24.0
const REPEAT_DELAY := 0.22
const REPEAT_INTERVAL := 0.16
const DIRECTIONS := {
	"move_up": Vector2i(0, 1), "move_down": Vector2i(0, -1),
	"move_left": Vector2i(-1, 0), "move_right": Vector2i(1, 0),
}
var enabled: bool = false
var _touch_id: int = -1
var _swipe_start := Vector2.ZERO
var _swipe_consumed: bool = false
var _mouse_swiping: bool = false
var _held_touch := Vector2i.ZERO
var _last_action: String = ""
var _repeat_left: float = 0.0

func _ready() -> void:
	# These actions also exist in project.godot and can be remapped in the editor.
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_enabled(value: bool) -> void:
	enabled = value
	reset_gestures()

func set_control_mode(mode: ControlMode) -> void:
	control_mode = mode
	reset_gestures()
	control_mode_changed.emit(mode)

func reset_gestures() -> void:
	_touch_id = -1
	_mouse_swiping = false
	_swipe_consumed = false
	_held_touch = Vector2i.ZERO
	_last_action = ""
	_repeat_left = REPEAT_DELAY
	gestures_reset.emit()

func set_touch_direction(direction: Vector2i, immediate: bool = true) -> void:
	_held_touch = direction if enabled and control_mode != ControlMode.SWIPE else Vector2i.ZERO
	_repeat_left = REPEAT_DELAY
	if immediate and _held_touch != Vector2i.ZERO:
		direction_requested.emit(direction)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var direction := _held_touch
	if direction == Vector2i.ZERO and not _last_action.is_empty() and Input.is_action_pressed(_last_action):
		direction = DIRECTIONS[_last_action]
	if direction == Vector2i.ZERO:
		return
	_repeat_left -= delta
	if _repeat_left <= 0.0:
		_repeat_left = REPEAT_INTERVAL
		direction_requested.emit(direction)

func _input(event: InputEvent) -> void:
	# A gesture may end over a GUI button. Release its ownership before the GUI
	# can consume the release, otherwise later swipes could remain locked out.
	if event is InputEventScreenTouch and not event.pressed and event.index == _touch_id:
		if enabled and not event.canceled:
			_try_swipe(event.position)
		_touch_id = -1
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_mouse_swiping = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("restart_game"):
		restart_requested.emit()
		return
	if event.is_action_pressed("toggle_sound"):
		sound_requested.emit()
		return
	if not enabled:
		return
	for action: String in DIRECTIONS:
		if event.is_action_pressed(action) and not event.is_echo():
			_last_action = action
			_repeat_left = REPEAT_DELAY
			direction_requested.emit(DIRECTIONS[action])
			get_viewport().set_input_as_handled()
			return
	if control_mode == ControlMode.SPLIT_BUTTONS:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and _touch_id == -1 and swipe_area.has_point(event.position):
			_touch_id = event.index
			_swipe_start = event.position
			_swipe_consumed = false
		elif not event.pressed and event.index == _touch_id:
			_try_swipe(event.position)
			_touch_id = -1
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_try_swipe(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Physical mouse only. Android's emulated mouse must not duplicate a swipe.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		_mouse_swiping = event.pressed and swipe_area.has_point(event.position)
		if _mouse_swiping:
			_swipe_start = event.position
			_swipe_consumed = false
	elif event is InputEventMouseMotion and _mouse_swiping:
		_try_swipe(event.position)

func _try_swipe(position: Vector2) -> void:
	if _swipe_consumed:
		return
	var distance := position - _swipe_start
	if distance.length() < SWIPE_THRESHOLD:
		return
	_swipe_consumed = true
	var direction := Vector2i.ZERO
	if absf(distance.x) > absf(distance.y):
		direction.x = 1 if distance.x > 0 else -1
	else:
		direction.y = -1 if distance.y > 0 else 1
	direction_requested.emit(direction)
