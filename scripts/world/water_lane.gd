class_name WaterLane
extends Node2D
## Fixed pool in travel order. Shared lane speed prevents overtaking or gap collapse.
var theme: LevelThemeConfig = LevelThemeConfig.new()
var config: WaterLaneConfig
var row: int = 0
var width: float = 1280.0
var platforms: Array[FloatingPlatform] = []
var elapsed: float = 0.0
var current_speed: float = 0.0
var rng := RandomNumberGenerator.new()
var _redraw_left: float = 0.0

func setup(settings: WaterLaneConfig, lane_row: int, level: LevelConfig, seed_value: int) -> void:
	process_physics_priority = -20
	config = settings
	row = lane_row
	position.y = level.cell_position(Vector2i(0,row)).y
	rng.seed = seed_value
	current_speed = config.platform_speed
	var count := ceili((width + config.platform_length * 2.0) / config.pitch_min()) + 2
	var travel := -config.pitch_max() * 2.0 + rng.randf_range(0, config.pitch_min())
	for i in range(count):
		var platform := FloatingPlatform.new()
		platform.setup(config)
		platform.travel = travel
		platform.position.x = travel if config.direction > 0 else width - travel
		add_child(platform)
		platforms.append(platform)
		travel += next_pitch()
	queue_redraw()

func next_pitch() -> float:
	return rng.randf_range(config.pitch_min(), config.pitch_max()) if config.spawn_variation else config.pitch_min()

func _physics_process(delta: float) -> void:
	elapsed += delta
	current_speed = config.platform_speed * (1.0 + sin(elapsed * TAU / config.variation_period) * config.speed_variation)
	var movement := current_speed * delta
	for platform in platforms:
		platform.travel += movement
		platform.motion_x = movement * config.direction
		platform.position.x = platform.travel if config.direction > 0 else width - platform.travel
	for platform in platforms:
		if not platform.carrying_player and platform.travel > width + config.platform_length * 0.5 + 64:
			var back := INF
			for other in platforms:
				back = minf(back, other.travel)
			platform.travel = back - next_pitch()
			platform.position.x = platform.travel if config.direction > 0 else width - platform.travel
			platform.motion_x = 0.0
	_redraw_left -= delta
	if _redraw_left <= 0:
		_redraw_left = 0.1 # Water ripples at 10 Hz, no shader or particles.
		queue_redraw()

func support_at(x: float) -> FloatingPlatform:
	for platform in platforms:
		if platform.supports_x(x):
			return platform
	return null

func _draw() -> void:
	draw_rect(Rect2(0,-32,width,64),theme.water_color)
	draw_rect(Rect2(0,24,width,8),theme.water_edge_color)
	var shift := fmod(elapsed * 12.0 * config.direction * theme.ripple_visual_speed,48.0)
	for x in range(-48,int(width)+48,64):
		for y in [-20.0, 20.0]:
			draw_line(Vector2(x+shift,y),Vector2(x+shift+21,y),theme.water_ripple_color,2)
	for x in [24.0,width-44.0]:
		draw_string(ThemeDB.fallback_font,Vector2(x,6),">>" if config.direction>0 else "<<",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c2e3df"))
