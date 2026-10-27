class_name TrainVisualConfig
extends Resource
@export var display_name: String = "Riverline"
@export var engine_texture: Texture2D
@export var coach_texture: Texture2D
func is_valid() -> bool:
	return engine_texture != null and coach_texture != null
