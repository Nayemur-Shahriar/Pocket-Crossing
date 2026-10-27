class_name GameHUD
extends CanvasLayer
## UI is deliberately independent of the game state implementation.

signal characters_pressed
signal character_selected(id: String)
signal level_selected(index: int)
signal retry_pressed
signal primary_pressed
signal secondary_pressed
signal menu_pressed
signal pause_pressed
signal sound_pressed
signal touch_direction(direction: Vector2i, immediate: bool)

const INK := CrossingStyle.INK
const CREAM := CrossingStyle.CREAM
const MUTED := CrossingStyle.MUTED
const YELLOW := CrossingStyle.ACCENT
@export var celebration_sound: AudioStream = preload("res://assets/audio/firework.wav")
var result_new_high_score: bool = false
var result_panel: LevelResultPanel
var result_stars: int = 0
var result_coins: int = 0
var level_config: LevelConfig
var has_next: bool = true
var level_label: Label
var split_controls: Control
var direction_buttons: Dictionary = {}
var _held_buttons: Array[Vector2i] = []
var _safe_rect := Rect2()
var root: Control
var score_label: Label
var time_label: Label
var lives_label: Label
var bays_label: Label
var destination_label: Label
var best_label: Label
var message_label: Label
var sound_button: Button
var pause_button: Button
var time_bar: ColorRect
var overlay: Control
var flash_rect: ColorRect
var _tip_left: float = 0.0
var _last_time: int = -1
var _default_tip := "Find a gap. The middle island is safe."

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel(root, Rect2(0, 0, 1280, 108), INK)
	_panel(root, Rect2(0, 616, 1280, 104), INK)
	for card in [Rect2(354, 12, 174, 80), Rect2(539, 12, 174, 80), Rect2(724, 12, 226, 80)]:
		_panel(root, card, Color("203d46"), 12)
	_label(root, "POCKET CROSSING", Rect2(32, 19, 300, 34), 27, CREAM)
	level_label = _label(root, "01  /  GREENWAY", Rect2(34, 58, 270, 26), 17, YELLOW)
	_label(root, "SCORE", Rect2(378, 18, 150, 22), 14, MUTED)
	score_label = _label(root, "0000", Rect2(376, 41, 180, 43), 33, CREAM)
	_label(root, "TIME LEFT", Rect2(563, 18, 145, 22), 14, MUTED)
	time_label = _label(root, "1:30", Rect2(561, 41, 165, 43), 33, YELLOW)
	_label(root, "LIVES", Rect2(744, 18, 160, 22), 14, MUTED)
	lives_label = _label(root, "♥  ♥  ♥", Rect2(742, 43, 194, 42), 30, Color("ef9686"))
	sound_button = _button(root, "SOUND ON", Rect2(974, 26, 122, 56), false)
	sound_button.pressed.connect(func() -> void: sound_pressed.emit())
	pause_button = _button(root, "II  PAUSE", Rect2(1110, 26, 138, 56), false)
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	var track := ColorRect.new()
	track.position = Vector2(0, 104)
	track.size = Vector2(1280, 4)
	track.color = Color("375151")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(track)
	time_bar = ColorRect.new()
	time_bar.position = Vector2(0, 104)
	time_bar.size = Vector2(1280, 4)
	time_bar.color = YELLOW
	time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(time_bar)
	destination_label = _label(root, "DESTINATIONS", Rect2(170, 130, 315, 25), 15, Color("3f624f"))
	bays_label = _label(root, "0 / 4 REACHED", Rect2(987, 130, 230, 25), 15, Color("3f624f"))
	message_label = _label(root, _default_tip, Rect2(164, 631, 834, 50), 19, CREAM)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	best_label = _label(root, "WASD / ARROWS  ·  SWIPE TO HOP  ·  TAP / HOLD", Rect2(164, 682, 660, 26), 14, MUTED)
	_build_split_controls()
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 0.35, 0.24, 0)
	root.add_child(flash_rect)
	set_sound(SaveData.sound_enabled)

func _process(delta: float) -> void:
	_update_control_safe_area()
	if _tip_left > 0.0:
		_tip_left -= delta
		if _tip_left <= 0.0:
			message_label.text = _default_tip
	flash_rect.color.a = maxf(0.0, flash_rect.color.a - delta * 0.7)

