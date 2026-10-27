extends Node
var passed := 0
var failed := 0
var game: CrossingGame
var normal_files := {}
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = SaveData.PATH + suffix
		normal_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	SaveData.storage_path = "user://m11_test.cfg"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(SaveData.storage_path + suffix)
	SaveData.load_profile()
	SaveData.sound_enabled = false
	game = load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	await get_tree().process_frame
	var catalog := game.CAMPAIGN
	check(catalog.levels.size() == 15, "15 authored campaign Resources")
	check(game.state == CrossingGame.State.MENU, "Normal startup opens Level Select")
	var scroll := game.hud.overlay.get_node("LevelScroll") as ScrollContainer
	check(scroll.follow_focus and scroll.get_child(0).get_child_count() == 15, "All 15 full-size cards in focus-following scroll")
	check(not SaveData.is_unlocked(1, catalog) and SaveData.is_unlocked(0, catalog), "Fresh campaign locks later levels")
	var ids := {}
	var names := {}
	var themes := {}
	var lengths := {}
	for i in range(15):
		var source: LevelConfig = catalog.levels[i]
		var compiled := source.compile_layout()
		var config := compiled.config
		check(not ids.has(source.level_id) and not source.level_id.is_empty(), "Unique level ID %02d" % (i+1))
		check(not names.has(source.display_name) and not source.display_name.is_empty() and source.level_number == i+1, "Valid name/number: " + source.display_name)
		ids[source.level_id] = true
		names[source.display_name] = true
		check(compiled.runtime_errors().is_empty(), "Road/rail/water and sections compile: " + source.display_name)
		check(source.sections.front().kind == 0 and source.sections.back().kind == 5 and config.goal_columns == [4,8,12], "Valid start and destination")
		check(source.presentation != null and source.presentation.validation_errors().is_empty(), "Valid assigned theme")
		themes[source.presentation.theme_id] = true
		lengths[compiled.total_rows] = true
		check(config.rate_completion(config.time_limit * (config.star_time_fraction+0.01), 2) == 3 and config.rate_completion(0, 2) == 2 and config.rate_completion(0, 1) == 1, "Achievable star tiers, no perfect-life requirement")
		check(SaveData.is_unlocked(i, catalog), "Sequential unlock: %02d" % (i+1))
		game.select_level(i)
		game.world.set_active(false)
		check(game.world.source_config == source and game.world.presentation.theme == source.presentation, "Correct layout and theme loaded")
		var coins := 0
		var powers := 0
		for cell: Vector2i in game.world.rewards.pickups:
			var pickup: RewardPickup = game.world.rewards.pickups[cell]
			check(compiled.safe_rows.has(cell.y) and cell != config.spawn_cell and game.world.can_enter_cell(cell), "Authored pickup on safe reachable cell")
			if pickup.kind == "coin": coins += 1
			else: powers += 1
		check(coins >= 4 and coins <= 12 and powers <= 3, "Bounded coins and sparse powers")
		game.score = 500
		game.time_left = config.time_limit * 0.85
		game.lives = 2
		game.finish_game(true, "test")
		check(game.state == CrossingGame.State.LEVEL_COMPLETE and game.run_stars == 3, "Completion awards rating")
		check(SaveData.completed_levels.has(source.level_id), "Stable-ID completion persisted")
		check((game.hud.result_panel.next_button != null) == (i < 14), "Next only exists before final level")
		if i < 14:
			game.hud.result_panel.next_button.pressed.emit()
			check(game.level_index == i+1 and game.state == CrossingGame.State.PLAYING and game.world.source_config == catalog.levels[i+1], "Next loads next Resource")
		else:
			check(game.hud.result_panel.record_label.text.contains("CAMPAIGN COMPLETE"), "Final campaign message")
	check(themes.size() == 6 and lengths.size() >= 10, "Six themes and varied route lengths")
	check(not SaveData.is_unlocked(15, catalog), "No nonexistent Level 16")
	# Detection must compare the final score with the previous saved best.
	game.select_level(0)
	game.world.set_active(false)
	var target := game.world.config.score_target
	SaveData.level_scores["greenway"] = target+50
	game.score = target
	game.run_coins = 7
	game.finish_game(true, "test") # configured target reward applies before comparison
	var panel := game.hud.result_panel
	check(game.previous_best == target+50 and game.new_high_score and game.score == target+100, "High score detected after reward, before saving")
	check(panel.score_value.text == str(target+100) and panel.best_value.text == str(target+100) and panel.coins_value.text == "+7", "Exact result score/best/run coins")
	check(panel.stars_label.text == game.hud.star_text(game.run_stars), "Result stars match earned rating")
	check(panel.record_label.text.contains("NEW HIGH SCORE") and panel.celebration != null, "Record message and repeating celebration")
	check(not game.controls.enabled and game.world.process_mode == Node.PROCESS_MODE_DISABLED, "Result blocks gameplay and freezes world")
	var at := game.world.player.position
	game.controls.direction_requested.emit(Vector2i(0,1))
	check(game.world.player.position == at and not game.world.player.moving, "Input cannot move behind result")
	var celebration := panel.celebration
	celebration.set_process(false)
	for tick in range(600): celebration._process(0.1)
	check(celebration.emitted >= 40 and not celebration.finished and celebration.bursts.size() <= 36 and celebration.sound_events == 0, "Repeats for 60 seconds with bounded bursts and respects mute")
	var audio_burst := ResultCelebration.new()
	audio_burst.sound = game.hud.celebration_sound
	add_child(audio_burst)
	audio_burst.set_process(false)
	SaveData.sound_enabled = true
	for tick in range(21): audio_burst._process(0.1)
	check(audio_burst.sound is AudioStreamWAV and audio_burst.sound_events > 0 and audio_burst.sound_events <= audio_burst.emitted and audio_burst.emitted >= 2, "Original audio plays only on explosions, with rate limiting")
	audio_burst.voice.stop()
	audio_burst.queue_free()
	SaveData.sound_enabled = false
	var count := game.score
	game.finish_game(true, "duplicate")
	check(game.score == count and game.hud.result_panel == panel, "No duplicate result/reward")
	panel.replay_button.pressed.emit()
	await get_tree().process_frame
	check(not is_instance_valid(panel) and not is_instance_valid(celebration), "Play Again cleans card and fireworks")
	check(game.state == CrossingGame.State.PLAYING and game.score == 0 and game.run_coins == 0 and game.lives == 3 and game.world.player.cell == game.world.config.spawn_cell, "Replay resets same run")
	check(game.world.camera.position.y == game.world.camera.maximum_scroll and game.world.presentation.get_child_count() == 2, "Replay resets camera without duplicate weather")
	for value in [target, target-100]:
		game.start_run(42)
		game.score = value
		game.finish_game(true, "equal/lower")
		check(not game.new_high_score and game.hud.result_panel.celebration == null, "Equal/lower best does not celebrate")
	# Fresh failed level must not unlock, award stars, or celebrate, even if a score record.
	SaveData.completed_levels = {}
	SaveData.level_scores = {}
	SaveData.level_stars = {}
	game.select_level(0)
	var before_wallet := SaveData.coins
	for cell: Vector2i in game.world.rewards.pickups.keys():
		if game.world.rewards.pickups[cell].kind == "coin":
			game._collect_reward(cell)
			break
	game.score = 321
	game.lives = 1
	game.world.player.invulnerable_left = 0
	game._on_collision(game.world.player)
	panel = game.hud.result_panel
	check(game.state == CrossingGame.State.GAME_OVER and panel.title_label.text == "TRY AGAIN", "No lives opens failure card")
	check(panel.next_button == null and panel.stars_label == null and panel.celebration == null, "Failure has no next/stars/fireworks")
	check(game.run_stars == 0 and not SaveData.level_stars.has("greenway") and not SaveData.is_unlocked(1,catalog), "Failure awards no completion or unlock")
	check(SaveData.coins == before_wallet+1 and panel.coins_value.text == "+1" and panel.best_value.text == "321", "Failure retains banked coin and existing high-score economy")
	panel.replay_button.pressed.emit()
	check(game.state == CrossingGame.State.PLAYING and game.level_index == 0, "Failure Play Again")
	game.finish_game(false, "Time's up")
	game.hud.result_panel.select_button.pressed.emit()
	await get_tree().process_frame
	check(game.state == CrossingGame.State.MENU and game.hud.result_panel == null and not game.world.presentation.visible, "Failure Level Select cleans effects")
	# Completed M10 profile carries forward by stable IDs; no economy migration.
	SaveData.completed_levels = {"greenway":true, "level_02":true, "level_03":true, "level_04":true, "level_05":true}
	SaveData.level_scores = {"greenway":1990}
	SaveData.level_stars = {"greenway":3}
	SaveData.coins = 77
	SaveData.unlocked_characters["ember"] = true
	SaveData.selected_character = "mint"
	SaveData.save()
	SaveData.load_profile()
	check(SaveData.is_unlocked(5,catalog) and not SaveData.is_unlocked(6,catalog), "Old five completions unlock Level 6")
	check(SaveData.coins == 77 and SaveData.level_scores.greenway == 1990 and SaveData.level_stars.greenway == 3 and SaveData.selected_character == "mint", "Existing wallet/best/stars/character preserved")
	var invalid := catalog.levels[0].duplicate(true) as LevelConfig
	invalid.sections[1].pickups = invalid.sections[0].pickups
	check(not invalid.playability_errors().is_empty(), "Reject pickup placement on hazardous sections")
	# Mixed late level reset covers every runtime family.
	for level in catalog.levels: SaveData.completed_levels[level.level_id] = true
	game.select_level(14)
	var road_count := game.world.lanes.size()
	var water_count := game.world.water_lanes.size()
	var rail_count := game.world.railways.size()
	var owner := game.world.presentation
	for retry in range(3):
		game.start_run(42)
		await get_tree().process_frame
		check(game.world.lanes.size() == road_count and game.world.water_lanes.size() == water_count and game.world.railways.size() == rail_count and game.world.traffic.get_child_count() == road_count+water_count+rail_count, "Final-level retry has no duplicate runtime components")
		check(game.world.presentation == owner and owner.get_child_count() == 2, "Final-level retry reuses theme owner")
	# Reactivation in the actual final campaign configuration retains independent clocks.
	game.world.set_active(false)
	var first_lane := game.world.lanes[0]
	var first_water := game.world.water_lanes[0]
	first_lane.active_seconds = 8.25
	first_water.elapsed = 6.5
	game.world.player.cell = Vector2i(8, 30)
	game.world.player.position = game.world.config.cell_position(game.world.player.cell)
	game.world.camera.snap_to_player()
	game.world.activation.refresh(true)
	check(not first_lane.visible, "Final-level distant road deactivates")
	game.world.player.reset_to_spawn()
	check(first_lane.visible and first_lane.active_seconds == 8.25 and first_water.elapsed == 6.5, "Backtrack/reactivation retains road and water clocks")
	game.toggle_pause()
	var clock := game.time_left
	await get_tree().process_frame
	check(game.time_left == clock and game.world.process_mode == Node.PROCESS_MODE_DISABLED, "Mixed final level pauses")
	game.toggle_pause()
	game.finish_game(true, "final")
	panel = game.hud.result_panel
	panel.select_button.pressed.emit()
	await get_tree().process_frame
	check(not is_instance_valid(panel) and game.state == CrossingGame.State.MENU and not game.world.presentation.visible, "Completion Level Select removes result and atmosphere")
	await get_tree().process_frame
	check(get_viewport().gui_get_focus_owner().name == "Level_15", "Return menu focuses and scrolls to last played level")
	game.queue_free()
	await get_tree().process_frame
	game = null
	for path in normal_files:
		var after := FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
		check(after == normal_files[path], "Normal profile untouched")
	print("CAMPAIGN RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit.call_deferred(1 if failed else 0)
