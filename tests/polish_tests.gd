extends Node
var passed := 0
var failed := 0
var calls := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error("FAIL " + label)
func _ready() -> void: run.call_deferred()
func run() -> void:
	Profiles.storage_path = "user://polish_test.cfg"
	var game: ModeGame = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	Account.create("Polish_Tester")
	SaveData.coins = 5000
	var textures := {}
	for map: MapConfig in game.CAMPAIGN.levels:
		check(map.preview_art.get_size() == Vector2(512,512), "512 preview " + map.level_id)
		textures[map.preview_art.resource_path] = true
		Profiles.purchase(map)
	check(textures.size() == 4, "four preview identities")
	for page in [func():game.ui.mode_menu(),func():game.show_menu(),func():game.ui.settings_screen(),func():game.ui.friends_menu(),func():game.ui.local_pause(),func():game.ui.manual_screen()]:
		page.call()
		for button in game.ui.overlay.find_children("*","Button",true,false):
			check(button.focus_mode == Control.FOCUS_ALL, "keyboard focus " + button.text)
			check(button.size.y >= 64, "touch target " + button.text)
			check(button.get_theme_font_size("font_size") == 20, "shared typography " + button.text)
			check(button.get_theme_stylebox("focus").border_width_left == 3, "visible focus")
	game.ui.set_process(false)
	var safe := Rect2(70,25,1140,660)
	game.ui.apply_control_safe_area(safe)
	check(safe.encloses(game.ui.root.get_global_rect()), "whole UI inside safe region")
	game.ui.set_process(true)
	var music_id := Audio.music.get_instance_id()
	RunRecords.set_option("music",false);SaveData.sound_enabled=true;Audio._process(3)
	check(Audio.music.stream_paused, "music independently off")
	Audio.play_cue("coin");check(Audio.voices.any(func(v):return v.playing), "SFX independently on")
	RunRecords.set_option("music",true);SaveData.sound_enabled=false;Audio._process(3)
	check(not Audio.music.stream_paused, "music independently on")
	Profiles.save_active();Profiles.load_profiles()
	check(RunRecords.option("music") and not SaveData.sound_enabled, "independent settings persist")
	check(Audio.music.get_instance_id()==music_id and Audio.get_child_count()==5, "bounded single music controller")
	check(Audio.CUE_DB.rail_warning > Audio.MUSIC_DB and Audio.CUE_DB.ui < Audio.CUE_DB.dog_bark, "audio hierarchy")
	check(AudioServer.get_bus_effect_count(0)==1, "master protection")
	for path in ["icon_512.png","icon_192.png","adaptive_foreground.png","adaptive_background.png","splash.png"]:
		check(load("res://assets/branding/"+path)!=null,"branding "+path)
	game.ui.navigate(func(): calls += 1)
	game.ui.navigate(func(): calls += 10)
	await get_tree().create_timer(.7).timeout
	check(calls==1 and not game.ui.scene_fade.busy, "one request and completed fade")
	game.ui.navigate(func(): calls += 10);game.ui.scene_fade.cancel()
	await get_tree().create_timer(.6).timeout
	check(calls==1 and not game.ui.scene_fade.veil.visible, "cancel before load")
	for i in range(30):game.ui.navigate(func():calls+=10);game.ui.scene_fade.cancel()
	check(calls==1 and not game.ui.scene_fade.is_processing(), "repeated cancellation bounded")
	game.ui.navigate(func():calls+=10);game.ui.start_race_ui()
	check(not game.ui.scene_fade.busy and not game.ui.scene_fade.veil.visible, "GO never blocked")
	game.queue_free();await get_tree().process_frame
	print("POLISH RESULTS: ",passed," passed, ",failed," failed")
	get_tree().quit(failed)