func _build_split_controls() -> void:
	split_controls = Control.new()
	split_controls.name = "SplitControls"
	split_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(split_controls)
	split_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vertical := VBoxContainer.new()
	vertical.name = "LeftThumb"
	vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_controls.add_child(vertical)
	vertical.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	vertical.offset_left = 24
	vertical.offset_right = 136
	vertical.offset_top = -176
	vertical.offset_bottom = -16
	vertical.add_theme_constant_override("separation", 8)
	_add_direction_button(vertical, "↑", Vector2i(0, 1), Vector2(112, 76))
	_add_direction_button(vertical, "↓", Vector2i(0, -1), Vector2(112, 76))
	var horizontal := HBoxContainer.new()
	horizontal.name = "RightThumb"
	horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_controls.add_child(horizontal)
	horizontal.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	horizontal.offset_left = -264
	horizontal.offset_right = -24
	horizontal.offset_top = -100
	horizontal.offset_bottom = -16
	horizontal.add_theme_constant_override("separation", 16)
	_add_direction_button(horizontal, "←", Vector2i(-1, 0), Vector2(112, 84))
	_add_direction_button(horizontal, "→", Vector2i(1, 0), Vector2(112, 84))
	_update_control_safe_area()

func _add_direction_button(parent: Container, caption: String, direction: Vector2i, hit_size: Vector2) -> void:
	var hit := TouchDirectionButton.new()
	hit.name = "Direction_%s_%s" % [direction.x, direction.y]
	hit.custom_minimum_size = hit_size
	parent.add_child(hit)
	var face := _button(hit, caption, Rect2(), false)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.focus_mode = Control.FOCUS_NONE
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Transparent padding enlarges the target without enlarging the painted face.
	face.offset_left = 4
	face.offset_right = -4
	face.offset_top = 4
	face.offset_bottom = -4
	face.add_theme_font_size_override("font_size", 34)
	hit.face = face
	hit.activated.connect(func() -> void:
		_held_buttons.erase(direction)
		_held_buttons.append(direction)
		touch_direction.emit(direction, true)
	)
	hit.released.connect(func() -> void:
		var was_active: bool = not _held_buttons.is_empty() and _held_buttons.back() == direction
		_held_buttons.erase(direction)
		if was_active:
			var remaining: Vector2i = Vector2i.ZERO if _held_buttons.is_empty() else _held_buttons.back()
			touch_direction.emit(remaining, false)
	)
	direction_buttons[direction] = hit

func reset_touch_controls() -> void:
	_held_buttons.clear()
	for button: TouchDirectionButton in direction_buttons.values():
		button.cancel()

func set_control_mode(mode: int) -> void:
	reset_touch_controls()
	split_controls.visible = mode != InputRouter.ControlMode.SWIPE

func _update_control_safe_area() -> void:
	if not is_instance_valid(split_controls):
		return
	var safe := get_viewport().get_visible_rect()
	if OS.has_feature("android") or OS.has_feature("ios"):
		var display_safe := Rect2(DisplayServer.get_display_safe_area())
		if display_safe.has_area():
			safe = safe.intersection(get_viewport().get_screen_transform().affine_inverse() * display_safe)
	apply_control_safe_area(safe)

func apply_control_safe_area(safe: Rect2) -> void:
	# Public helper also permits deterministic notch/inset checks in tests.
	if safe == _safe_rect:
		return
	_safe_rect = safe
	var factor := minf(safe.size.x / 1280.0, safe.size.y / 720.0)
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.size = Vector2(1280,720)
	root.scale = Vector2.ONE * factor
	root.position = safe.position + (safe.size - root.size * factor) * 0.5
	split_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func update_status(score: int, seconds: float, lives: int, reached: int, total: int, limit: float) -> void:
	score_label.text = "%04d" % score
	var whole := maxi(0, ceili(seconds))
	if whole != _last_time:
		_last_time = whole
		time_label.text = "%d:%02d" % [whole / 60, whole % 60]
	time_label.modulate = Color("ff977e") if seconds <= 15.0 else Color.WHITE
	lives_label.text = "  ".join(Array(PackedStringArray(["♥", "♥", "♥"])).slice(0, lives)) if lives > 0 else "—"
	bays_label.text = "%d / %d REACHED" % [reached, total]
	time_bar.size.x = 1280.0 * clampf(seconds / limit, 0.0, 1.0)
	time_bar.color = Color("ef9686") if seconds <= 15.0 else YELLOW

