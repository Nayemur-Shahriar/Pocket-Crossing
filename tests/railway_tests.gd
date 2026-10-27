extends Node
var passed := 0
var failed := 0
var game: CrossingGame
const DEMO := preload("res://resources/examples/railway_demo.tres")
func _ready() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print(("PASS " if ok else "FAIL ") + label)
func advance(section: RailwaySection, seconds: float) -> void:
	for i in range(ceili(seconds * 60.0)):
		section._physics_process(1.0 / 60.0)
func variant(count: int) -> LevelConfig:
	var level := DEMO.duplicate(false) as LevelConfig
	var rail := LevelSectionConfig.new()
	rail.kind = LevelSectionConfig.Kind.RAILWAY_SECTION
	for i in range(count):
		var settings := RailwayTrackConfig.new()
		settings.direction = 1 if i % 2 == 0 else -1
		settings.speed = 400 + i * 100
		settings.initial_delay = 0.0
		settings.interval_min = 3.0
		settings.interval_max = 4.0
		rail.railway_tracks.append(settings)
	level.sections = [DEMO.sections[0], rail, DEMO.sections[4], DEMO.sections[5]]
	return level
func run() -> void:
	# Never write the normal profile. Snapshot it including backup/temp if present.
	var normal := {}
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = SaveData.PATH + suffix
		normal[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	game = load("res://tools/railway_preview.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	check(game.state == CrossingGame.State.PLAYING and game.world.config.level_id == DEMO.level_id, "Preview directly opens railway demo")
	check(SaveData.storage_path == "user://section_preview_profile.cfg", "Preview uses isolated profile")
	game.set_physics_process(false)
	game.world.set_active(false)
	check(DEMO.playability_errors().is_empty() and game.world.layout.total_rows == 7, "Demo fits seven rows")
	check(game.world.lanes.size() == 1 and game.world.railways[0].tracks.size() == 2, "Road and two tracks coexist")
	check(game.world.layout.safe_rows == [0,2,5], "Safe zones bracket both railway tracks")
	for site in game.world.reward_sites():
		check(site.key.y not in [3,4], "Pickups excluded from railway rows")
	for count in [1,2,3]:
		check(game.world.configure(variant(count)), "%d-track configuration loads" % count)
		var section := game.world.railways[0]
		check(section.tracks.size() == count, "Track count matches Resource")
		advance(section, 1.5)
		check(section.tracks[0].state == RailwayTrack.State.SAFE and not section.tracks[0].train.visible, "Initial safe window")
		advance(section, 0.6)
		for track in section.tracks:
			check(track.state == RailwayTrack.State.WARNING and not track.train.visible, "Warning precedes train")
		advance(section, 2.0)
		check(not section.tracks[0].train.visible, "Full warning duration respected")
		advance(section, 1.1)
		for track in section.tracks:
			check(track.state == RailwayTrack.State.PASSING and track.train.running, "Warned train enters")
			var x := track.train.position.x
			advance(section, 0.1)
			check(signf(track.train.position.x - x) == track.config.direction, "Train direction matches config")
			check((track.train.hitbox.shape as RectangleShape2D).size.x == track.config.train_length - 12, "Hitbox matches visible train")
		var first_train := section.tracks[0].train
		advance(section, 8.0)
		check(section.tracks[0].train == first_train, "One train reused across cycles")
		# Every entry must follow WARNING, never SAFE->PASSING, across many cycles.
		var previous: Array[int] = []
		for track in section.tracks: previous.append(track.state)
		var ordered := true
		var common_safe := 0.0
		var longest_safe := 0.0
		for step in range(3600):
			section._physics_process(1.0/60.0)
			var all_safe := true
			for i in range(count):
				var track := section.tracks[i]
				if track.state == RailwayTrack.State.PASSING and previous[i] != RailwayTrack.State.PASSING:
					ordered = ordered and previous[i] == RailwayTrack.State.WARNING
				previous[i] = track.state
				all_safe = all_safe and track.state == RailwayTrack.State.SAFE
			common_safe = common_safe + 1.0/60.0 if all_safe else 0.0
			longest_safe = maxf(longest_safe, common_safe)
		check(ordered, "Every repeated train has warning")
		check(longest_safe >= 1.99, "Shared safe window survives overlapping schedules")
	var invalid := RailwayTrackConfig.new()
	invalid.warning_seconds = 0
	check(not invalid.validation_errors().is_empty(), "Instant train config rejected")
	invalid = RailwayTrackConfig.new()
	invalid.speed = INF
	check(not invalid.validation_errors().is_empty(), "Nonfinite speed rejected")
	invalid = RailwayTrackConfig.new()
	invalid.safe_delay = 0
	check(not invalid.validation_errors().is_empty(), "Missing safe delay rejected")
	var slow_hop := variant(3)
	slow_hop.hop_seconds = 1.0
	check(not slow_hop.playability_errors().is_empty(), "Insufficient warning for slow player rejected")
	game.world.configure(DEMO)
	game.start_run(17)
	game.world.set_active(false)
	var rail := game.world.railways[0]
	var track := rail.tracks[0]
	advance(rail, 2.2)
	game.toggle_pause()
	var warning_left := track.remaining
	await get_tree().create_timer(0.15).timeout
	check(track.remaining == warning_left, "Pause freezes warning")
	game.toggle_pause()
	game.world.set_active(false)
	advance(rail, 3.1)
	game.powers.activate(load("res://resources/powerups/slow.tres"))
	game._physics_process(0.01)
	var x := track.train.position.x
	advance(rail, 0.1)
	check(is_equal_approx(absf(track.train.position.x-x), track.config.speed * game.powers.traffic_scale() * 0.1), "Slow power-up affects train motion")
	game.toggle_pause()
	x = track.train.position.x
	var clock := game.time_left
	await get_tree().create_timer(0.15).timeout
	check(track.train.position.x == x and game.time_left == clock, "Pause freezes passing train and timer")
	game.toggle_pause()
	game.powers.clear()
	game.world.set_traffic_scale(1)
	# Real Area2D overlap goes through track -> world -> existing deferred damage.
	track.train.position.x = 640
	game.world.player.position = Vector2(640, track.position.y)
	game.world.player.moving = false
	game.world.player.invulnerable_left = 0
	game.powers.activate(load("res://resources/powerups/shield.tres"))
	var lives := game.lives
	await get_tree().create_timer(0.12).timeout
	check(game.lives == lives and not game.powers.active.has("shield"), "Train collision consumes shield without life loss")
	game.world.player.position = game.world.config.cell_position(game.world.config.spawn_cell)
	await get_tree().create_timer(0.08).timeout
	game.world.player.invulnerable_left = 0
	game.world.player.position = Vector2(track.train.position.x, track.position.y)
	await get_tree().create_timer(0.12).timeout
	check(game.lives == lives - 1 and game.state == CrossingGame.State.RESPAWNING, "Train collision uses normal life loss/respawn")
	game.hud.retry_pressed.emit()
	check(game.state == CrossingGame.State.PLAYING and game.lives == game.world.config.starting_lives, "Retry restores game")
	check(game.world.railways[0].tracks[0].state == RailwayTrack.State.SAFE and not game.world.railways[0].tracks[0].train.running, "Retry resets railway clocks and train")
	var start := game.world.player.position
	game.controls.direction_requested.emit(Vector2i.RIGHT)
	await get_tree().create_timer(0.3).timeout
	check(game.world.player.position != start, "Existing movement works in railway preview")
	game.world.set_active(false)
	var wallet := SaveData.coins
	for cell in game.world.rewards.pickups.keys():
		if game.world.rewards.pickups[cell].kind == "coin":
			game._on_step_completed(cell)
			break
	check(SaveData.coins == wallet+1, "Coins still bank")
	for column in game.world.config.goal_columns:
		game._set_state(CrossingGame.State.PLAYING)
		game._on_step_completed(Vector2i(column,game.world.config.goal_row))
	check(game.state == CrossingGame.State.LEVEL_COMPLETE, "Destination system completes railway level")
	SaveData.load_profile()
	check(SaveData.completed_levels.has(DEMO.level_id) and SaveData.level_scores.has(DEMO.level_id) and SaveData.level_stars.has(DEMO.level_id), "Completion, score, stars persist by ID")
	for path in normal:
		var data := FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
		check(data == normal[path], "Normal profile/backup/temp unchanged")
	for voice in Audio.get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
	game.queue_free()
	await get_tree().process_frame
	game = null
	# Clear temporary references before shutdown to avoid harness-only leaks.
	rail = null
	track = null
	await get_tree().create_timer(0.4).timeout
	print("RAILWAY RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit.call_deferred(1 if failed else 0)
