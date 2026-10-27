extends Node
var frames := 0
var largest := 0
var game: CrossingGame
var effect: ResultCelebration
func _process(_delta: float) -> void:
	frames += 1
	if is_instance_valid(effect): largest = maxi(largest,effect.bursts.size())
func _ready() -> void: run.call_deferred()
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/m13_fireworks_"+label+".png")
func run() -> void:
	game = load("res://tools/campaign_preview.tscn").instantiate()
	add_child(game)
	game.select_level(3)
	game.world.set_active(false)
	SaveData.sound_enabled = true
	SaveData.level_scores[game.world.config.level_id] = 100
	game.score = 2000
	game.finish_game(true,"Capture fixture")
	effect = game.hud.result_panel.celebration
	var begin := Time.get_ticks_msec()
	var baseline_nodes := get_tree().get_node_count()
	await get_tree().create_timer(1.0).timeout
	await shot("01s")
	await get_tree().create_timer(29.0).timeout
	await shot("30s")
	await get_tree().create_timer(30.0).timeout
	await shot("60s")
	var elapsed := (Time.get_ticks_msec()-begin)/1000.0
	print("FIREWORK WALL RUN seconds=",elapsed," frames=",frames," max_bursts=",largest," emitted=",effect.emitted," sounds=",effect.sound_events," nodes_start=",baseline_nodes," nodes_end=",get_tree().get_node_count())
	var ok := effect.emitted>=40 and effect.emitted==effect.sound_events and largest<=2 and get_tree().get_node_count()<=baseline_nodes
	game.hud.result_panel.replay_button.pressed.emit()
	ok = ok and effect.finished and not effect.voice.playing and effect.bursts.is_empty()
	await get_tree().process_frame
	await shot("after_replay")
	game.queue_free()
	await get_tree().process_frame
	for voice in Audio.get_children():
		if voice is AudioStreamPlayer:voice.stop()
	await get_tree().create_timer(0.3).timeout
	print("FIREWORK RENDER RESULT: ","PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
