class_name ThemeArt
extends RefCounted
## Stateless cheap draw helpers, shared by short and long terrain and all vehicles.
static func surface_details(node: Node2D, y: float, theme: LevelThemeConfig, road: bool) -> void:
	if theme.time_of_day=="Night" and road:
		for x in range(110,1280,192):
			for edge in [-29,29]:
				var at:=Vector2(x,y+edge)
				node.draw_circle(at,7,Color(1,0.89,0.54,0.08))
				node.draw_rect(Rect2(at-Vector2(3,1),Vector2(6,2)),Color(1,0.91,0.62,0.65))
	if theme.wetness > 0.0 and road:
		for x in range(100,1280,176):
			node.draw_line(Vector2(x,y+19),Vector2(x+94,y+19),Color(0.62,0.8,0.86,0.28*theme.wetness),2)
	if theme.snow_coverage > 0.0:
		var c := Color(0.86,0.93,0.97,theme.snow_coverage)
		node.draw_rect(Rect2(0,y-32,1280,5 if road else 9),c)
		for x in range(0,1280,96):
			node.draw_circle(Vector2(x+17,y-27),5,c)

static func lights(node: Node2D, direction: int, length: float, strength: float) -> void:
	if strength <= 0:
		return
	var nose := direction * length * 0.5
	for y in [-13.0,13.0]:
		node.draw_colored_polygon(PackedVector2Array([Vector2(nose,y-3),Vector2(nose+direction*74,y-19),Vector2(nose+direction*74,y+19),Vector2(nose,y+3)]),Color(1.0,0.91,0.61,0.12*strength))
		node.draw_circle(Vector2(nose,y),4,Color(1.0,0.96,0.74,strength))
		node.draw_circle(Vector2(-nose,y),3,Color(1.0,0.25,0.21,strength))
