class_name PlatformVisualConfig
extends Resource
## Art only. WaterLaneConfig still owns length, pitch, speed and support.
@export var display_name: String = "Wooden boat"
@export var texture: Texture2D
func is_valid() -> bool:
	return texture != null
