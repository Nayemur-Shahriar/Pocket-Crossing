extends Node2D
## Brief, non-violent impact marker; no physics or gameplay authority.
var remaining := 0.42

func _process(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0.0:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var fade := remaining / 0.42
	var radius := 18.0 + (1.0 - fade) * 24.0
	var color := Color(1.0, 0.83, 0.52, fade)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, color, 3.0, true)
	for i in range(6):
		var direction := Vector2.from_angle(i * TAU / 6.0)
		draw_line(direction * (radius + 5), direction * (radius + 11), color, 2.0, true)
