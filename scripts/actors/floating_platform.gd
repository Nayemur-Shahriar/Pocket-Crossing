class_name FloatingPlatform
extends Node2D
## Visual support surface; no physics body or parenting of the player is needed.
var visual: PlatformVisualConfig
var length: float = 224.0
var kind: String = "small_boat"
var direction: int = 1
var travel: float = 0.0
var motion_x: float = 0.0
var carrying_player := false
var riders: Dictionary = {}
func set_rider(id: int, present: bool) -> void:
	if present:riders[id]=true
	else:riders.erase(id)
	carrying_player=not riders.is_empty()


func setup(settings: WaterLaneConfig) -> void:
	visual = settings.visual
	length = settings.platform_length
	kind = settings.platform_type
	direction = settings.direction
	queue_redraw()

func supports_x(x: float) -> bool:
	# Player's 26px body/feet must fit inside the visibly highlighted deck.
	return absf(x - position.x) <= support_half_width()

func support_half_width() -> float:
	return maxf(0.0, length * 0.5 - 18.0)

func overlaps_playable_width(width: float) -> bool:
	return position.x + support_half_width() >= 0.0 and position.x - support_half_width() <= width

func _draw() -> void:
	var left := -length * 0.5
	draw_rect(Rect2(left + 5, 16, length - 10, 9), Color(0.05, 0.2, 0.28, 0.3))
	if visual != null and visual.is_valid():
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(direction, 1))
		draw_texture_rect(visual.texture, Rect2(left, -26, length, 52), false)
		draw_set_transform(Vector2.ZERO)
		# Same foot-support boundary as legacy decks, regardless of texture scaling.
		draw_line(Vector2(left+18,-16),Vector2(-left-18,-16),Color("fff0bc"),2)
		return
	if kind == "log":
		draw_style_box(_style(Color("866343"), 16), Rect2(left, -23, length, 46))
		draw_rect(Rect2(left + 10, -16, length - 20, 32), Color("b49b69"))
		for y in [-10.0, 4.0, 12.0]:
			draw_line(Vector2(left + 15,y),Vector2(-left - 15,y),Color("8b764d"),2)
		draw_arc(Vector2(left+10,0),10,-PI/2,PI/2,12,Color("d2ba88"),2)
	else:
		draw_style_box(_style(Color("253f4a"), 16), Rect2(left, -25, length, 50))
		var hull := Color("dba557") if kind != "long_boat" else Color("82b7a9")
		draw_style_box(_style(hull, 12), Rect2(left+4,-21,length-8,42))
		draw_rect(Rect2(left+13,-16,length-26,32),Color("ead9aa"))
		for x in range(int(left+26),int(-left-20),28):
			draw_line(Vector2(x,-14),Vector2(x,14),Color("c5ad7c"),1)
		draw_rect(Rect2(direction*(length/2-10)-3,-11,6,22),Color("557d81"))
	# The deck edge is the readable safe landing surface.
	draw_line(Vector2(left+18,-16),Vector2(-left-18,-16),Color("fff0bc"),2)

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
