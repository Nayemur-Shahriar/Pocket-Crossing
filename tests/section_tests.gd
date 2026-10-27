extends Node
var passed := 0
var failed := 0
var game: CrossingGame
const DEMO := preload("res://resources/examples/road_sections_demo.tres")
const MIXED := preload("res://resources/examples/mixed_layout_data_only.tres")
func _ready() -> void:
	run.call_deferred()
func check(ok: bool, text: String) -> void:
	if ok:
		passed += 1
		print("PASS ", text)
	else:
		failed += 1
		push_error("FAIL " + text)
func fresh() -> LevelConfig:
	var config := DEMO.duplicate(false) as LevelConfig
	config.sections = []
	# External templates are shared intentionally; make each edited test section unique.
	for original in DEMO.sections:
		var section := original.duplicate(false) as LevelSectionConfig
		section.road_lanes = []
		section.blocked_cells = original.blocked_cells.duplicate()
		section.destination_columns = original.destination_columns.duplicate()
		for lane in original.road_lanes:
			section.road_lanes.append(lane.duplicate(true))
		config.sections.append(section)
	return config
func rejected(config: LevelConfig, label: String) -> void:
	check(not config.validation_errors().is_empty(), label)
func run() -> void:
	SaveData.storage_path = "user://section_tests.cfg"
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SaveData.storage_path + suffix):
			DirAccess.remove_absolute(SaveData.storage_path + suffix)
	SaveData.load_profile()
	SaveData.sound_enabled = false
	var layout := DEMO.compile_layout()
	check(layout.errors.is_empty() and layout.runtime_errors().is_empty(), "Road section example is valid and playable")
	check(layout.total_rows == 7 and layout.sections.size() == 5, "Ordered sections produce contiguous seven-row layout")
	check(layout.config.lanes.size() == 4 and layout.safe_rows == [0, 3], "Derived lane count and safe rows are correct")
	check(layout.config.goal_row == 6 and layout.config.spawn_cell == Vector2i(8, 0), "Start/destination compile to existing grid contract")
	check(layout.config.lanes[0].row == 1 and layout.config.lanes[3].row == 5, "Local lane rows assigned from section order")
	check(layout.config.lanes[0].direction == 1 and layout.config.lanes[1].direction == -1, "Per-lane directions retained")
	check(layout.config.lanes[0].speed == 155 and layout.config.lanes[1].speed == 180, "Independent per-lane speeds retained")
	check(layout.config.lanes[1].spawn_min == 2.2 and layout.config.lanes[1].minimum_gap_seconds == 1.6, "Spawn density and gap settings retained")
	check(layout.config.level_id == DEMO.level_id and layout.config.time_limit == DEMO.time_limit, "Stable progression ID and time limit preserved")
	check(layout.section_at(4).kind == LevelSectionConfig.Kind.ROAD_SECTION and layout.section_at(-1).is_empty(), "Section lookup maps global rows safely")
	var original_row := DEMO.sections[1].road_lanes[0].row
	layout.config.lanes[0].row = 99
	layout.config.lanes[0].vehicle_types.append("test")
	check(DEMO.sections[1].road_lanes[0].row == original_row and not DEMO.sections[1].road_lanes[0].vehicle_types.has("test"), "Compiler does not mutate shared lane resources")
	check(DEMO.sections.size() == 5 and DEMO.lanes.is_empty(), "Source section array and legacy fields stay untouched")
	var changed := fresh()
	changed.sections[0].spawn_column = 5
	changed.sections[-1].destination_columns = [1, 9]
	changed.sections[2].blocked_cells = [Vector2i(4, 0)]
	var customized := changed.compile_layout()
	check(customized.config.spawn_cell == Vector2i(5, 0) and customized.config.goal_columns == [1, 9], "Section start and destination settings override obsolete flat fields")
	check(customized.config.obstacles.has(Vector2i(4, 3)), "Section-local obstacle rows translated correctly")
	changed = fresh()
	changed.sections[2].safe_rows = 2
	changed.sections[3].road_lanes = [LaneConfig.new()]
	check(changed.compile_layout().safe_rows == [0, 3, 4] and changed.playability_errors().is_empty(), "Multirow safe section reflows downstream lanes")
	var theme_variant := fresh()
	theme_variant.presentation = LevelThemeConfig.new()
	theme_variant.presentation.time_of_day = "Night"
	theme_variant.presentation.weather = "Rain"
	var themed := theme_variant.compile_layout()
	check(themed.config.goal_row == 6 and themed.config.lanes[0].speed == 155 and themed.config.time_limit == DEMO.time_limit, "Theme metadata independent of gameplay and difficulty")
	check(themed.config.presentation == theme_variant.presentation, "Presentation resource carried through without weather simulation")
	var mixed := MIXED.compile_layout()
	check(mixed.errors.is_empty() and mixed.total_rows > 7, "Long Road/Rail/Water/Road/Rail combination validates as data")
	check(mixed.deferred_features.is_empty() and mixed.runtime_errors().is_empty(), "Mixed long layout now playable with M9 camera")
	check(mixed.sections[2].resource.railway_tracks[0].warning_seconds == 3 and mixed.sections[4].resource.water_lanes[0].platform_speed == 90, "Track and platform metadata remain available in section descriptors")
	for combination in [[1,3,1], [1,4,3], [1,3,4,1], [1,3,4,3,1]]:
		var recipe := fresh()
		recipe.sections = [load("res://resources/sections/start.tres")]
		for kind in combination:
			var path := "road_pair" if kind == 1 else ("railway_pair" if kind == 3 else "water_pair")
			recipe.sections.append(load("res://resources/sections/" + path + ".tres"))
		recipe.sections.append(load("res://resources/sections/destination.tres"))
		check(recipe.validation_errors().is_empty(), "Mixed ordered recipe validates: " + str(combination))
	for count in [1, 2, 3]:
		var recipe := fresh()
		var rail := LevelSectionConfig.new()
		rail.kind = LevelSectionConfig.Kind.RAILWAY_SECTION
		for i in range(count):
			rail.railway_tracks.append(RailwayTrackConfig.new())
		recipe.sections = [recipe.sections[0], rail, recipe.sections[-1]]
		check(recipe.validation_errors().is_empty() and recipe.playability_errors().is_empty(), "%d configured tracks validate and can launch" % count)
	changed = fresh()
	changed.sections[0] = null
	rejected(changed, "Missing section rejected")
	changed = fresh()
	changed.sections.remove_at(0)
	rejected(changed, "Missing START rejected")
	changed = fresh()
	changed.sections.insert(2, changed.sections[0])
	rejected(changed, "Duplicate/misplaced START rejected")
	changed = fresh()
	changed.sections[-1] = changed.sections[2]
	rejected(changed, "Missing DESTINATION rejected")
	changed = fresh()
	changed.sections[1].road_lanes.clear()
	rejected(changed, "Zero-lane ROAD rejected")
	changed = fresh()
	changed.sections[1].road_lanes[0] = null
	rejected(changed, "Missing lane resource rejected")
	changed = fresh()
	changed.sections[1].road_lanes[0].speed = -1
	rejected(changed, "Negative speed rejected")
	changed = fresh()
	changed.sections[1].road_lanes[0].direction = 0
	rejected(changed, "Invalid direction rejected")
	changed = fresh()
	changed.sections[1].road_lanes[0].spawn_max = 0.1
	rejected(changed, "Reversed spawn interval rejected")
	changed = fresh()
	changed.sections[1].road_lanes[0].vehicle_types = ["train"]
	rejected(changed, "Train hidden in new ROAD section rejected")
	changed = fresh()
	changed.sections[1].road_lanes[0].minimum_gap_seconds = -1
	rejected(changed, "Unsafe negative gap rejected")
	changed = fresh()
	changed.sections[2].blocked_cells = [Vector2i(0, 5)]
	rejected(changed, "Out-of-section obstacle rejected")
	changed = fresh()
	for column in range(changed.columns):
		changed.sections[2].blocked_cells.append(Vector2i(column, 0))
	rejected(changed, "Full-width blocked safe zone makes destinations unreachable")
	changed = fresh()
	changed.sections[-1].destination_columns = [2, 2]
	rejected(changed, "Duplicate destination columns rejected")
	changed = fresh()
	changed.sections[0].spawn_column = -1
	rejected(changed, "Invalid start column rejected")
	changed = fresh()
	changed.sections[0].section_id = "same"
	changed.sections[-1].section_id = "same"
	rejected(changed, "Duplicate explicit section IDs rejected")
	var track := RailwayTrackConfig.new()
	track.interval_min = 1
	check(not track.validation_errors().is_empty(), "Train interval shorter than warning rejected")
	var water := WaterLaneConfig.new()
	water.platform_speed = NAN
	check(not water.validation_errors().is_empty(), "Nonfinite platform speed rejected")
	changed = fresh()
	changed.sections[2].safe_rows = 3
	check(changed.validation_errors().is_empty() and changed.playability_errors().is_empty(), "Long road-only layout is valid and playable")
	# Exercise the actual game/world, not a replacement implementation.
	game = load("res://scenes/legacy_main.tscn").instantiate()
	game.CAMPAIGN = load("res://tests/fixtures/legacy_campaign.tres")
	add_child(game)
	await get_tree().process_frame
	game.set_physics_process(false)
	for config: LevelConfig in game.CAMPAIGN.levels:
		check(game.world.configure(config) and game.world.config == config, "Legacy resource loads unchanged: " + config.display_name)
		check(game.world.lanes.size() == config.lanes.size(), "Legacy lane count preserved: " + config.display_name)
	var source := fresh()
	source.level_id = "future_section_route_900"
	var catalog := LevelCatalog.new()
	var invalid := MIXED.duplicate(false) as LevelConfig
	invalid.columns = 17 # Horizontal landscape geometry is still validated.
	catalog.levels = [source, invalid]
	game.CAMPAIGN = catalog
	game.select_level(0)
	game.world.set_active(false)
	check(game.state == CrossingGame.State.PLAYING and game.world.lanes.size() == 4, "Section level starts through existing selection/controller flow")
	check(game.hud.level_config == game.world.config and game.world.player.config == game.world.config, "HUD and player share compiled rules")
	check(game.world.goals.size() == 4 and game.world.rewards.pickups.size() > 0, "Existing destinations and pickups built for sections")
	check(game.world.player.can_enter.call(Vector2i(8, 3)), "SAFE section remains a resting area")
	var wallet := SaveData.coins
	for key: Vector2i in game.world.rewards.pickups.keys():
		if game.world.rewards.pickups[key].kind == "coin":
			game._on_step_completed(key)
			break
	check(SaveData.coins == wallet + 1, "Coins still bank in a compiled section level")
	game.powers.activate(load("res://resources/powerups/slow.tres"))
	game._physics_process(0.01)
	check(game.world.lanes[0].effect_scale < 1, "Power-ups still affect compiled traffic")
	game.toggle_pause()
	var clock := game.time_left
	game._physics_process(1)
	check(game.time_left == clock, "Section level pauses without advancing timer")
	game.toggle_pause()
	for column in game.world.config.goal_columns:
		game._set_state(CrossingGame.State.PLAYING)
		game._on_step_completed(Vector2i(column, game.world.config.goal_row))
	check(game.state == CrossingGame.State.LEVEL_COMPLETE and SaveData.level_stars.has(source.level_id), "Existing destination completion awards stars using stable source ID")
	SaveData.load_profile()
	check(SaveData.completed_levels.has(source.level_id) and SaveData.level_scores.has(source.level_id), "Section progress survives existing save/load schema")
	var old_config := game.world.config
	var old_lane := game.world.lanes[0]
	check(not game.world.configure(invalid) and game.world.config == old_config and game.world.lanes[0] == old_lane, "Unsupported configuration fails atomically, preserving active world")
	game.show_menu()
	game.select_level(1)
	check(game.state == CrossingGame.State.MENU and game.level_index == 0, "Controller refuses invalid geometry without changing state")
	game.select_level(0)
	check(game.score == 0 and game.run_coins == 0 and game.powers.active.is_empty(), "Retry/selection resets run effects and counters")
	for voice in Audio.get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SaveData.storage_path + suffix):
			DirAccess.remove_absolute(SaveData.storage_path + suffix)
	print("SECTION RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed else 0)
