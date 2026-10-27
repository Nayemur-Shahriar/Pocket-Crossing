class_name VehicleVisualConfig
extends Resource
## Pure presentation/dimensions. Motion is always TrafficVehicle.
@export var id: String = ""
@export var display_name: String = ""
@export var texture: Texture2D
@export var visual_size := Vector2(116,58)
@export var collision_size := Vector2(92,38)
## Optional simple convex outline in pixels; mirrored with the vehicle direction.
@export var collision_outline: PackedVector2Array = PackedVector2Array()
@export var spacing_envelope: float = 144.0
@export var tint_with_lane_color := false
## Nominal pixels/second at Lane Speed 150 and Speed Modifier 1.
@export_range(50.0, 250.0) var base_speed: float = 150.0

func is_valid() -> bool:
	if not collision_outline.is_empty():
		if collision_outline.size()<3 or collision_outline.size()>8: return false
		for point in collision_outline:
			if not point.is_finite() or absf(point.x)>collision_size.x/2 or absf(point.y)>collision_size.y/2: return false
		if Geometry2D.convex_hull(collision_outline).size()!=collision_outline.size()+1: return false
	return is_finite(base_speed) and base_speed >= 50 and base_speed <= 250 and not id.is_empty() and texture != null and visual_size.is_finite() and collision_size.is_finite() and visual_size.x > 0 and visual_size.y > 0 and collision_size.x > 0 and collision_size.y > 0 and collision_size.x <= visual_size.x and collision_size.y <= visual_size.y and is_finite(spacing_envelope) and spacing_envelope >= visual_size.x
