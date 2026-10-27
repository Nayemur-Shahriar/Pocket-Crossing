class_name LevelListScroll
extends ScrollContainer
## Own the gesture before GUI dispatch so a drag starting on a Button cannot click it.
## Wheel, scrollbar and keyboard/controller focus remain native Godot UI behavior.
@export_range(8.0, 40.0) var drag_threshold := 16.0
var pointer := -2 # -2 idle; -1 mouse; >=0 touch index.
var press_position := Vector2.ZERO
var press_scroll := 0
var dragging := false
var pressed_card: BaseButton

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_cancel()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if pointer == -2: _begin(event.position,event.index)
		elif pointer == event.index:
			_end(event.position,event.canceled)
	elif event is InputEventScreenDrag and pointer == event.index:
		_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Touch-to-mouse emulation must not select a second time.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			if pointer != -2 or _inside_list(event.position): get_viewport().set_input_as_handled()
			return
		if event.pressed:
			if pointer == -2: _begin(event.position,-1)
		elif pointer == -1:
			_end(event.position,event.canceled)
	elif event is InputEventMouseMotion and pointer == -1:
		_drag(event.position)

func _begin(at: Vector2, id: int) -> void:
	if not _inside_list(at): return
	pointer = id
	press_position = at
	press_scroll = scroll_vertical
	dragging = false
	pressed_card = _card_at(at)
	get_viewport().set_input_as_handled()

func _drag(at: Vector2) -> void:
	if absf(at.y-press_position.y) >= drag_threshold: dragging = true
	if dragging: scroll_vertical = press_scroll + roundi(press_position.y-at.y)
	get_viewport().set_input_as_handled()

func _end(at: Vector2, canceled: bool = false) -> void:
	var card := pressed_card
	var tap := not canceled and not dragging and at.distance_to(press_position) < drag_threshold
	_cancel()
	get_viewport().set_input_as_handled()
	if tap and is_instance_valid(card) and not card.disabled and _card_at(at) == card:
		card.grab_focus()
		card.pressed.emit()

func _card_at(at: Vector2) -> BaseButton:
	if not get_global_rect().has_point(at): return null
	for card in find_children("*","BaseButton",true,false):
		if card.is_visible_in_tree() and card.get_global_rect().has_point(at): return card
	return null

func _cancel() -> void:
	pointer = -2
	pressed_card = null
	dragging = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED:
		_cancel()

func _inside_list(at: Vector2) -> bool:
	return get_global_rect().has_point(at) and not (get_v_scroll_bar().visible and get_v_scroll_bar().get_global_rect().has_point(at))
