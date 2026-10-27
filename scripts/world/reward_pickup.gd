class_name RewardPickup
extends Node2D
## Tiny drawn icon; collection uses the existing completed-hop signal, no extra physics.
var coin_value: int = 1
var kind: String = "coin"
var power: PowerUpConfig
var collected: bool = false
var fade_left: float = 0.0
func collect() -> void:
	collected = true
	fade_left = 0.35
	queue_redraw()
func _process(delta: float) -> void:
	if not collected:
		return
	fade_left = maxf(0.0, fade_left - delta)
	queue_redraw()
	if fade_left <= 0.0:
		queue_free()
func _draw() -> void:
	var color := Color("f6cb70") if power == null else power.color
	if collected:
		var t := 1.0 - fade_left / 0.35
		draw_arc(Vector2.ZERO, 16 + 22 * t, 0, TAU, 24, Color(color, 1 - t), 3, true)
		for i in range(5):
			var angle := i * TAU / 5
			draw_circle(Vector2.from_angle(angle) * (15 + t * 27), 2.5, Color(color, 1 - t))
		return
	draw_circle(Vector2(0, 3), 16, Color(0.04, 0.12, 0.15, 0.22))
	draw_circle(Vector2.ZERO, 15, Color("203d46"))
	draw_arc(Vector2.ZERO, 13, 0, TAU, 24, color, 2, true)
	if kind == "coin":
		draw_circle(Vector2.ZERO, 9, color)
		if coin_value==3:
			draw_arc(Vector2.ZERO,18,0,TAU,24,color,2,true)
			draw_string(ThemeDB.fallback_font,Vector2(-5,6),"3",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("203d46"))
		else:draw_line(Vector2(0, -6), Vector2(0, 6), Color("9a6d31"), 2)
	else:
		var text := "S" if kind == "shield" else ("T" if kind == "slow" else "2")
		draw_string(ThemeDB.fallback_font, Vector2(-6, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, color)
