class_name CrossingGame
extends Node
## Single authoritative owner of lives, score, time, and all screen transitions.
## Actors communicate through signals, so art and levels can be replaced freely.

enum State { MENU, PLAYING, RESPAWNING, PAUSED, GAME_OVER, LEVEL_COMPLETE }
var CAMPAIGN: LevelCatalog = load("res://resources/levels/campaign.tres")
var level_index: int = 0
var state: State = State.MENU
var score: int = 0
var run_coins: int = 0
var run_stars: int = 0
var new_high_score: bool = false
var previous_best: int = 0
var powers := PowerUpController.new()
var lives: int = 3
var time_left: float = 90.0
var destinations_reached: int = 0
var furthest_row: int = 0
var _respawn_left: float = 0.0
var _resume_state: State = State.PLAYING
var _low_time_warned: bool = false
@onready var world: RoadLevel = $World
@onready var hud: GameHUD = $HUD
@onready var controls: InputRouter = $InputRouter

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = true
	get_tree().quit_on_go_back = false
	controls.direction_requested.connect(_on_direction)
	controls.pause_requested.connect(toggle_pause)
	controls.restart_requested.connect(_request_restart)
	controls.sound_requested.connect(toggle_sound)
	hud.pause_pressed.connect(toggle_pause)
	hud.sound_pressed.connect(toggle_sound)
	hud.touch_direction.connect(controls.set_touch_direction)
	controls.gestures_reset.connect(hud.reset_touch_controls)
	controls.control_mode_changed.connect(hud.set_control_mode)
	hud.primary_pressed.connect(_on_primary)
	hud.secondary_pressed.connect(_on_secondary)
	hud.menu_pressed.connect(show_menu)
	hud.level_selected.connect(select_level)
	hud.characters_pressed.connect(func() -> void: hud.show_characters())
	hud.character_selected.connect(_choose_character)
	hud.retry_pressed.connect(start_run)
	hud.set_level(world.config, true)
	# A fatal hit disables the World subtree. Defer handling until the physics
	# server has finished flushing Area2D overlaps so that removal is safe.
	world.collision.connect(_queue_collision)
	world.water_hazard.connect(_on_water_hazard)
	world.player.step_completed.connect(_on_step_completed)
	world.player.step_started.connect(func() -> void: Audio.play_cue("hop"))
	world.player.step_blocked.connect(_on_blocked)
	show_menu()

func _physics_process(delta: float) -> void:
	if state == State.PLAYING or state == State.RESPAWNING:
		powers.tick(delta)
		world.set_traffic_scale(powers.traffic_scale())
		time_left = maxf(0.0, time_left - delta)
		if time_left <= 0.0:
			finish_game(false, "Time's up.")
			return
		if time_left <= 15.0 and not _low_time_warned:
			_low_time_warned = true
			hud.show_tip("15 seconds left. Make your next gap count!", 3.0)
		if state == State.RESPAWNING:
			_respawn_left -= delta
			if _respawn_left <= 0.0:
				world.player.reset_to_spawn()
				_set_state(State.PLAYING)
		_update_hud()

func start_run(seed_value: int = 0) -> void:
	score = 0
	run_coins = 0
	run_stars = 0
	new_high_score = false
	previous_best = 0
	powers.clear()
	lives = world.config.starting_lives
	time_left = world.config.time_limit
	destinations_reached = 0
	furthest_row = 0
	_respawn_left = 0.0
	_low_time_warned = false
	world.reset(seed_value)
	hud.hide_screen()
	hud.show_tip("Reach any finish. Swipe or use the arrows.", 4.0)
	_set_state(State.PLAYING)
	_update_hud()

func show_menu() -> void:
	if state == State.PLAYING or state == State.RESPAWNING or state == State.PAUSED:
		SaveData.record_level_score(world.config.level_id, score)
	powers.clear()
	world.set_traffic_scale(1.0)
	_set_state(State.MENU)
	hud.show_level_select(CAMPAIGN, level_index)
	_update_hud()

