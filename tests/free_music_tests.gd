extends Node
## Real soundtrack transport tests; not subjective listening acceptance.
var passed := 0
var failed := 0
var game: ModeGame
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error(label)
func fixture() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(22050 * 2 * 2) # Two seconds of silence; not a replacement score.
	stream.data = bytes
	return stream
func _ready() -> void: run.call_deferred()
func run() -> void:
	Profiles.storage_path = "user://playful_slots_profiles.cfg"
	Profiles.load_profiles()
	if "verify_restart" in OS.get_cmdline_user_args():
		check(not RunRecords.option("music"), "music preference persists in fresh process")
		check(SaveData.sound_enabled, "sound preference remains independent")
		finish(); return
	game = load("res://scenes/main.tscn").instantiate(); add_child(game)
	if Profiles.active_key.is_empty(): Account.create("PlayfulSlotsQA")
	SaveData.coins = 5000
	for map: MapConfig in game.CAMPAIGN.levels: Profiles.purchase(map)
	RunRecords.set_option("music", true); SaveData.sound_enabled = true
	Audio.set_process(false)
	var player_id := Audio.music.get_instance_id()
	check(Audio.music_catalog.missing_slots().is_empty(), "eight real audio assets assigned")
	var slot_names := ["village", "city", "river", "night"]
	for cycle in range(3):
		for i in range(4):
			var map: MapConfig = game.CAMPAIGN.levels[i]
			game.select_level(i)
			Audio._process(.35); Audio._process(.35)
			check(Audio.current_track == Audio.music_catalog.get(slot_names[i]), "map resolves to its replacement slot")
			check(Audio.music.playing and is_equal_approx(Audio.music.volume_db, 0), "normal playback gain reached")
			if cycle == 0:
				Audio.music.seek(Audio.music.stream.get_length() - .15)
				await get_tree().create_timer(.4).timeout
				check(Audio.music.playing and Audio.music.get_playback_position() < 1, "actual normal Ogg wraps")
			var before := Audio.current_track
			Audio.music.seek(.5)
			Audio.request_music(map.environment.music_track); Audio._process(.01)
			check(Audio.music.get_playback_position() >= .49, "same map request does not restart")
			game.show_menu()
			Audio._process(.1)
			check(Audio.current_track == before, "menu does not create a new music stream")
	for i in range(4):
		var map: MapConfig = game.CAMPAIGN.levels[i]
		game.select_challenge(i, ChallengeCatalog.for_map(map.level_id)[0].challenge_id)
		Audio._process(.35)
		check(Audio.current_track == Audio.music_catalog.get(slot_names[i]+"_challenge") and Audio.music.volume_db <= -59.9, "challenge swaps at silence")
		Audio._process(.35)
		check(is_equal_approx(Audio.music.volume_db, 0), "challenge has no loudness boost")
		var loop := Audio.music.stream as AudioStreamOggVorbis
		check(loop != null and loop.loop and loop.loop_offset == 0, "Ogg full length loop")
		Audio.music.seek(loop.get_length() - .15)
		await get_tree().create_timer(.4).timeout
		check(Audio.music.playing and Audio.music.get_playback_position() < 1, "actual challenge Ogg wraps")
	check(Audio.music.get_instance_id() == player_id and Audio.get_child_count() == 5, "one music player and four unchanged SFX voices")
	check(Audio.loop_cache.size() <= 8, "bounded replacement cache")
	game._action("settings", "")
	var overlay_id := game.ui.overlay.get_instance_id()
	var overlay_alpha := game.ui.overlay.modulate.a
	game._action("music", ""); Audio._process(.01)
	check(Audio.music.stream_paused and not RunRecords.option("music"), "music off")
	check(game.ui.overlay.get_instance_id() == overlay_id and game.ui.overlay.modulate.a == overlay_alpha, "toggle does not rebuild or fade UI")
	Audio.play_cue("coin")
	check(Audio.voices.any(func(v): return v.playing), "SFX on with music off")
	Audio.request_music(game.CAMPAIGN.levels[0].environment.music_track); Audio._process(.01)
	check(Audio.music.stream_paused and Audio.music.volume_db <= -59.9, "muted map swap remains silent")
	game._action("music", ""); SaveData.sound_enabled = false; Audio._process(.35)
	check(not Audio.music.stream_paused and not Audio.voices.any(func(v): return v.playing), "music on with SFX off")
	SaveData.sound_enabled = true
	Audio.duck_left = 0; Audio.duck_gain_db = 0
	Audio.play_cue("ui"); check(Audio.duck_left == 0, "UI clicks do not pump music")
	Audio.play_cue("rail_warning"); Audio._process(.05)
	check(is_equal_approx(Audio.duck_gain_db, -5), "warning ducks only music")
	Audio._process(2); check(Audio.duck_gain_db == 0, "duck recovery")
	Audio.request_music(null); Audio._process(.35)
	check(Audio.current_track == null and not Audio.music.playing, "empty request fades to silence")
	var ogg_path := OS.get_environment("POCKET_MUSIC_TEST_OGG")
	if not ogg_path.is_empty():
		var ogg := AudioStreamOggVorbis.load_from_file(ogg_path)
		Audio.music_catalog.village = ogg
		Audio.request_music(game.CAMPAIGN.levels[0].environment.music_track)
		Audio._process(.35)
		var playing_ogg := Audio.music.stream as AudioStreamOggVorbis
		check(playing_ogg != null and playing_ogg.loop and playing_ogg.loop_offset == 0, "Ogg loop configured")
		Audio.music.seek(.9)
		await get_tree().create_timer(.35).timeout
		check(Audio.music.playing and Audio.music.get_playback_position() < .8, "Ogg wraps without restarting player")
	RunRecords.set_option("music", false); Profiles.save_active()
	game.queue_free(); await get_tree().process_frame
	finish()
func finish() -> void:
	print("FREE MUSIC REVIEW: ", passed, " passed, ", failed, " failed")
	get_tree().quit.call_deferred(failed)
