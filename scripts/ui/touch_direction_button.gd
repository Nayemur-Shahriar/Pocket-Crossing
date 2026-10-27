class_name TouchDirectionButton
extends Control
## Own each finger independently; emulated mouse events must not duplicate taps.
signal activated
signal released

var face: Button
var _fingers: Dictionary = {}
var _mouse_held := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree():
			cancel()
	)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			var was_held := is_held()
			_fingers[event.index] = true
			if not was_held:
				activated.emit()
			_update_face()
		accept_event()
	elif event is InputEventScreenDrag:
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device != InputEvent.DEVICE_ID_EMULATION and event.pressed:
			_mouse_held = true
			activated.emit()
			_update_face()
		accept_event()

func _input(event: InputEvent) -> void:
	# Observe releases anywhere, including outside the button or over a modal.
	# Do not consume them: other input owners must see their own releases.
	if event is InputEventScreenTouch and (not event.pressed or event.canceled):
		if _fingers.has(event.index):
			_fingers.erase(event.index)
			_after_release()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION and _mouse_held:
			_mouse_held = false
			_after_release()

func is_held() -> bool:
	return _mouse_held or not _fingers.is_empty()

func cancel() -> void:
	_fingers.clear()
	_mouse_held = false
	_update_face()

func _after_release() -> void:
	_update_face()
	if not is_held():
		released.emit()

func _update_face() -> void:
	if is_instance_valid(face):
		face.set_pressed_no_signal(is_held())