func show_tip(message: String, duration: float = 2.4) -> void:
	message_label.text = message
	_tip_left = duration

func hit_flash(at: Vector2 = Vector2(640, 360)) -> void:
	flash_rect.color.a = 0.14
	var marker := Node2D.new()
	marker.set_script(preload("res://scripts/ui/collision_feedback.gd"))
	marker.position = at
	root.add_child(marker)
	# Keep the impact beneath an existing modal.
	if is_instance_valid(overlay):
		root.move_child(marker, overlay.get_index())


func set_sound(enabled: bool) -> void:
	sound_button.text = "SOUND ON" if enabled else "SOUND OFF"

func show_screen(kind: String, score: int = 0, best: int = 0, detail: String = "") -> void:
	hide_screen()
	if kind == "complete" or kind == "game_over":
		result_panel = LevelResultPanel.new()
		overlay = result_panel
		root.add_child(overlay)
		result_panel.build(self, kind == "complete", score, best, detail)
		pause_button.disabled = true
		return
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)
	overlay.modulate.a = 1.0
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.11, 0.14, 0.77)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	_panel(overlay, Rect2(318, 89, 644, 542), CrossingStyle.CREAM, 24)
	var tag := "LEVEL %02d / %s" % [level_config.level_number, level_config.display_name.to_upper()] if level_config != null else "POCKET CROSSING"
	var title := "Small steps.\nBig city."
	var body := "Guide Pip across four busy lanes.\nReach any finish before the clock runs out."
	var primary := "LET'S CROSS  →"
	var secondary := ""
	var footer := "3 lives   ·   90 seconds   ·   choose a finish"
	if kind == "pause":
		tag = "CROSSING PAUSED"
		title = "Take a breath."
		body = "Your timer and the traffic are paused.\nReady when you are."
		primary = "KEEP GOING  →"
		secondary = "Restart level"
		footer = "Esc / P to resume"
	_label(overlay, tag, Rect2(360, 124, 564, 28), 16, Color("597365"))
	_label(overlay, title, Rect2(356, 169, 575, 127), 49, INK)
	var body_label := _label(overlay, body, Rect2(360, 310, 565, 80), 19, Color("526662"))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(overlay, footer, Rect2(360, 394, 564, 28), 17, INK)
	var start := _button(overlay, primary, Rect2(359, 450, 562, 63), true)
	start.focus_mode = Control.FOCUS_ALL
	start.pressed.connect(func() -> void: primary_pressed.emit())
	_focus_if_current.call_deferred(start)
	if not secondary.is_empty():
		var other := _button(overlay, secondary, Rect2(359, 528, 562, 55), false)
		other.add_theme_color_override("font_color", CREAM)
		other.pressed.connect(func() -> void: secondary_pressed.emit())
	else:
		_label(overlay, "ARROW KEYS / WASD     •     SWIPE / TOUCH", Rect2(362, 540, 555, 27), 16, Color("64756b"))
	if kind == "pause":
		var menu := _button(overlay, "Level Select", Rect2(786, 115, 136, 42), false)
		menu.pressed.connect(func() -> void: menu_pressed.emit())
	pause_button.disabled = kind != "pause"

func hide_screen() -> void:
	if is_instance_valid(result_panel) and is_instance_valid(result_panel.celebration):
		result_panel.celebration.stop()
	result_panel = null
	if is_instance_valid(overlay):
		root.remove_child(overlay)
		overlay.queue_free()
		overlay = null
	pause_button.disabled = false

