class_name MapGame
extends CrossingGame
## Campaign rules reuse the existing world, collision, controls and power-ups.
var elapsed_seconds:=0.0
var new_best_time:=false
var current_map: MapConfig
var map_hud: MapHUD
var challenge: ChallengeConfig
var run_stats:=MapRunStats.new()
var dog_encounter:=DogEncounter.new()
var dog_view: DogView
var run_presentation: RunPresentation
var record_token:=""
func record_category() -> String:return "local" if challenge==null else "challenge:"+challenge.challenge_id
func current_score() -> int:return LanMatchRules.score(destinations_reached,run_stats.coins,run_stats.deaths,maxf(0,current_map.time_limit-elapsed_seconds))
func _set_state(next: State) -> void:
	super._set_state(next)
	if next==State.MENU:
		if run_presentation!=null:run_presentation.clear()
		if dog_view!=null:dog_view.clear()
		dog_encounter.reset()

func _ready() -> void:
	CAMPAIGN=load("res://resources/maps/catalog.tres")
	current_map=CAMPAIGN.levels[0] as MapConfig
	map_hud=$HUD
	Profiles.load_profiles()
	map_hud.profile_create_requested.connect(_create_profile)
	map_hud.profile_selected.connect(_select_profile)
	map_hud.profile_screen_requested.connect(show_profiles)
	map_hud.map_purchase_requested.connect(_purchase)
	super._ready()
	run_presentation=RunPresentation.new();add_child(run_presentation);run_presentation.setup(self)
	dog_view=DogView.new();world.add_child(dog_view)
	show_profiles()
func show_profiles() -> void:
	if not Profiles.active_key.is_empty():Profiles.save_active()
	_set_state(State.MENU)
	powers.clear()
	world.water_support.clear_support()
	map_hud.show_profiles(Profiles.recovery_notice)
func _create_profile(username: String) -> void:
	var error:=Profiles.create_profile(username)
	if not error.is_empty():map_hud.show_profiles(error,username)
	else:show_menu()
func _select_profile(key: String) -> void:
	if Profiles.select_profile(key):show_menu()
	else:map_hud.show_profiles("Could not save player selection.")
func _purchase(index: int) -> void:
	if index<0 or index>=CAMPAIGN.levels.size():return
	var message:=Profiles.purchase(CAMPAIGN.levels[index] as MapConfig)
	map_hud.show_maps(CAMPAIGN,message if not message.is_empty() else "Map unlocked. Ready to cross!")
func show_menu() -> void:
	_set_state(State.MENU)
	powers.clear()
	world.water_support.clear_support()
	world.set_traffic_scale(1.0)
	if Profiles.active_key.is_empty():map_hud.show_profiles(Profiles.recovery_notice)
	else:
		map_hud.set_sound(SaveData.sound_enabled)
		if challenge!=null and map_hud.has_method("show_challenges"):map_hud.call("show_challenges",CAMPAIGN,current_map.level_id)
		else:map_hud.show_maps(CAMPAIGN)
func select_level(index: int) -> void:
	if index<0 or index>=CAMPAIGN.levels.size():return
	var map:=CAMPAIGN.levels[index] as MapConfig
	challenge=null
	if not Profiles.is_unlocked(map.level_id):return
	if not map.map_errors().is_empty():
		map_hud.show_maps(CAMPAIGN,"This map configuration needs attention.")
		return
	_set_state(State.MENU)
	if not world.configure(map):return
	current_map=map
	level_index=index
	hud.set_level(world.config,false)
	start_run()
func start_run(seed_value: int = 0) -> void:
	if Profiles.active_key.is_empty() or not Profiles.is_unlocked(current_map.level_id):return
	dog_encounter.reset();dog_view.clear()
	run_stats=MapRunStats.new()
	elapsed_seconds=0.0
	new_best_time=false
	super.start_run(seed_value)
	record_token=Crypto.new().generate_random_bytes(16).hex_encode()
	RunRecords.apply(record_category(),current_map.level_id,record_token)
	run_presentation.begin(current_map)
	var environment := current_map.environment
	if environment!=null:
		Audio.request_music(environment.challenge_music_track if challenge!=null and environment.challenge_music_track!=null else environment.music_track)
	map_hud.level_label.text=(challenge.title+" · " if challenge!=null else "")+current_map.display_name.to_upper()
	map_hud._default_tip="Bring five characters to five free destinations."
	map_hud.show_tip("Any free destination. Bring all five across.",3)
	for goal: DestinationZone in world.goals.values():goal.character_texture=null
func _physics_process(delta: float) -> void:
	if state!=State.PLAYING and state!=State.RESPAWNING:return
	var event:=dog_encounter.tick(delta,world.player,world.layout.section_at(world.player.cell.y),current_map.dog,state==State.PLAYING)
	dog_view.display(dog_encounter.snapshot(),delta)
	if event=="hit":world.player.contact_cause="dog";_on_collision(world.player)
	elapsed_seconds+=delta
	powers.tick(delta)
	world.set_traffic_scale(powers.traffic_scale())
	if state==State.RESPAWNING:
		_respawn_left-=delta
		if _respawn_left<=0:
			world.player.reset_to_spawn()
			_set_state(State.PLAYING)
	_update_hud()
