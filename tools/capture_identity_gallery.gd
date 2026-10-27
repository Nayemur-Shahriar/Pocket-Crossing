extends "res://tools/identity_gallery.gd"
func _ready() -> void:
	super._ready()
	capture_all.call_deferred()
func capture_all() -> void:
	for index in range(6):
		for category in range(3):
			show_page(category,index)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://docs/screenshots/m12_gallery_%s_%d.png" % [THEME_IDS[index],category])
			print("Captured gallery ",THEME_IDS[index]," ",category)
	get_tree().quit.call_deferred()
