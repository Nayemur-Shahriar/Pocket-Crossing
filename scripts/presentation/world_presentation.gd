class_name WorldPresentation
extends Node2D
## Exactly one owner per world. No timers, saving, damage, or section spawning.
var theme: LevelThemeConfig
var requested_theme: LevelThemeConfig
var camera: LevelCamera
var weather: WeatherEffects
var haze: AtmosphereHaze
var used_fallback := false

func _ready() -> void:
	weather = WeatherEffects.new()
	weather.z_index = 4 # Light precipitation over hazards, below player (5)/signals (8).
	add_child(weather)
	haze = AtmosphereHaze.new()
	haze.z_index = 2 # Terrain haze cannot obscure moving hazards or platform edges.
	add_child(haze)

func configure(candidate: LevelThemeConfig, view: LevelCamera) -> void:
	requested_theme = candidate
	used_fallback = candidate == null or not candidate.validation_errors().is_empty()
	theme = LevelThemeConfig.resolve(candidate)
	camera = view
	weather.configure(theme)
	haze.configure(theme)
	follow_camera()

func follow_camera() -> void:
	if camera == null:
		return
	# Camera uses a fixed top-left anchor; pool coordinates remain in logical screen space.
	weather.position = camera.position
	haze.position = camera.position

func _process(_delta: float) -> void:
	follow_camera()