func _on_step_completed(cell: Vector2i) -> void:
	if state!=State.PLAYING:return
	_collect_reward(cell)
	if cell.y==world.config.goal_row and world.claim_destination(cell.x):
		destinations_reached+=1
		run_presentation.success(world.player.position,destinations_reached==5)
		var goal: DestinationZone=world.goals[cell.x]
		goal.character_texture=world.player.art.texture if current_map.show_arrived_character else null
		goal.queue_redraw()
		Audio.play_cue("dock")
		if destinations_reached==current_map.required_crossings:finish_game(true,"")
		else:
			hud.show_tip("%d / 5 safe. Choose another free destination."%destinations_reached,2)
			_begin_respawn(world.config.destination_reset_seconds)
	_update_hud()
func finish_game(completed: bool, _detail: String) -> void:
	if state!=State.PLAYING and state!=State.RESPAWNING:return
	if completed and destinations_reached!=current_map.required_crossings:return
	_set_state(State.LEVEL_COMPLETE if completed else State.GAME_OVER)
	RunRecords.apply(record_category(),current_map.level_id,record_token,{"safe":destinations_reached,"coins":run_stats.coins,"deaths":run_stats.deaths,"score":current_score(),"time":elapsed_seconds})
	run_presentation.end_run()
	dog_encounter.reset();dog_view.clear()
	if challenge!=null:
		finish_challenge(completed)
		return
	var previous:=Profiles.best_time(current_map.level_id)
	new_best_time=false
	var notice:=""
	if completed:
		if Profiles.complete_map(current_map,maxf(0.01,elapsed_seconds)):
			new_best_time=previous==0 or elapsed_seconds<previous
			run_coins+=current_map.completion_coins
		else:notice="Result could not be saved. Check free storage."
	powers.clear()
	world.set_traffic_scale(1)
	map_hud.show_map_result(completed,elapsed_seconds,Profiles.best_time(current_map.level_id),run_coins,destinations_reached,new_best_time,notice)
	if completed:Audio.play_cue("complete")
	_update_hud()
func _update_hud() -> void:
	if map_hud==null:return
	world.player.set_shield_visual(powers.active.has("shield"))
	hud.update_progression(run_coins,powers.caption())
	map_hud.update_map_status(elapsed_seconds,run_coins,lives,destinations_reached)
	hud.best_label.text=("CHALLENGE" if challenge!=null else "LOCAL")+" · SCORE %d · COINS +%d"%[current_score(),run_coins]+(" · "+powers.caption() if not powers.caption().is_empty() else "")
func _on_primary() -> void:
	if state==State.PAUSED:toggle_pause()
	elif state!=State.MENU:start_run()
func _request_restart() -> void:
	if state!=State.MENU:start_run()

func clear_challenge() -> void:
	challenge=null
	if level_index>=0 and level_index<CAMPAIGN.levels.size():current_map=CAMPAIGN.levels[level_index] as MapConfig
func select_challenge(index: int, id: String) -> void:
	if index<0 or index>=CAMPAIGN.levels.size():return
	var base:=CAMPAIGN.levels[index] as MapConfig
	var definition:=ChallengeCatalog.find(id)
	if definition==null or not Profiles.is_unlocked(base.level_id):return
	var modified:=definition.apply(base)
	if modified==null or not modified.map_errors().is_empty():return
	_set_state(State.MENU)
	if not world.configure(modified):return
	challenge=definition;current_map=modified;level_index=index
	hud.set_level(world.config,false);start_run()
func coin_multiplier() -> int:return challenge.coin_multiplier() if challenge!=null else 1
func _collect_reward(cell: Vector2i) -> void:
	var pickup: RewardPickup=world.rewards.pickups.get(cell)
	var before:=run_coins
	super._collect_reward(cell)
	if pickup!=null and pickup.kind=="coin":
		run_presentation.emit_effect("coin",world.player.position)
		run_stats.coins+=run_coins-before
		if pickup.coin_value==3:run_stats.risk_coins+=1
func _record_death(player: CrossingPlayer) -> void:
	var cause:=player.contact_cause
	var kind:=LevelSectionConfig.Kind.WATER_SECTION if cause=="water" else (LevelSectionConfig.Kind.RAILWAY_SECTION if cause=="train" else LevelSectionConfig.Kind.ROAD_SECTION)
	run_stats.record_death(kind)
	run_presentation.death(kind,player.position)
func finish_challenge(completed: bool) -> void:
	var old:=MapDepthProgress.record(current_map.level_id,challenge.challenge_id)
	var result_score:=LanMatchRules.score(destinations_reached,run_stats.coins,run_stats.deaths,maxf(0,current_map.time_limit-elapsed_seconds))
	var saved:=MapDepthProgress.save_challenge(current_map,challenge,completed,maxf(0.01,elapsed_seconds),result_score)
	if saved and completed:run_coins+=current_map.completion_coins
	var record:=MapDepthProgress.record(current_map.level_id,challenge.challenge_id)
	powers.clear();world.set_traffic_scale(1)
	new_best_time=saved and completed and (old.time==0 or elapsed_seconds<old.time)
	var notice:="CHALLENGE · %s · SCORE %d · BEST %d"%[challenge.title,result_score,record.score] if saved else "Challenge could not be saved. Check storage."
	map_hud.show_map_result(completed,elapsed_seconds,record.time,run_coins,destinations_reached,new_best_time,notice)
	if completed:Audio.play_cue("complete")
	_update_hud()
