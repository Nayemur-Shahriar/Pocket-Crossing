class_name RailwayTrackConfig
extends Resource
## Intervals are clear-to-next-warning delays. The section may extend them for fairness.
@export_enum("Left:-1", "Right:1") var direction: int = 1
@export_range(80.0, 1000.0) var speed: float = 310.0
@export_range(2.0, 20.0) var warning_seconds: float = 3.0
@export_range(2.0, 120.0) var interval_min: float = 20.0
@export_range(2.0, 120.0) var interval_max: float = 24.0
@export_range(0.0, 120.0) var initial_delay: float = 2.0
@export_range(2.0, 30.0) var safe_delay: float = 3.0
@export_range(128.0, 768.0) var train_length: float = 360.0
@export var timing_variation: bool = true
## Optional art only; null keeps the original train.
@export var visual: TrainVisualConfig

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if absi(direction) != 1 or not is_finite(speed) or speed < 80.0 or speed > 1000.0:
		errors.append("Track direction must be -1/+1; speed must be 80–1000")
	if not is_finite(warning_seconds) or warning_seconds < 2.0 or warning_seconds > 20.0:
		errors.append("Every train requires 2–20 seconds of warning")
	if not is_finite(safe_delay) or safe_delay < 2.0 or safe_delay > 30.0:
		errors.append("Safe delay must be 2–30 seconds")
	if not is_finite(interval_min) or not is_finite(interval_max) or interval_min < safe_delay or interval_max < interval_min or interval_max > 120.0:
		errors.append("Train interval must be ordered, at least safe_delay, and at most 120 seconds")
	if not is_finite(initial_delay) or initial_delay < 0 or initial_delay > 120:
		errors.append("Initial delay must be 0–120 seconds")
	if not is_finite(train_length) or train_length < 128 or train_length > 768:
		errors.append("Train length must be 128–768 pixels")
	if visual != null and not visual.is_valid():
		errors.append("Train visual needs engine and coach textures")
	return errors
