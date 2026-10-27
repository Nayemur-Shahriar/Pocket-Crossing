class_name DogView
extends Node2D
## Exactly one visible encounter per device. Remote authority dogs have no nodes.
var phase:="idle"
var at:=Vector2.ZERO
var origin:=Vector2.ZERO
var direction:=1
var clock:=0.0
var seen_warning:=0
var warning_left:=0.0
var font: Font
func _ready() -> void:
	z_index=8;font=ThemeDB.fallback_font
func clear() -> void:
	phase="idle";seen_warning=0;queue_redraw()
func display(data: Dictionary, delta: float, audible: bool=true) -> void:
	clock+=delta;phase=data.get("phase","idle");at=data.get("at",Vector2.ZERO);origin=data.get("origin",Vector2.ZERO);direction=int(data.get("direction",1))
	warning_left=float(data.get("warning_left",0))
	var id:=int(data.get("warning_id",0))
	if phase=="warning" and id!=seen_warning:
		seen_warning=id
		if audible:Audio.play_cue("dog_bark")
	queue_redraw()
func _draw() -> void:
	if phase=="warning":
		var pos:=Vector2(clampf(origin.x+44 if origin.x<920 else origin.x-274,70,980),origin.y-16)
		draw_style_box(_warning_style(),Rect2(pos,Vector2(230,32)))
		draw_circle(pos+Vector2(17,16),6+sin(clock*12),Color("ffcc74"))
		draw_string(font,pos+Vector2(30,23),"DOG ALERT! MOVE!",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("fff2bc"))
		draw_line(pos+Vector2(8,30),pos+Vector2(8+214*clampf(warning_left,0,1),30),Color("ffcc74"),2)
		return
	if phase!="running":return
	draw_set_transform(at,0,Vector2(direction,1))
	draw_ellipse_shadow()
	var stride:=sin(clock*22)*7
	for i in range(4):
		var x: float=-15+i*9
		draw_line(Vector2(x,3),Vector2(x+(stride if i%2==0 else -stride),18),Color("79543c"),5,true)
	draw_line(Vector2(-21,-4),Vector2(-33,-14),Color("b77f50"),5,true)
	draw_ellipse_body()
	draw_circle(Vector2(22,-11),12,Color("c79765"))
	draw_polygon(PackedVector2Array([Vector2(14,-18),Vector2(17,-31),Vector2(23,-20)]),PackedColorArray([Color("6b4635")]))
	draw_circle(Vector2(33,-8),6,Color("d8af7f"));draw_circle(Vector2(37,-10),3,Color("27383b"));draw_circle(Vector2(25,-15),2,Color("203038"))
	draw_line(Vector2(15,-1),Vector2(26,0),Color("548d87"),3,true)
	draw_set_transform(Vector2.ZERO)
func draw_ellipse_body() -> void:
	draw_set_transform(at,0,Vector2(direction*1.8,1));draw_circle(Vector2(-1,-3),14,Color("b78555"));draw_set_transform(at,0,Vector2(direction,1))
func draw_ellipse_shadow() -> void:
	draw_set_transform(at+Vector2(0,17),0,Vector2(2.5,0.35));draw_circle(Vector2.ZERO,14,Color(0.05,0.12,0.14,0.18));draw_set_transform(at,0,Vector2(direction,1))
var warning_style: StyleBoxFlat
func _warning_style() -> StyleBoxFlat:
	if warning_style==null:
		warning_style=StyleBoxFlat.new();warning_style.bg_color=Color("65452e");warning_style.set_corner_radius_all(8)
	return warning_style
