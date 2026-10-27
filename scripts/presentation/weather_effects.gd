class_name WeatherEffects
extends Node2D
## A fixed screen-sized particle pool. Never uses world length or gameplay RNG.
var theme: LevelThemeConfig
var positions := PackedVector2Array()
var elapsed: float = 0.0
var redraw_left: float = 0.0

func configure(settings: LevelThemeConfig) -> void:
	theme = settings
	elapsed = 0
	redraw_left = 0
	positions.clear()
	var count := roundi(theme.particle_amount * theme.weather_intensity) if theme.weather in ["Rain","Snow"] else 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 10010
	positions.resize(count)
	for i in range(count):
		positions[i] = Vector2(rng.randf_range(0,1280),rng.randf_range(108,616))
	set_process(count > 0)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	var rain := theme.weather == "Rain"
	for i in range(positions.size()):
		var p := positions[i]
		p.y = 108 + fposmod(p.y - 108 + delta * (490 if rain else 36 + i % 23),508)
		p.x = fposmod(p.x + delta * (-135 if rain else sin(elapsed+i)*16),1280)
		positions[i] = p
	redraw_left -= delta
	if redraw_left <= 0:
		redraw_left = 1.0/30.0
		queue_redraw()

func _draw() -> void:
	if theme == null:
		return
	for i in range(positions.size()):
		var p := positions[i]
		if theme.weather == "Rain":
			if p.y < 600:
				draw_line(p,p+Vector2(-5,15),Color(0.76,0.88,0.95,0.42),1.3)
		else:
			draw_circle(p,1.4+float(i%3)*0.45,Color(0.95,0.98,1.0,0.7))
