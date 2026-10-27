class_name DestinationZone
extends Node2D
## Grid entry is the authority; visual state never decides scoring.

var theme: LevelThemeConfig = LevelThemeConfig.new()
var occupied: bool = false
var character_texture: Texture2D
var occupied_color := Color("245b54")
var occupied_border := Color("aeeaa7")
var number: int = 1
var pulse: float = 0.0

func set_occupied(value: bool) -> void:
	pulse = 0.4 if value and not occupied else 0.0
	occupied = value
	queue_redraw()

func _process(delta: float) -> void:
	if pulse > 0.0:
		pulse = maxf(0.0, pulse - delta)
		queue_redraw()

func _draw() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = occupied_color if occupied else theme.destination_color
	style.border_color = occupied_border if occupied else theme.destination_border
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.05, 0.15, 0.13, 0.18)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	style.draw(get_canvas_item(), Rect2(-40, -29, 80, 57))
	draw_line(Vector2(-26, -22), Vector2(26, -22), CrossingStyle.GREEN if occupied else Color("f6f5df"), 3.0, true)
	if pulse > 0.0:
		var alpha := pulse / 0.4
		draw_arc(Vector2.ZERO, 30.0 + (1.0 - alpha) * 20.0, 0, TAU, 48, Color(0.85, 0.97, 0.68, alpha), 3.0, true)
		for i in range(6):
			var angle := i * TAU / 6.0 - PI / 2.0
			var at := Vector2.from_angle(angle) * (26.0 + (1.0 - alpha) * 28.0)
			draw_circle(at, 2.5, Color(0.97, 0.81, 0.45, alpha))
	if occupied:
		draw_polyline(PackedVector2Array([Vector2(-12, 0), Vector2(-3, 9), Vector2(14, -10)]), Color("d8f8af"), 5.0, true)
	else:
		draw_circle(Vector2.ZERO, 18.0, Color("c3dab0"))
		draw_string(ThemeDB.fallback_font, Vector2(-6, 7), str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("32594b"))

	if occupied and character_texture!=null:
		draw_texture_rect(character_texture,Rect2(-15,-20,30,36),false)