func _label(parent: Node, text: String, rectangle: Rect2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.position = rectangle.position
	label.size = rectangle.size
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _panel(parent: Node, rectangle: Rect2, color: Color, radius: int = 0) -> Panel:
	var panel := Panel.new()
	panel.position = rectangle.position
	panel.size = rectangle.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if radius > 0:
		style.border_color = color.lightened(0.08)
		style.set_border_width_all(1)
		style.shadow_color = Color(0.02, 0.08, 0.11, 0.18)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _button(parent: Node, text: String, rectangle: Rect2, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rectangle.position
	button.size = rectangle.size
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if rectangle.size.y >= 64 and rectangle.size.y <= 86: button.size.y = CrossingStyle.BUTTON_HEIGHT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", CrossingStyle.BUTTON_FONT if rectangle.size.x >= 170 or rectangle.size.x == 0 else 16)
	button.add_theme_color_override("font_color", INK if primary else CREAM)
	button.add_theme_color_override("font_hover_color", INK if primary else CREAM)
	button.add_theme_color_override("font_pressed_color", INK if primary else CREAM)
	button.add_theme_color_override("font_focus_color", INK if primary else CREAM)
	button.add_theme_color_override("font_disabled_color", MUTED)
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = YELLOW if primary else CrossingStyle.BUTTON
		if state_name == "hover":
			style.bg_color = style.bg_color.lightened(0.09)
		elif state_name == "pressed":
			style.bg_color = style.bg_color.darkened(0.12)
		elif state_name == "disabled":
			style.bg_color = Color("293c43")
		elif state_name == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = CREAM if primary else YELLOW
			style.set_border_width_all(3)
		if state_name != "focus":
			style.border_color = Color("dcae60") if primary else CrossingStyle.EDGE
			style.set_border_width_all(1)
			style.border_width_bottom = 3 if state_name != "pressed" else 1
			style.shadow_color = Color(0.02, 0.08, 0.12, 0.24)
			style.shadow_size = 3 if state_name != "pressed" else 0
			style.shadow_offset = Vector2(0, 2)
		style.set_corner_radius_all(CrossingStyle.BUTTON_RADIUS)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		button.add_theme_stylebox_override(state_name, style)
	parent.add_child(button)
	return button

func set_level(config: LevelConfig, next_available: bool) -> void:
	level_config = config
	has_next = next_available
	level_label.text = "%02d / %s" % [config.level_number, config.display_name.to_upper()]
	level_label.add_theme_font_size_override("font_size", 15)
	# The old destination caption sat over the fixed garden. On long routes,
	# keep its counter in the footer so it does not label an intermediate hazard.
	var long_route := config.goal_row > 6
	destination_label.visible = not long_route
	bays_label.position = Vector2(850, 684) if long_route else Vector2(987, 130)
	bays_label.size = Vector2(162, 24) if long_route else Vector2(230, 25)
	bays_label.add_theme_color_override("font_color", MUTED if long_route else Color("3f624f"))
	bays_label.add_theme_font_size_override("font_size", 14 if long_route else 15)
	best_label.size.x = 660 if long_route else 834
	best_label.clip_text = long_route
	_default_tip = "Find a gap. Reach any marked destination."
	if config.theme == "Railway":
		_default_tip = "Amber signals warn of a train. Wait off the tracks."

func show_level_select(catalog: LevelCatalog, preferred_level: int = 0) -> void:
	hide_screen()
	overlay = Control.new()
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel(overlay, Rect2(0, 0, 1280, 720), INK)
	_label(overlay, "CHOOSE YOUR CROSSING", Rect2(100, 42, 720, 50), 34, CREAM)
	var wardrobe := _button(overlay, "CHARACTERS / %d coins" % SaveData.coins, Rect2(882, 44, 298, 48), true)
	wardrobe.focus_mode = Control.FOCUS_ALL
	wardrobe.pressed.connect(func() -> void: characters_pressed.emit())
	_label(overlay, "Complete a level to unlock the next route.", Rect2(100, 96, 1080, 36), 20, MUTED)
	var scroll := LevelListScroll.new()
	scroll.name = "LevelScroll"
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 100
	scroll.offset_right = -100
	scroll.offset_top = 151
	scroll.offset_bottom = -45
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var focused := false
	var focus_level := preferred_level if SaveData.is_unlocked(preferred_level, catalog) else 0
	for i in range(catalog.levels.size()):
		var config := catalog.levels[i]
		var reasons := config.playability_errors()
		var unlocked := SaveData.is_unlocked(i, catalog) and reasons.is_empty()
		var status := "LOCKED" if not unlocked else "PLAY"
		if not reasons.is_empty():
			status = "LAYOUT ONLY"
		if reasons.is_empty() and SaveData.completed_levels.get(config.level_id, false) == true:
			status = "COMPLETED"
		var caption := "%02d   %s     %s     %s" % [config.level_number, config.display_name, star_text(int(SaveData.level_stars.get(config.level_id, 0))), status]
		var button := _button(list, caption, Rect2(), unlocked)
		button.name = "Level_%02d" % (i + 1)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_disabled_color", Color("a8b9b5"))
		button.custom_minimum_size = Vector2(0, 86)
		button.disabled = not unlocked
		button.tooltip_text = "; ".join(reasons)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(func() -> void: level_selected.emit(i))
		if unlocked and not focused and i == focus_level:
			_focus_if_current.call_deferred(button)
			focused = true
	pause_button.disabled = true

func update_progression(collected: int, effects: String) -> void:
	best_label.text = "COINS +%d  /  WALLET %d" % [collected, SaveData.coins]
	if not effects.is_empty():
		best_label.text += "   ·   " + effects
	else:
		best_label.text += "   ·   S: Shield  /  T: Slow traffic  /  2: Double rewards"

func star_text(value: int) -> String:
	return "★".repeat(clampi(value, 0, 3)) + "☆".repeat(3 - clampi(value, 0, 3))

func show_characters(notice: String = "Cosmetic skins only. Same speed, lives and collision shape.") -> void:
	hide_screen()
	overlay = Control.new()
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel(overlay, Rect2(0, 0, 1280, 720), INK)
	_label(overlay, "CHOOSE YOUR COURIER", Rect2(100, 42, 760, 48), 34, CREAM)
	_label(overlay, "WALLET  %d COINS" % SaveData.coins, Rect2(902, 49, 278, 38), 23, YELLOW)
	_label(overlay, notice, Rect2(100, 100, 1080, 36), 19, MUTED)
	var scroll := LevelListScroll.new()
	overlay.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 100
	scroll.offset_right = -100
	scroll.offset_top = 154
	scroll.offset_bottom = -108
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for entry in CharacterCatalog.SKINS:
		var skin := CharacterCatalog.find_skin(entry.id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 22)
		list.add_child(row)
		var icon := TextureRect.new()
		icon.texture = load(skin.texture)
		icon.custom_minimum_size = Vector2(76, 92)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var owned: bool = SaveData.unlocked_characters.get(skin.id, false)
		var selected: bool = SaveData.selected_character == skin.id
		var action := "SELECTED" if selected else ("SELECT" if owned else "UNLOCK / %d COINS" % skin.cost)
		var button := _button(row, "%s     ·     %s" % [skin.name, action], Rect2(), selected)
		button.name = "Skin_" + skin.id
		button.add_theme_font_size_override("font_size", 20)
		button.custom_minimum_size = Vector2(0, 92)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = selected or (not owned and SaveData.coins < int(skin.cost))
		if selected:
			button.add_theme_stylebox_override("disabled", button.get_theme_stylebox("normal"))
			button.add_theme_color_override("font_disabled_color", INK)
		button.pressed.connect(func() -> void: character_selected.emit(skin.id))
	var back := _button(overlay, "RETURN TO LEVEL SELECT", Rect2(100, 624, 1080, 72), false)
	back.focus_mode = Control.FOCUS_ALL
	back.pressed.connect(func() -> void: menu_pressed.emit())
	_focus_if_current.call_deferred(back)
	pause_button.disabled = true

func _focus_if_current(button: Variant) -> void:
	# A fast retry/menu change can replace the modal before deferred focus runs.
	if is_instance_valid(button) and button.is_inside_tree() and button.is_visible_in_tree() and not button.disabled:
		button.grab_focus()

var scene_fade: SceneFade
func navigate(callback: Callable) -> void:
	if not is_instance_valid(scene_fade):
		scene_fade = SceneFade.new()
		add_child(scene_fade)
	scene_fade.begin(callback)
