class_name WaterLaneConfig
extends Resource
## Direction is the platform/current direction. Intervals define nominal spatial pitch.
@export_enum("Left:-1", "Right:1") var direction: int = 1
@export_range(20.0, 120.0) var platform_speed: float = 90.0
@export_range(0.5, 12.0) var spawn_min: float = 2.0
@export_range(0.5, 12.0) var spawn_max: float = 3.0
@export_enum("boat_placeholder", "small_boat", "long_boat", "log") var platform_type: String = "boat_placeholder"
@export_range(112.0, 384.0) var platform_length: float = 224.0
@export_range(24.0, 96.0) var minimum_spacing: float = 32.0
@export var spawn_variation: bool = true
@export_range(0.0, 0.12) var speed_variation: float = 0.0
@export_range(4.0, 30.0) var variation_period: float = 10.0
## Optional art only; platform length/support remain unchanged.
@export var visual: PlatformVisualConfig

func pitch_min() -> float:
	return maxf(platform_length + minimum_spacing, platform_speed * spawn_min)
func pitch_max() -> float:
	return maxf(pitch_min(), platform_speed * (spawn_max if spawn_variation else spawn_min))
func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if absi(direction) != 1 or not is_finite(platform_speed) or platform_speed < 20 or platform_speed > 120:
		errors.append("Water direction must be -1/+1; platform speed must be 20–120")
	if not is_finite(spawn_min) or not is_finite(spawn_max) or spawn_min < 0.5 or spawn_max < spawn_min or spawn_max > 12:
		errors.append("Water spawn intervals must be ordered within 0.5–12 seconds")
	if platform_type not in ["boat_placeholder", "small_boat", "long_boat", "log"]:
		errors.append("Unknown floating platform type")
	if not is_finite(platform_length) or platform_length < 112 or platform_length > 384:
		errors.append("Platform length must be 112–384 pixels")
	if not is_finite(minimum_spacing) or minimum_spacing < 24 or minimum_spacing > 96:
		errors.append("Platform spacing must be 24–96 pixels")
	if not is_finite(speed_variation) or speed_variation < 0 or speed_variation > 0.12 or not is_finite(variation_period) or variation_period < 4 or variation_period > 30:
		errors.append("Speed variation must be 0–12%, with a 4–30 second period")
	if errors.is_empty() and pitch_max() - platform_length > 96:
		errors.append("Spawn interval leaves more than 96 pixels of open water; shorten interval or lengthen platforms")
	if visual != null and not visual.is_valid():
		errors.append("Platform visual needs a texture")
	return errors
