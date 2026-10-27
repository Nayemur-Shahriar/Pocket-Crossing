extends Node
## Real scene integration and save fixtures, isolated from the player's profile.
var passed := 0
var failed := 0
var game: CrossingGame
const TEST_PATH := "user://phase4_test.cfg"
func _ready() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
func clean() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(TEST_PATH + suffix):
			DirAccess.remove_absolute(TEST_PATH + suffix)
func collect(kind: String) -> Vector2i:
	for cell: Vector2i in game.world.rewards.pickups.keys():
		if game.world.rewards.pickups[cell].kind == kind:
			game._on_step_completed(cell)
			return cell
	check(false, "Pickup exists: " + kind)
	return Vector2i(-1, -1)
func run() -> void:
	SaveData.storage_path = TEST_PATH
	clean()
	SaveData.load_profile()
	check(SaveData.coins == 0 and SaveData.selected_character == "pip", "Missing profile uses safe defaults")
	check(SaveData.unlocked_characters.size() == 2, "Two free cosmetic skins")
	game = load("res://scenes/legacy_main.tscn").instantiate()
	game.CAMPAIGN = load("res://tests/fixtures/legacy_campaign.tres")
	add_child(game)
	await get_tree().process_frame
	game.set_physics_process(false)
	game.start_run(42)
	game.world.set_active(false)
	for level: LevelConfig in game.CAMPAIGN.levels:
		game.world.configure(level)
		var valid := not game.world.rewards.pickups.is_empty()
		for cell: Vector2i in game.world.rewards.pickups:
			valid = valid and game.world.can_enter_cell(cell) and cell != level.spawn_cell and cell.y < level.goal_row
			for lane in level.lanes:
				valid = valid and cell.y != lane.row
		check(valid, "Safe, reachable pickup cells: " + level.display_name)
		check(game.world.rewards.pickups.size() <= 15, "Bounded pickup count: " + level.display_name)
	game.world.configure(game.CAMPAIGN.levels[0])
	game.start_run(42)
	game.world.set_active(false)
	var coin_cell := collect("coin")
	check(SaveData.coins == 1 and game.run_coins == 1, "Coin banks immediately through completed-hop callback")
	game._on_step_completed(coin_cell)
	check(SaveData.coins == 1, "Repeated callback cannot award duplicate coin")
	SaveData.load_profile()
	check(SaveData.coins == 1, "Collected coin survives reload")
	collect("shield")
	game.world.player.invulnerable_left = 0
	game._on_collision(game.world.player)
	check(game.lives == 3 and game.state == CrossingGame.State.PLAYING, "Shield absorbs collision without losing life or resetting hop")
	check(not game.powers.active.has("shield") and game.world.player.invulnerable_left > 0, "Shield consumed with short collision grace")
	game._on_collision(game.world.player)
	check(game.lives == 3, "Same-frame second hit ignored during shield grace")
	game.world.player.invulnerable_left = 0
	game._on_collision(game.world.player)
	check(game.lives == 2 and game.state == CrossingGame.State.RESPAWNING, "Unshielded hit retains existing life/respawn flow")
	check(not game.world.rewards.pickups.has(coin_cell), "Death does not respawn collected coins")
	game.world.player.reset_to_spawn()
	game._set_state(CrossingGame.State.PLAYING)
	game.world.set_active(false)
	collect("slow")
	var lane := game.world.lanes[0]
	var car := lane.get_child(0) as TrafficVehicle
	check(is_equal_approx(car.speed, lane.speed_at(lane.active_seconds) * 0.65), "Slow effect reaches existing vehicles immediately")
	var new_car := lane.spawn_vehicle(-1000)
	check(new_car != null and is_equal_approx(new_car.speed, car.speed), "New vehicles inherit shared slow speed")
	var left: float = game.powers.active.slow.left
	game.toggle_pause()
	game._physics_process(2)
	check(is_equal_approx(game.powers.active.slow.left, left), "Pause freezes power duration")
	game.toggle_pause()
	game.world.set_active(false)
	game._physics_process(6.1)
	check(not game.powers.active.has("slow") and is_equal_approx(car.speed, lane.speed_at(lane.active_seconds)), "Slow expires and restores existing traffic speed")
	collect("double")
	var before := SaveData.coins
	collect("coin")
	check(SaveData.coins == before + 2, "Multiplier doubles coin reward")
	game.furthest_row = 0
	var points := game.score
	game._on_step_completed(Vector2i(2, 1))
	check(game.score == points + 20, "Multiplier doubles forward points")
	points = game.score
	game._on_step_completed(Vector2i(2, 6))
	check(game.score == points + 100 + 200 + int(game.time_left)*game.world.config.seconds_bonus + game.lives*game.world.config.life_bonus + (game.world.config.target_reward if game.score >= game.world.config.score_target else 0), "Multiplier doubles destination and forward points, then awards one completion bonus")
	game.powers.tick(9)
	check(game.powers.multiplier() == 1, "Reward multiplier expires")
	var shield: PowerUpConfig = load("res://resources/powerups/shield.tres")
	game.powers.activate(shield)
	game.powers.tick(4)
	game.powers.activate(shield)
	check(is_equal_approx(game.powers.active.shield.left, 12), "Repeated effect refreshes instead of stacking")
	game.start_run(42)
	check(game.powers.active.is_empty() and game.run_coins == 0, "Retry clears temporary effects and run counters")
	check(SaveData.coins == before + 2, "Retry keeps banked wallet")
	var cfg := game.world.config
	check(cfg.rate_completion(1, 1) == 1, "Completion alone earns one star")
	check(cfg.rate_completion(cfg.time_limit, 1) == 2, "Time threshold earns second star")
	check(cfg.rate_completion(1, 2) == 2, "Lives threshold earns second star")
	check(cfg.rate_completion(cfg.time_limit * cfg.star_time_fraction, 2) == 3, "Both thresholds earn three stars, inclusive boundaries")
	game.time_left = cfg.time_limit
	game.lives = 3
	game.score = int(SaveData.level_scores.get(cfg.level_id,0)) + 100
	game.finish_game(true, "test")
	check(SaveData.level_stars.get(cfg.level_id, 0) == 3, "Successful run saves stars")
	check(game.hud.result_stars == 3 and game.hud.result_coins == 0, "Results receive rating and coin totals")
	var total := game.score
	game.finish_game(true, "repeat")
	check(game.score == total, "Completion callback cannot duplicate rewards")
	SaveData.complete_level(cfg.level_id, 20, 1)
	check(SaveData.level_stars[cfg.level_id] == 3 and SaveData.level_scores[cfg.level_id] == total, "Worse replay never reduces stars or high score")
	game.start_run(42)
	game.score = total + 50
	game.finish_game(false, "test loss")
	check(SaveData.level_scores[cfg.level_id] == total + 50 and SaveData.level_stars[cfg.level_id] == 3, "Failed run can improve score without changing best stars")
	SaveData.coins = 0
	check(not SaveData.choose_character("coral"), "Insufficient coins cannot unlock character")
	check(not SaveData.choose_character("unknown"), "Unknown character ID safely rejected")
	SaveData.add_coins(60)
	check(SaveData.choose_character("coral") and SaveData.coins == 40, "Unlock spends exact coin price")
	check(SaveData.choose_character("coral") and SaveData.coins == 40, "Re-selecting owned skin never charges again")
	check(SaveData.choose_character("violet") and SaveData.coins == 0, "Second paid skin unlocks without negative balance")
	SaveData.load_profile()
	check(SaveData.selected_character == "violet" and SaveData.unlocked_characters.has("coral"), "Character selection and ownership survive reload")
	game.start_run(42)
	check(game.world.player.art.texture.resource_path.ends_with("courier_violet.svg"), "Selected skin applied at run start")
	var hitbox: Vector2 = game.world.player.get_node("CollisionShape2D").shape.size
	game.world.player.apply_skin("mint")
	check(game.world.player.get_node("CollisionShape2D").shape.size == hitbox and game.world.player.hop_duration == cfg.hop_seconds, "Cosmetics never change hitbox or movement")
	game.show_menu()
	game.hud.characters_pressed.emit()
	await get_tree().process_frame
	var button := game.hud.overlay.find_child("Skin_mint", true, false) as Button
	check(button != null and not button.disabled, "Character selection screen exposes free skin")
	button.pressed.emit()
	check(SaveData.selected_character == "mint" and game.state == CrossingGame.State.MENU, "Character UI selects without starting gameplay")
	game.hud.menu_pressed.emit()
	check(game.state == CrossingGame.State.MENU and not game.controls.enabled, "Return from characters preserves input isolation")
	# IDs and world sites are not tied to the current campaign's five layouts.
	SaveData.complete_level("future_chunk_route_42", 5432, 2)
	SaveData.load_profile()
	check(SaveData.level_scores.get("future_chunk_route_42", 0) == 5432 and SaveData.level_stars.get("future_chunk_route_42", 0) == 2, "Arbitrary future level IDs persist")
	var generic := RewardField.new()
	add_child(generic)
	var sites: Array[Dictionary] = [{"key": "chunk/a/coin", "position": Vector2(9000, -4000)}]
	var no_powers: Array[PowerUpConfig] = []
	generic.setup(sites, 1, no_powers)
	check(generic.take("chunk/a/coin") != null and generic.take("chunk/a/coin") == null, "Pickup system accepts opaque world keys and positions")
	generic.queue_free()
	# Typed malformed data: never blindly cast arrays/dictionaries into profile scalars.
	var malformed := ConfigFile.new()
	malformed.set_value("profile", "coins", [1, 2])
	malformed.set_value("profile", "best_score", "bad")
	malformed.set_value("progress", "scores", {"future": -20, "bad": []})
	malformed.set_value("progress", "stars", {"future": 99})
	malformed.set_value("progress", "completed", {"false": "yes", "future": true})
	malformed.set_value("characters", "selected", "not_owned")
	malformed.set_value("characters", "unlocked", {"fake": true})
	malformed.set_value("settings", "sound", [])
	malformed.save(TEST_PATH)
	SaveData.load_profile()
	check(SaveData.coins == 0 and SaveData.best_score == 0 and SaveData.sound_enabled, "Wrong scalar types fall back safely")
	check(SaveData.level_scores.future == 0 and SaveData.level_stars.future == 3, "Negative scores and excessive star values are clamped")
	check(not SaveData.completed_levels.has("false") and SaveData.completed_levels.has("future"), "Only boolean true unlock records accepted")
	check(SaveData.selected_character == "pip" and not SaveData.unlocked_characters.has("fake"), "Bad/locked character selections fall back")
	clean()
	var legacy := ConfigFile.new()
	legacy.set_value("profile", "best_score", 1234)
	legacy.set_value("settings", "sound", false)
	legacy.set_value("progress", "completed", {"greenway": true})
	legacy.set_value("progress", "scores", {"greenway": 1234})
	legacy.save(TEST_PATH)
	SaveData.load_profile()
	check(SaveData.best_score == 1234 and not SaveData.sound_enabled and SaveData.completed_levels.has("greenway"), "Phase 3 profile migrates without losing progress/settings")
	check(SaveData.coins == 0 and SaveData.level_stars.is_empty(), "Legacy profile does not invent coins or star performance")
	SaveData.add_coins(11)
	SaveData.add_coins(2)
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("[broken\n")
	file.close()
	SaveData.load_profile()
	check(SaveData.coins == 11 and SaveData.best_score == 1234, "Truncated save recovers last-good backup")
	clean()
	file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("[broken\n")
	file.close()
	SaveData.load_profile()
	check(SaveData.coins == 0 and SaveData.selected_character == "pip", "Corrupt save without backup starts safely")
	clean()
	SaveData.load_profile()
	SaveData.coins = 100
	SaveData.storage_path = "user://missing_phase4_folder/profile.cfg"
	check(not SaveData.choose_character("coral") and SaveData.coins == 100 and not SaveData.unlocked_characters.has("coral"), "Failed save rolls back purchase and selection")
	SaveData.storage_path = TEST_PATH
	clean()
	for voice in Audio.get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	print("PHASE 4 RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed else 0)
