extends Node
var passed := 0
var failed := 0
var game: ModeGame
var visual := false
var frames_checked := 0
var deaths := 0
var splashes := 0
var cases: Dictionary = {}
var captured: Dictionary = {}
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error("FAIL " + label)
func _ready() -> void: run.call_deferred()
func panel_check() -> void:
	check(is_instance_valid(game.ui.overlay) and game.ui.overlay.modulate.a == 1.0,"panel opaque immediately: " + game.ui.page)
	check(not game._transition_busy(),"panel switch has no world fade")
	if visual:
		for frame in range(3):
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			var covered := true
			for y in [.15,.3,.5,.7,.9]:
				var pixel := image.get_pixel(int(image.get_width()*.015),int(image.get_height()*y))
				if Vector3(pixel.r,pixel.g,pixel.b).distance_to(Vector3(22,46,56)/255.0) > .04: covered=false
			check(covered,"rendered menu margin never exposes game")
			frames_checked += 1
			if not captured.has(game.ui.page):
				image.save_png("res://docs/ui_water/"+game.ui.page+".png");captured[game.ui.page]=true
	else: await get_tree().process_frame
func run() -> void:
	visual = "visual" in OS.get_cmdline_user_args()
	if visual:DirAccess.make_dir_recursive_absolute("res://docs/ui_water")
	Profiles.storage_path="user://ui_water_tests.cfg"
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Water_UI_QA");SaveData.coins=5000
	for map: MapConfig in game.CAMPAIGN.levels: Profiles.purchase(map)
	Audio.cue_played.connect(func(cue: String):
		if cue=="water_entry":splashes+=1)
	for repeat in range(20):
		for action in ["local","friends","settings","challenges"]:
			game._action(action,"");await panel_check()
			if action=="settings":
				var panel:=game.ui.overlay
				var entry:=game.ui.entry
				entry.text="Unsaved_Name";entry.caret_column=4
				for option in ["music","sound","ambience","vibration"]:
					var button: Button=game.ui.setting_buttons[option]
					for toggle in range(3):
						button.pressed.emit();await panel_check()
						check(game.ui.overlay==panel and game.ui.entry==entry,"toggle retains panel and input")
						check(entry.text=="Unsaved_Name" and entry.caret_column==4,"toggle retains edit/caret")
						check(button.is_inside_tree(),"toggle retains button/focus target")
				var sound:=SaveData.sound_enabled
				var music:=RunRecords.option("music")
				Profiles.save_active();Profiles.load_profiles()
				check(sound==SaveData.sound_enabled and music==RunRecords.option("music"),"independent settings saved")
			if action=="challenges":
				for map: MapConfig in game.CAMPAIGN.levels:
					game._action("challenge_map",map.level_id);await panel_check()
			game.navigation.last_back=-1000;game.navigation.back();await panel_check()
		game._action("local","");game.ui.characters_pressed.emit();await panel_check()
		game.navigation.last_back=-1000;game.navigation.back();await panel_check()
		game._action("friends","");game._action("host","");await panel_check()
		game.ui.race_results([],true);await panel_check()
		game._action("lobby","");await panel_check()
		game.navigation.last_back=-1000;game.navigation.back();game.navigation.accept();await panel_check()
		game._action("local","")
		game.ui.show_map_result(false,1,0,0,0,false);await panel_check()
		game.show_menu();await panel_check()
		if repeat%5==4:print("NAVIGATION CYCLES: ",repeat+1)
	SaveData.sound_enabled=true;RunRecords.set_option("music",false)
	for index in range(game.CAMPAIGN.levels.size()):
		var map: MapConfig=game.CAMPAIGN.levels[index]
		var variants: Array[String]=[""]
		for challenge in ChallengeCatalog.for_map(map.level_id): variants.append(challenge.challenge_id)
		for variant: String in variants:
			game.leave_friends()
			if variant.is_empty():game.select_level(index)
			else:game.select_challenge(index,variant)
			game.set_physics_process(false);game.world.set_active(false)
			if game.world.water_lanes.is_empty():continue
			var before:=deaths
			for lane in game.world.water_lanes:
				for n in range(24):exercise_water(lane,n%8,true)
			cases[map.level_id+":"+variant]=deaths-before
			print("WATER CONFIG ",map.level_id,":",variant," deaths=",deaths-before)
	check(deaths==splashes,"every sound-on death has one splash")
	check(deaths>=20,"at least twenty valid water deaths")
	game.select_level(2);game.set_physics_process(false);game.world.set_active(false)
	var splash_count:=splashes
	RunRecords.set_option("music",true);SaveData.sound_enabled=false;Audio._process(.1)
	for lane in game.world.water_lanes:exercise_water(lane,0,false)
	check(splashes==splash_count,"sound OFF intentionally silent")
	check(not Audio.music.stream_paused,"music ON independent")
	SaveData.sound_enabled=true;RunRecords.set_option("music",false);Audio._process(.1)
	check(Audio.music.stream_paused,"music OFF independent")
	Audio.play_cue("water_entry")
	var voice:=Audio.voices[3]
	for i in range(40):Audio.play_cue("hop");Audio.play_cue("ui")
	check(voice.stream==Audio.streams.water_entry and voice.playing,"splash survives same-frame voice pressure")
	game.world.player.reset_to_spawn();game.show_menu()
	check(voice.playing,"splash survives respawn/menu cleanup")
	check(Audio.get_child_count()==5,"still four SFX voices plus one music")
	AudioServer.add_bus()
	var bus := AudioServer.bus_count-1
	AudioServer.set_bus_name(bus,"WaterTestCapture")
	var capture := AudioEffectCapture.new()
	AudioServer.add_bus_effect(bus,capture)
	voice.bus="WaterTestCapture"
	Audio.play_cue("water_entry")
	for i in range(40):Audio.play_cue("hop")
	await get_tree().create_timer(.2).timeout
	var samples := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for sample in samples:peak=maxf(peak,absf(sample.x))
	check(samples.size()>0 and peak>.001,"water voice produces mixed audio after competing cues")
	print("WATER MIX CAPTURE frames=",samples.size()," peak=",peak)
	voice.bus="Master";AudioServer.remove_bus(bus)
	var heard:=splashes
	game.session.match_id="ui_water_epoch"
	game.session._owner_hurt("ui_water_epoch",1,"water",Vector2.ZERO)
	game.session._owner_hurt("ui_water_epoch",1,"water",Vector2.ZERO)
	game.session._owner_hurt("wrong_epoch",2,"water",Vector2.ZERO)
	check(splashes==heard+1,"local reliable hurt exactly once")
	game.feed.push("Remote fell into the river",false)
	check(splashes==heard+1,"remote feed never plays full splash")
	game.queue_free();await get_tree().process_frame
	check(voice.playing,"autoload voice survives game node cleanup")
	for v in Audio.voices:v.stop();v.stream=null
	Audio.music.stop()
	await get_tree().create_timer(.3).timeout
	print("WATER STRESS: ",deaths," valid sound-on deaths; ",JSON.stringify(cases))
	print("RENDERED MENU FRAMES: ",frames_checked)
	print("UI WATER: ",passed," passed, ",failed," failed")
	get_tree().quit(failed)
