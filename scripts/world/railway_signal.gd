class_name RailwaySignal
extends Node2D
## Text plus alternating lamps: readable with sound disabled or color blindness.
var state: int = 0
var direction: int = 1
var phase := false
var width: float = 1280.0

func update_state(next: int, flash: bool) -> void:
	if next != state or flash != phase:
		state = next
		phase = flash
		queue_redraw()

func _draw() -> void:
	if state != 0:
		var tint := Color(1.0, 0.3, 0.18, 0.13 if phase else 0.06)
		draw_rect(Rect2(88, -30, width - 176, 60), tint)
		draw_line(Vector2(88, -29), Vector2(width - 88, -29), Color("f5a269"), 2)
	var word := "SAFE" if state == 0 else ("WARNING" if state == 1 else "PASSING")
	var color := Color("97cca4") if state == 0 else Color("ffcd79")
	# Side signage stays outside the grid's playable columns (96..1184).
	for x in [8.0, width - 88.0]:
		draw_rect(Rect2(x, -28, 80, 56), Color("243943"))
		draw_string(ThemeDB.fallback_font, Vector2(x + 5, 0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		for i in range(2):
			var lit := state != 0 and (phase == (i == 0))
			if lit:draw_circle(Vector2(x + 26 + i * 26, -17),10,Color(1,0.3,0.2,0.15))
			draw_circle(Vector2(x + 26 + i * 26, -17), 6, Color("ff6654") if lit else Color("52665e"))
		var arrow := ">>>" if direction > 0 else "<<<"
		draw_string(ThemeDB.fallback_font, Vector2(x + 23, 19), arrow, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
