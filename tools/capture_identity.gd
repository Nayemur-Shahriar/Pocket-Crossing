extends "res://tools/capture_campaign.gd"
## Inherits M11's representative campaign/result capture workflow without duplication.
func capture(label: String) -> void:
	# The parent freezes simulation and teleports the camera for each sample.
	# Refresh camera-local scenery explicitly, just like terrain and weather.
	if label.begins_with("level_"):
		game.world.decorations.refresh(true)
	if label.begins_with("level_") and not game.world.railways.is_empty():
		var tracks := game.world.railways[0].tracks
		for i in range(tracks.size()):
			var track := tracks[i]
			track.state = RailwayTrack.State.SAFE
			track.remaining = 0
			track.begin_warning()
			if i == tracks.size()-1:
				track.state = RailwayTrack.State.PASSING
				track.train.launch(1280)
				track.train.position.x = 640
				track.signal_art.update_state(2,true)
	await get_tree().create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/m12_"+label+".png")
	print("Captured M12 ",label)
	if label.begins_with("level_"):
		var row := game.world.config.goal_row - 1
		game.world.player.cell = Vector2i(8,row)
		game.world.player.position = game.world.config.cell_position(game.world.player.cell)
		game.world.camera.snap_to_player()
		game.world.activation.refresh(true)
		game.world.terrain.refresh()
		game.world.decorations.refresh(true)
		game.world.presentation.follow_camera()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/screenshots/m12_"+label+"_destination.png")
		print("Captured M12 destination ",label)