func exercise_water(lane: WaterLane, kind: int, audible: bool) -> void:
	var actor:=game.world.player
	game.state=game.State.PLAYING;game.lives=100;game.powers.clear()
	actor.reset_to_spawn(0);actor.cell=Vector2i(8,lane.row);actor.position=game.world.config.cell_position(actor.cell)
	var support:=game.world.water_support
	for platform in lane.platforms:platform.position.x=-10000;platform.motion_x=0
	var deck:=lane.platforms[0]
	var old_length:=deck.length
	var before:=splashes
	var old_deaths:=game.run_stats.deaths
	match kind:
		0: support.check_landing()
		1,2,3:
			deck.length=[96.0,160.0,256.0][kind-1]
			deck.position.x=actor.position.x-deck.support_half_width()-2
			support.check_landing()
		4:
			deck.position.x=actor.position.x;deck.length=96
			check(support.check_landing(),"supported before hop")
			actor.request_step(Vector2i.RIGHT);actor._physics_process(actor.hop_duration+.01)
		5:
			deck.position.x=actor.position.x;support.check_landing()
			deck.position.x=-10000;support._physics_process(0)
		6,7:
			deck.position.x=actor.position.x;support.check_landing()
			var target: float=-deck.support_half_width()-1 if kind==6 else lane.width+deck.support_half_width()+1
			deck.motion_x=target-deck.position.x;deck.position.x=target
			support._physics_process(0)
	deck.length=old_length
	check(game.lives==99 and game.run_stats.deaths==old_deaths+1,"water loses one life")
	check(actor.contact_cause=="water" and game.state==game.State.RESPAWNING,"water cause and respawn state")
	check(splashes==before+(1 if audible else 0),"one splash per accepted water death")
	check(game.run_presentation.bursts.back().kind=="splash","water visual")
	game._on_water_hazard(actor)
	check(game.lives==99 and splashes==before+(1 if audible else 0),"duplicate water signal ignored")
	game._physics_process(game.world.config.hit_reset_seconds+.01)
	game.world.set_active(false)
	check(actor.visible and actor.cell==game.world.config.spawn_cell,"normal respawn")
	if audible:deaths+=1
