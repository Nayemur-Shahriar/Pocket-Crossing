class_name TrafficVehicle
extends Area2D

signal hit_player(player: CrossingPlayer)
var speed: float = 150.0
var direction: int = 1
var paint: Color = Color.WHITE
var is_van: bool = false
var vehicle_type: String = "car"
@onready var art: Sprite2D = $Art

var visual: VehicleVisualConfig
func _ready() -> void:
	visual = VehicleLibrary.find_visual(vehicle_type)
	if visual == null or not visual.is_valid():
		visual = VehicleLibrary.find_visual("car")
	art.texture = visual.texture
	art.scale = visual.visual_size / art.texture.get_size()
	art.modulate = paint if visual.tint_with_lane_color else Color.WHITE
	art.flip_h = direction < 0
	if visual.collision_outline.is_empty():
		var shape := RectangleShape2D.new()
		shape.size = visual.collision_size
		$CollisionShape2D.shape = shape
	else:
		var shape := ConvexPolygonShape2D.new()
		var points := visual.collision_outline.duplicate()
		for i in range(points.size()): points[i].x *= direction
		shape.points = points
		$CollisionShape2D.shape = shape
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	if position.x < -400.0 or position.x > 1680.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is CrossingPlayer:
		body.contact_cause=vehicle_type
		hit_player.emit(body)

var presentation_theme: LevelThemeConfig = LevelThemeConfig.new()
func apply_theme(theme: LevelThemeConfig) -> void:
	presentation_theme = theme
	queue_redraw()
func _draw() -> void:
	if presentation_theme.vehicle_lights:
		var length := visual.visual_size.x if visual != null else 116.0
		ThemeArt.lights(self, direction, length, presentation_theme.light_strength)