func _set_state(next_state: State) -> void:
	state = next_state
	world.presentation.visible = state != State.MENU
	world.decorations.set_running(state == State.PLAYING or state == State.RESPAWNING, state == State.MENU)
	controls.set_enabled(state == State.PLAYING)
	world.player.clear_buffer()
	world.set_active(state == State.PLAYING or state == State.RESPAWNING)

func _on_direction(direction: Vector2i) -> void:
	if state == State.PLAYING:
		world.player.request_step(direction)

func _on_step_completed(cell: Vector2i) -> void:
	if state != State.PLAYING:
		return
	_collect_reward(cell)
	if cell.y > furthest_row:
		score += (cell.y - furthest_row) * world.config.forward_points * powers.multiplier()
		furthest_row = cell.y
	if cell.y == world.config.goal_row and world.claim_destination(cell.x):
		score += world.config.destination_points * powers.multiplier()
		destinations_reached += 1
		Audio.play_cue("dock")
		var bonus := int(time_left) * world.config.seconds_bonus + lives * world.config.life_bonus
		score += bonus
		finish_game(true, "Time + lives bonus: %d points." % bonus)
	_update_hud()

func _queue_collision(player: CrossingPlayer) -> void:
	_apply_contact.call_deferred(player,player.contact_cause)
func _apply_contact(player: CrossingPlayer, cause: String) -> void:
	player.contact_cause=cause
	_on_collision(player)

func _on_collision(player: CrossingPlayer) -> void:
	if state != State.PLAYING:return
	var outcome:=CollisionRules.hit(player,powers)
	if outcome==CollisionRules.Hit.IGNORED:return
	if outcome==CollisionRules.Hit.SHIELDED:
		hud.show_tip("Shield absorbed the hit. Keep moving!", 2.5)
		Audio.play_cue("dock")
		_update_hud()
		return
	lives -= 1
	_record_death(player)
	HazardAudio.play(player.contact_cause)
	hud.hit_flash(hud.root.get_global_transform_with_canvas().affine_inverse() * player.get_global_transform_with_canvas().origin)
	if not self is MapGame and SaveData.vibration_enabled and OS.has_feature("android"):
		Input.vibrate_handheld(90)
	if lives <= 0:
		player.stop_and_hide()
		finish_game(false, "No lives left.")
	else:
		hud.show_tip("Ouch! %d %s left. Look for a wider gap." % [lives, "life" if lives == 1 else "lives"])
		_begin_respawn(world.config.hit_reset_seconds)
	_update_hud()

func _on_water_hazard(player: CrossingPlayer) -> void:
	if state != State.PLAYING or not player.visible:
		return
	# Reuse the single shield/invulnerability/life-loss path. If it protects the
	# player, return them to spawn rather than leaving them standing in water.
	player.contact_cause="water"
	_on_collision(player)
	if state == State.PLAYING:
		player.reset_to_spawn()
		hud.show_tip("Water rescue! Wait for a clear deck before hopping.", 3.0)

func _begin_respawn(delay: float) -> void:
	world.player.stop_and_hide()
	_respawn_left = delay
	_set_state(State.RESPAWNING)

func finish_game(completed: bool, detail: String) -> void:
	# Gate all terminal transitions to prevent duplicate scoring on the same frame.
	if state != State.PLAYING and state != State.RESPAWNING:
		return
	_set_state(State.LEVEL_COMPLETE if completed else State.GAME_OVER)
	previous_best = int(SaveData.level_scores.get(world.config.level_id, 0))
	new_high_score = false
	if completed:
		if score >= world.config.score_target:
			score += world.config.target_reward
			detail += " Target reward: +%d." % world.config.target_reward
		new_high_score = score > previous_best
		run_stars = world.config.rate_completion(time_left, lives)
		SaveData.complete_level(world.config.level_id, score, run_stars)
	else:
		SaveData.record_level_score(world.config.level_id, score)
	powers.clear()
	world.set_traffic_scale(1.0)
	hud.result_new_high_score = new_high_score
	hud.result_stars = run_stars
	hud.result_coins = run_coins
	if SaveData.last_save_error != OK:
		detail += " Save failed: check free storage."
	hud.show_screen("complete" if completed else "game_over", score, int(SaveData.level_scores.get(world.config.level_id, 0)), detail)
	if completed:
		Audio.play_cue("complete")
	_update_hud()

