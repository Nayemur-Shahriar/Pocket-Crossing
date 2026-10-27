class_name LevelResultPanel
extends Control
## Reusable modal presentation. Scoring, saving and navigation stay in CrossingGame.
var title_label: Label
var stars_label: Label
var score_value: Label
var best_value: Label
var coins_value: Label
var record_label: Label
var replay_button: Button
var select_button: Button
var next_button: Button
var celebration: ResultCelebration

func build(hud: GameHUD, completed: bool, score: int, best: int, detail: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.04, 0.09, 0.12, 0.80)
	add_child(shade)
	if completed and hud.result_new_high_score:
		celebration = ResultCelebration.new()
		celebration.sound = hud.celebration_sound
		add_child(celebration)
	hud._panel(self, Rect2(278, 116, 724, 488), CrossingStyle.CREAM, 24)
	var tag := "%02d  /  %s" % [hud.level_config.level_number, hud.level_config.display_name.to_upper()]
	center_label(hud, tag, Rect2(304, 141, 672, 26), 17, Color("597365"))
	title_label = center_label(hud, "LEVEL COMPLETE" if completed else "TRY AGAIN", Rect2(304, 180, 672, 52), 38, CrossingStyle.INK)
	if completed:
		stars_label = center_label(hud, hud.star_text(hud.result_stars), Rect2(304, 238, 672, 64), 48, Color("947018"))
		var status := "NEW HIGH SCORE!" if hud.result_new_high_score else "Every crossing counts."
		if not hud.has_next:
			status += "  ·  CAMPAIGN COMPLETE" if hud.result_new_high_score else "  Campaign complete!"
		record_label = center_label(hud, status, Rect2(304, 311, 672, 28), 20, Color("3f705c"))
	else:
		center_label(hud, "Take a breath. Your next crossing starts here.", Rect2(304, 258, 672, 48), 21, Color("526662"))
	var values := [str(score), str(best), "+%d" % hud.result_coins]
	var labels := ["SCORE", "BEST SCORE", "COINS THIS RUN"]
	var value_nodes: Array[Label] = []
	for i in range(3):
		var x := 308.0 + i * 224.0
		hud._panel(self, Rect2(x, 354, 212, 85), Color("dce5cf"), 12)
		center_label(hud, labels[i], Rect2(x, 364, 212, 22), 15, Color("526662"))
		value_nodes.append(center_label(hud, values[i], Rect2(x, 386, 212, 44), 30, CrossingStyle.INK))
	score_value = value_nodes[0]
	best_value = value_nodes[1]
	coins_value = value_nodes[2]
	var note := "Coins are saved as you collect them."
	if detail.contains("Save failed"):
		note = "Save failed: check free storage."
	center_label(hud, note, Rect2(304, 451, 672, 26), 17, Color("526662"))
	var count := 3 if completed and hud.has_next else 2
	var width := 212.0 if count == 3 else 324.0
	replay_button = hud._button(self, "PLAY AGAIN", Rect2(308, 493, width, 84), count == 2)
	select_button = hud._button(self, "LEVEL SELECT", Rect2(308 + width + 12, 493, width, 84), false)
	replay_button.pressed.connect(func() -> void: hud.retry_pressed.emit())
	select_button.pressed.connect(func() -> void: hud.menu_pressed.emit())
	var buttons: Array[Button] = [replay_button, select_button]
	if count == 3:
		next_button = hud._button(self, "NEXT LEVEL", Rect2(756, 493, 212, 84), true)
		next_button.pressed.connect(func() -> void: hud.primary_pressed.emit())
		buttons.append(next_button)
	for i in range(buttons.size()):
		var button := buttons[i]
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 18)
		button.focus_neighbor_left = button.get_path_to(buttons[(i + buttons.size() - 1) % buttons.size()])
		button.focus_neighbor_right = button.get_path_to(buttons[(i + 1) % buttons.size()])
		button.focus_neighbor_top = button.get_path_to(button)
		button.focus_neighbor_bottom = button.get_path_to(button)
	hud._focus_if_current.call_deferred(next_button if next_button != null else replay_button)

func center_label(hud: GameHUD, text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := hud._label(self, text, rect, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and is_instance_valid(celebration):
		celebration.stop()
