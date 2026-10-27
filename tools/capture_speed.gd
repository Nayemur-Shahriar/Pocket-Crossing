extends "res://tools/speed_preview.gd"
func _ready() -> void:
	super._ready()
	capture.call_deferred()
func capture() -> void:
	for label in ["start","after_four_seconds"]:
		if label=="after_four_seconds": await get_tree().create_timer(4.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/screenshots/m13_speed_"+label+".png")
	get_tree().quit()
