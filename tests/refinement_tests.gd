extends Node
var passed:=0
var failed:=0
var game: ModeGame
var heard: Array[String]=[]
func check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:run.call_deferred()
func stop() -> void:game.set_physics_process(false);game.world.set_active(false)
func text_in(node: Node) -> String:
	var result: String=str(node.get("text")) if node is Label or node is Button else ""
	for child in node.get_children():result+=" "+text_in(child)
	return result
func place_safe() -> int:
	var row:=0
	for section in game.world.layout.sections:
		if int(section.kind)==LevelSectionConfig.Kind.SAFE_SECTION:row=int(section.first_row);break
	var player:=game.world.player
	player.cell=Vector2i(8,row);player.position=game.world.config.cell_position(player.cell);player.moving=false;player.invulnerable_left=0
	return row
func run() -> void:
	Profiles.storage_path="user://refinement.cfg";SaveData.storage_path="user://refinement_legacy.cfg"
	for path in [Profiles.storage_path,SaveData.storage_path]:
		for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	check(Account.create("Refine_Tester").is_empty(),"account creation")
	SaveData.coins=2000
	for map: MapConfig in game.CAMPAIGN.levels:Profiles.purchase(map)
	check(game.CAMPAIGN.levels.size()==4,"four maps")
	for show_page in [func():game.ui.mode_menu(),func():game.ui.settings_screen(),func():game.show_menu(),func():game.ui.show_challenges(game.CAMPAIGN)]:
		show_page.call()
		var words:=text_in(game.ui.overlay).to_upper()
		check(not words.contains("GHOST") and not words.contains("MASTERY") and not words.contains("RECORDS"),"removed UI/navigation")
	check(not game.has_method("show_map_details") and game.get("ghost")==null,"removed runtime")
	var profile: Dictionary=Profiles.profiles[Profiles.active_key]
	profile.mastery={"bad":-1};profile.ghost="old";profile.presentation_options={"ghost":true}
	var wallet:=SaveData.coins;var identity: String=Account.identity().id
	check(Profiles.save_active(),"obsolete fields save safely")
	Profiles.load_profiles();check(SaveData.coins==wallet and Account.identity().id==identity and Profiles.recovery_notice.is_empty(),"obsolete fields ignored without data loss")
	check(not MapDepthProgress.new().has_method("award"),"no mastery reward API")
	Audio.cue_played.connect(func(cue: String):heard.append(cue))
	RunRecords.set_option("music",true);SaveData.sound_enabled=false;Audio._process(2)
	check(not Audio.music.stream_paused and Audio.music.volume_db>-60,"music independent of Sound off")
	heard.clear();Audio.play_cue("hop");check(heard.is_empty(),"SFX muted independently")
	RunRecords.set_option("music",false);SaveData.sound_enabled=true;Audio._process(2)
	check(Audio.music.stream_paused,"music off stops playback")
	Audio.play_cue("hop");check(heard==["hop"],"SFX works music off")
	Profiles.save_active();Profiles.load_profiles();check(not RunRecords.option("music") and SaveData.sound_enabled,"independent settings reload")
	var music_id:=Audio.music.get_instance_id()
	game.ui.mode_menu();game.ui.settings_screen();game.show_menu()
	check(Audio.music.get_instance_id()==music_id and Audio.get_child_count()==5,"one persistent music voice plus four effects")
	var loop:=Audio.music.stream as AudioStreamWAV
	check(loop.loop_mode==AudioStreamWAV.LOOP_FORWARD and loop.loop_end>0 and is_equal_approx(loop.get_length(),Audio.current_track.get_length()),"configured track loops its complete length")
	check(CharacterCatalog.SKINS.size()==6,"six characters")
	game.select_level(0);stop()
	var player:=game.world.player
	var hitbox: Shape2D=player.get_node("CollisionShape2D").shape
	var duration:=player.hop_duration
	for skin in CharacterCatalog.SKINS:
		check(load(skin.texture)!=null,"character art "+skin.id)
		check(SaveData.choose_character(skin.id) or SaveData.unlocked_characters.has(skin.id),"cosmetic unlock "+skin.id)
		SaveData.choose_character(skin.id);player.apply_skin(skin.id)
		check(player.get_node("CollisionShape2D").shape==hitbox and player.hop_duration==duration,"same collision and speed "+skin.id)
		Profiles.save_active();Profiles.load_profiles();check(SaveData.selected_character==skin.id,"selected skin persists "+skin.id)
	game.ui.show_characters();check(text_in(game.ui.overlay).contains("Arun") and text_in(game.ui.overlay).contains("Leela"),"selection includes older characters")
	game.select_level(0);stop();var row:=place_safe()
	var section:=game.world.layout.section_at(row);var settings:=game.current_map.dog
	check(settings!=null and settings.allows(section),"Village dry safe lane configured")
	for i in range(1,4):check(game.CAMPAIGN.levels[i].dog!=null,"existing per-map dog configuration preserved")
	check(not settings.allows({"kind":LevelSectionConfig.Kind.START_SECTION}) and not settings.allows({"kind":LevelSectionConfig.Kind.WATER_SECTION}),"no start or water camping dog")
	var dog:=DogEncounter.new();dog.tick(0,player,section,settings,true)
	check(dog.tick(2.9,player,section,settings,true).is_empty() and dog.phase=="idle","grace period")
	check(dog.tick(0.11,player,section,settings,true)=="warning","stationary triggers warning")
	check(dog.at.x<0 or dog.at.x>1280,"offscreen spawn")
	check(dog.tick(0.9,player,section,settings,true).is_empty() and dog.phase=="warning","full reaction window before entry")
	player.position.x+=64;dog.tick(0.05,player,section,settings,true)
	check(dog.phase=="idle","reaction cancels threat")
	for i in range(200):
		player.position.x+=1;dog.tick(0.016,player,section,settings,true)
	check(dog.phase=="idle","normal displacement avoids warning")
	place_safe();dog.reset();dog.tick(0,player,section,settings,true);dog.tick(3.01,player,section,settings,true);dog.tick(1.01,player,section,settings,true)
	check(dog.phase=="running","warning then entry")
	var hits:=0
	for i in range(300):
		if dog.tick(1.0/60,player,section,settings,true)=="hit":hits+=1;break
	check(hits==1 and dog.cooldown>0,"one swept dog catch then cooldown")
	check(dog.tick(1,player,section,settings,true).is_empty(),"no repeat catch")
	# Every real gameplay death takes the same guarded collision/respawn path.
	for cause in HazardAudio.CATEGORIES:
		game.start_run(42);stop();player.invulnerable_left=0;heard.clear();var lives:=game.lives
		if cause=="water":game._on_water_hazard(player)
		else:game._apply_contact(player,cause)
		game._apply_contact(player,cause)
		check(game.lives==lives-1 and game.run_stats.deaths==1,"one life per "+cause)
		check(heard==[HazardAudio.cue(cause)],"one correct SFX per "+cause)
		check(game.state==game.State.RESPAWNING,"same respawn "+cause)
	# Contact source carries an immutable cause through deferred damage dispatch.
	game.start_run(42);stop();player.invulnerable_left=0;heard.clear()
	for id in ["rickshaw","cng","small_car","delivery_van","local_bus","large_truck"]:
		var vehicle:=TrafficVehicle.new();vehicle.vehicle_type=id;vehicle._on_body_entered(player)
		check(player.contact_cause==id,"vehicle identifies contact "+id);vehicle.free()
	var train:=RailwayTrain.new();train.running=true;train._on_body_entered(player)
	check(player.contact_cause=="train","train identifies contact");train.free()
	player.contact_cause="rickshaw";game.world.collision.emit(player)
	player.contact_cause="train";game.world.collision.emit(player)
	await get_tree().process_frame
	check(game.lives==2 and heard==["impact_rickshaw"],"first queued impact retains its cause exactly once")
	game.start_run(42);stop();player.invulnerable_left=0;heard.clear()
	game.powers.activate(load("res://resources/powerups/shield.tres"));game._apply_contact(player,"dog")
	check(game.lives==3 and game.run_stats.deaths==0 and heard==["dock"],"shield absorbs dog without death sound")
	game.start_run(42);stop();place_safe()
	game._physics_process(0);game._physics_process(3.01)
	check(game.dog_encounter.phase=="warning" and game.dog_view.phase=="warning","runtime dog warning wired")
	var warning_left:=game.dog_encounter.warning_left;game.pause_local();game._physics_process(5)
	check(game.dog_encounter.warning_left==warning_left,"pause freezes dog")
	game.resume_local();stop();player.position.x+=64;game._physics_process(0.02)
	check(game.dog_encounter.phase=="idle","runtime movement escapes")
	game.start_run(42);stop();check(game.dog_encounter.stationary==0 and game.dog_view.phase=="idle","Retry resets dog")
	place_safe();heard.clear()
	for i in range(600):
		game._physics_process(1.0/60)
		if game.state==game.State.RESPAWNING:break
	check(game.lives==2 and game.run_stats.deaths==1 and heard==["dog_bark","dog_catch"],"Local stationary dog warning through accepted collision/respawn")
	game.start_run(42);stop()
	var before:=SaveData.coins;game.destinations_reached=5;game.elapsed_seconds=70;game.finish_game(true,"");game.finish_game(true,"")
	check(SaveData.coins==before+game.current_map.completion_coins,"completion only normal reward once")
	check(Profiles.best_time(game.current_map.level_id)==70,"Best Time remains")
	check(not text_in(game.ui.overlay).to_upper().contains("MASTERY"),"no result mastery")
	game.show_menu();check(game.dog_view.phase=="idle","menu clears dog")
	game.leave_friends();game.queue_free();await get_tree().process_frame
	Audio.music.stop()
	for voice in Audio.voices:voice.stop();voice.stream=null
	# Fixed-FPS tests run faster than wall time; allow the mixer to retire playbacks.
	var drain_until:=Time.get_ticks_msec()+250
	while Time.get_ticks_msec()<drain_until:await get_tree().process_frame
	print("REFINEMENT RESULTS: %d passed, %d failed"%[passed,failed]);get_tree().quit(failed)
