class_name AtmosphereHaze
extends Node2D
## Gentle distant haze behind player/vehicles/platforms/signals. No opaque fog wall.
var theme: LevelThemeConfig
func configure(settings: LevelThemeConfig) -> void:
	theme = settings
	queue_redraw()
func _draw() -> void:
	if theme == null or theme.fog_strength <= 0:
		return
	for i in range(16):
		var alpha := theme.fog_strength * (1.0 - float(i)/20.0)
		draw_rect(Rect2(0,108+i*31.75,1280,32),Color(theme.atmosphere_color,alpha))
