class_name LevelThemeConfig
extends Resource
## Visual-only settings. Clear is the legacy name for NONE. No gameplay parameters.
@export var theme_id: String = "day"
@export var display_name: String = "Day"
@export_enum("Day", "Evening", "Night") var time_of_day: String = "Day"
@export var environment_id: String = "greenway"
@export_group("Environment")
@export var background_color := Color("b6cbb0")
@export var ambient_tint := Color.WHITE
@export_range(0.55, 1.2, 0.01) var ambient_brightness: float = 1.0
@export var ground_tint: Color = Color(0.8, 0.64, 0.33, 0.12)
@export var road_tint := Color.WHITE
@export var grass_tint := Color.WHITE
@export var safe_tint := Color.WHITE
@export var markings_color := Color("9baaa6")
@export var railway_color := Color("727b70")
@export var rail_color := Color("b6c4bd")
@export var destination_color := Color("e8ecd0")
@export var destination_border := Color("749780")
@export_range(0.0, 1.0) var wetness: float = 0.0
@export_range(0.0, 1.0) var snow_coverage: float = 0.0
@export_group("Weather — visual only")
@export_enum("Clear", "Rain", "Snow", "Fog") var weather: String = "Clear"
@export_range(0.0, 1.0, 0.01) var weather_intensity: float = 0.0
@export_range(0, 240, 1) var particle_amount: int = 120
@export_range(0.0, 0.3, 0.01) var fog_strength: float = 0.0
@export var atmosphere_color := Color("c0d6de")
@export_group("Readability and lights")
@export var vehicle_lights: bool = false
@export var train_lights: bool = false
@export var player_highlight: bool = false
@export_range(0.0, 1.0) var light_strength: float = 0.65
@export_group("Water — visual only")
@export var water_color := Color("397f99")
@export var water_edge_color := Color("326f86")
@export var water_ripple_color := Color("72b3c4")
@export_range(0.0, 2.0) var ripple_visual_speed: float = 1.0

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if theme_id.is_empty() or display_name.is_empty() or time_of_day not in ["Day","Evening","Night"] or weather not in ["Clear","Rain","Snow","Fog"]:
		errors.append("Unknown/empty theme metadata")
	for spec in [[ambient_brightness,0.55,1.2],[weather_intensity,0.0,1.0],[fog_strength,0.0,0.3],[wetness,0.0,1.0],[snow_coverage,0.0,1.0],[light_strength,0.0,1.0],[ripple_visual_speed,0.0,2.0]]:
		if not is_finite(spec[0]) or spec[0] < spec[1] or spec[0] > spec[2]:
			errors.append("Theme value outside readable range")
	if particle_amount < 0 or particle_amount > 240:
		errors.append("Particle amount must be 0–240")
	for color: Color in [background_color,ambient_tint,ground_tint,road_tint,grass_tint,safe_tint,markings_color,railway_color,rail_color,destination_color,destination_border,atmosphere_color,water_color,water_edge_color,water_ripple_color]:
		for value: float in [color.r,color.g,color.b,color.a]:
			if not is_finite(value) or value < 0 or value > 1:
				errors.append("Invalid theme color")
	return errors

static func resolve(candidate: LevelThemeConfig) -> LevelThemeConfig:
	return candidate if candidate != null and candidate.validation_errors().is_empty() else LevelThemeConfig.new()

func surface(color: Color) -> Color:
	return Color(color.r * ambient_tint.r * ambient_brightness, color.g * ambient_tint.g * ambient_brightness, color.b * ambient_tint.b * ambient_brightness, color.a)
