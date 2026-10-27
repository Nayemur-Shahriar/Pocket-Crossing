class_name LaneConfig
extends Resource
@export_range(0,120) var phase_offset: float=0.0
## One horizontal traffic stream. Row counts upward from the starting sidewalk.

@export_range(0, 4095) var row: int = 1
@export_enum("Left:-1", "Right:1") var direction: int = 1
@export_range(50.0, 350.0) var speed: float = 150.0
@export_range(0.5, 1.5) var speed_modifier: float = 1.0
@export_range(0.8, 5.0) var spawn_min: float = 1.8
@export_range(0.8, 5.0) var spawn_max: float = 2.8
@export var vehicle_colors: Array[Color] = [Color("f8c96c"), Color("8acbc2")]

@export_group("Fair traffic spacing")
@export_range(120.0, 500.0) var minimum_clear_gap: float = 220.0
@export_range(0.6, 3.0) var minimum_gap_seconds: float = 1.4
@export_range(0.0, 0.15) var speed_variation: float = 0.06
@export_range(6.0, 40.0) var variation_period: float = 18.0

@export_group("Vehicles and patterns")
## Repeated entries provide simple weights without another spawning system.
@export var vehicle_types: Array[String] = ["car", "car", "car", "truck"]
@export_enum("steady", "waves", "railway") var pattern: String = "steady"
@export var cycle_seconds: float = 12.0
@export var open_seconds: float = 5.0
@export var warning_seconds: float = 2.5

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(speed_modifier) or speed_modifier < 0.5 or speed_modifier > 1.5:
		errors.append("Lane speed modifier must be 0.5–1.5")
	if absi(direction) != 1 or not is_finite(speed) or speed <= 0:
		errors.append("Road direction must be -1/+1 and speed positive")
	if not is_finite(spawn_min) or not is_finite(spawn_max) or spawn_min <= 0 or spawn_max < spawn_min:
		errors.append("Road spawn intervals must be positive and ordered")
	if vehicle_types.is_empty() or vehicle_colors.is_empty():
		errors.append("Road requires vehicle types and colors")
	for type in vehicle_types:
		if VehicleLibrary.find_visual(type) == null or not VehicleLibrary.find_visual(type).is_valid():
			errors.append("Unknown vehicle type: " + type)
	if not is_finite(minimum_clear_gap) or minimum_clear_gap <= 0 or not is_finite(minimum_gap_seconds) or minimum_gap_seconds <= 0 or not is_finite(speed_variation) or speed_variation < 0 or speed_variation > 0.15 or not is_finite(variation_period) or variation_period <= 0:
		errors.append("Invalid road gap/speed variation settings")
	if pattern not in ["steady", "waves", "railway"]:
		errors.append("Unknown traffic pattern")
	if pattern != "steady" and (not is_finite(cycle_seconds) or not is_finite(open_seconds) or not is_finite(warning_seconds) or open_seconds < 0 or warning_seconds < 0 or cycle_seconds <= open_seconds + warning_seconds):
		errors.append("Traffic cycle must exceed open + warning duration")
	if not is_finite(phase_offset) or phase_offset<0 or phase_offset>120:errors.append("Invalid phase offset")
	return errors
