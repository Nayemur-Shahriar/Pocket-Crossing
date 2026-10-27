extends Node
var game: CrossingGame
var passed := 0
var failed := 0
const PRESETS = ["day","evening","night","rain","snow","fog"]
func _ready() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print(("PASS " if ok else "FAIL ")+label)
func frames(count: int = 6) -> void:
	for i in range(count): await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame # process_frame is emitted before Node._process.
func run() -> void:
	var normal := {}
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = SaveData.PATH + suffix
		normal[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	game = load("res://tools/theme_preview.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	SaveData.sound_enabled = false
	var world := game.world
	var presentation := world.presentation
	var effects := presentation.weather
	var haze := presentation.haze
	var road := world.lanes[0]
	var track := world.railways[0].tracks[0]
	var water := world.water_lanes[0]
	check(game.state == CrossingGame.State.PLAYING and world.config.goal_row == 23,"Single theme preview launches real long layout")
	check(SaveData.storage_path == "user://section_preview_profile.cfg","Theme preview profile isolated")
	world.set_active(false)
	for i in range(PRESETS.size()):
		var theme := load("res://resources/themes/"+PRESETS[i]+".tres") as LevelThemeConfig
		check(theme != null and theme.validation_errors().is_empty(),PRESETS[i]+" Resource loads and validates")
		var source := world.source_config.duplicate(false) as LevelConfig
		source.presentation = theme
		var compiled := source.compile_layout()
		check(compiled.config.presentation == theme and compiled.total_rows == 24,PRESETS[i]+" assignment compiles without changing layout")
		var lane_rng := road.rng.state
		var track_remaining := track.remaining
		var water_elapsed := water.elapsed
		var player_position := world.player.position
		var score := game.score
		game.select_theme(i)
		check(world.lanes[0] == road and world.railways[0].tracks[0] == track and world.water_lanes[0] == water,PRESETS[i]+" switches without rebuilding gameplay nodes")
		check(road.rng.state == lane_rng and track.remaining == track_remaining and water.elapsed == water_elapsed and world.player.position == player_position and game.score == score,PRESETS[i]+" leaves simulation/scoring/RNG unchanged")
		check(world.terrain.theme == theme and world.get_node("BoardArt").theme == theme and track.theme == theme and water.theme == theme and world.goals[8].theme == theme,PRESETS[i]+" reaches all environment components")
		check(road.get_child(0).presentation_theme == theme and track.train.theme == theme,PRESETS[i]+" reaches existing vehicle and train visuals")
		check(presentation.weather == effects and presentation.haze == haze and presentation.get_child_count() == 2,PRESETS[i]+" keeps exactly one weather pool and haze")
		var expected := roundi(theme.particle_amount*theme.weather_intensity) if theme.weather in ["Rain","Snow"] else 0
		check(effects.positions.size() == expected and expected <= 240,PRESETS[i]+" uses bounded viewport particle count")
		if i > 0:
			check(theme.surface(theme.road_tint) != LevelThemeConfig.new().surface(Color.WHITE),PRESETS[i]+" has its own road material tint")
		# Newly spawned road vehicles inherit the selected lights too.
		var fresh := road.spawn_vehicle(-2000)
		check(fresh != null and fresh.presentation_theme == theme,PRESETS[i]+" reaches newly spawned vehicles")
		road.remove_child(fresh)
		fresh.queue_free()
	check(LevelThemeConfig.resolve(null).theme_id == "day","Missing theme falls back to Day")
	for field in ["ambient_brightness","fog_strength","particle_amount","weather"]:
		var invalid := LevelThemeConfig.new()
		invalid.set(field, "Storm" if field == "weather" else (9999 if field == "particle_amount" else NAN))
		world.apply_theme(invalid)
		check(presentation.used_fallback and presentation.theme.theme_id == "day" and effects.positions.is_empty(),"Invalid "+field+" falls back safely")
	game.select_theme(3)
	world.set_active(true)
	var initial := effects.positions.duplicate()
	await frames()
	check(effects.positions != initial,"Rain particles actually animate")
	game.toggle_pause()
	var paused := effects.positions.duplicate()
	var paused_time := effects.elapsed
	await frames()
	check(effects.positions == paused and effects.elapsed == paused_time,"Rain freezes while paused")
	game.toggle_pause()
	await frames()
	check(effects.elapsed > paused_time,"Rain resumes")
	game.select_theme(4)
	await frames()
	game.toggle_pause()
	paused = effects.positions.duplicate()
	await frames()
	check(effects.positions == paused,"Snow freezes while paused")
	game.toggle_pause()
	world.set_active(false)
	for row in [7,13,22,13,0,17,0]:
		world.player.cell = Vector2i(8,row)
		world.player.position = world.config.cell_position(world.player.cell)
		world.camera.snap_to_player()
		world.activation.refresh(true)
		presentation.follow_camera()
		check(is_equal_approx(effects.get_global_transform_with_canvas().origin.y,0) and effects.positions.size() == 104,"Weather stays screen-relative at row %d" % row)
		check(presentation.weather == effects and presentation.get_child_count() == 2,"Streaming/backtracking does not duplicate effects")
	var pool_id := effects.get_instance_id()
	for i in range(5):
		game.start_run(42)
		world.set_active(false)
		check(world.presentation.weather.get_instance_id() == pool_id and effects.positions.size() == 104,"Retry retains one correctly reset snow pool")
	# Presentation persists through the existing damage/respawn path.
	game.world.player.invulnerable_left = 0
	game._on_collision(world.player)
	game._physics_process(world.config.hit_reset_seconds + 0.1)
	check(presentation.theme.theme_id == "snow" and effects == presentation.weather and game.lives == 2,"Death/respawn keeps assigned theme")
	game.show_menu()
	check(not presentation.visible and not effects.can_process(),"Level Select hides and stops all weather")
	# Use the real Next Level handler, not a direct presentation-only call.
	var first := world.source_config.duplicate(false) as LevelConfig
	var second := first.duplicate(false) as LevelConfig
	first.level_id = "theme_transition_rain"
	second.level_id = "theme_transition_night"
	first.presentation = load("res://resources/themes/rain.tres")
	second.presentation = load("res://resources/themes/night.tres")
	var catalog := LevelCatalog.new()
	catalog.levels = [first,second]
	game.CAMPAIGN = catalog
	game.select_level(0)
	game._on_step_completed(Vector2i(8,23))
	check(game.state == CrossingGame.State.LEVEL_COMPLETE,"First themed level completes normally")
	game._on_primary()
	check(game.level_index == 1 and presentation.theme.theme_id == "night" and effects.positions.is_empty() and world.lanes[0].get_child(0).presentation_theme.vehicle_lights,"Next Level replaces rain with night/lights")
	check(presentation.visible and effects.get_instance_id() == pool_id,"Next Level reuses one presentation owner")
	game.show_menu()
	check(not presentation.visible,"Next Level then menu leaves no overlay")
	var config := first.duplicate(false) as LevelConfig
	config.presentation = null
	check(world.configure(config) and presentation.used_fallback and presentation.theme.theme_id == "day","Level Resource with missing presentation loads Day")
	for original: LevelConfig in load("res://tests/fixtures/legacy_campaign.tres").levels:
		check(world.configure(original),"Legacy campaign still loads: "+original.display_name)
		world.apply_theme(load("res://resources/themes/night.tres"))
		check(world.get_node("BoardArt").theme.theme_id == "night" and world.lanes[0].presentation_theme.vehicle_lights,"Short-board theme integration: "+original.display_name)
	for path: String in normal:
		var current := FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
		check(current == normal[path],"Normal profile/backup/temp untouched")
	game.queue_free()
	await get_tree().process_frame
	game = null
	print("THEME RESULTS: %d passed, %d failed" % [passed,failed])
	get_tree().quit.call_deferred(1 if failed else 0)