func toggle_pause() -> void:
	if state == State.PLAYING or state == State.RESPAWNING:
		_resume_state = state
		_set_state(State.PAUSED)
		hud.show_screen("pause")
	elif state == State.PAUSED:
		hud.hide_screen()
		_set_state(_resume_state)

func toggle_sound() -> void:
	SaveData.sound_enabled = not SaveData.sound_enabled
	SaveData.save()
	hud.set_sound(SaveData.sound_enabled)
	world.decorations.sync_sound()
	Audio.play_cue("ui")

func _on_primary() -> void:
	Audio.play_cue("ui")
	if state == State.PAUSED:
		toggle_pause()
	elif state == State.LEVEL_COMPLETE and level_index + 1 < CAMPAIGN.levels.size():
		select_level(level_index + 1)
	elif state == State.MENU:
		select_level(level_index)
	else:
		start_run()

func _on_secondary() -> void:
	if state == State.PAUSED:
		start_run()
	else:
		show_menu()

func _request_restart() -> void:
	if state != State.MENU:
		SaveData.record_level_score(world.config.level_id, score)
		start_run()

func _on_blocked() -> void:
	if world.player.cell.y == world.config.goal_row - 1:
		hud.show_tip("Line up with an empty numbered bay.", 1.8)

func _update_hud() -> void:
	world.player.set_shield_visual(powers.active.has("shield"))
	hud.update_progression(run_coins, powers.caption())
	hud.update_status(score, time_left, lives, destinations_reached, 1, world.config.time_limit)

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if state == State.PLAYING or state == State.RESPAWNING:
			toggle_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		toggle_pause()

func select_level(index: int) -> void:
	if not SaveData.is_unlocked(index, CAMPAIGN):
		return
	var next: LevelConfig = CAMPAIGN.levels[index] as LevelConfig
	var errors := next.playability_errors()
	if not errors.is_empty():
		hud.show_tip("Cannot start layout: " + "; ".join(errors), 6.0)
		return
	_set_state(State.MENU)
	level_index = index
	if not world.configure(next):
		hud.show_tip(world.configuration_error, 6.0)
		return
	hud.set_level(world.config, index + 1 < CAMPAIGN.levels.size())
	start_run()

func _collect_reward(cell: Vector2i) -> void:
	var pickup := world.rewards.take(cell)
	if pickup == null:
		return
	if pickup.kind == "coin":
		var amount := powers.multiplier()*pickup.coin_value*coin_multiplier()
		run_coins += amount
		SaveData.add_coins(amount)
		Audio.play_cue("coin")
	else:
		powers.activate(pickup.power)
		world.set_traffic_scale(powers.traffic_scale())
		hud.show_tip("%s active for %ds" % [pickup.power.display_name, int(pickup.power.duration)])
		Audio.play_cue("ui")
	if SaveData.last_save_error != OK:
		hud.show_tip("Progress could not be saved. Check free storage.", 5.0)

func _choose_character(id: String) -> void:
	if state != State.MENU:
		return
	var success := SaveData.choose_character(id)
	world.player.apply_skin(SaveData.selected_character)
	hud.show_characters("Selected! Cosmetics never change gameplay." if success else "Could not unlock/select. Check coins and free storage.")

func _record_death(_player: CrossingPlayer) -> void:pass
func coin_multiplier() -> int:return 1
