extends "res://tools/capture_identity.gd"
## Reuses the representative campaign workflow; keeps M11/M12 evidence intact.
func capture(label: String) -> void:
	if label.begins_with("level_"):game.world.decorations.refresh(true)
	await get_tree().create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/m13_"+label+".png")
	print("Captured M13 ",label)
