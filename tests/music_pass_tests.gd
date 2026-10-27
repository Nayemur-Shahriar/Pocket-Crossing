extends Node
var passed := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error(label)
func _ready() -> void: run.call_deferred()
func run() -> void:
	Profiles.storage_path = "user://music_pass_profiles.cfg"
	Profiles.load_profiles()
	if Profiles.active_key.is_empty(): Profiles.create_profile("MusicPassQA")
	if "verify_restart" in OS.get_cmdline_user_args():
		check(not RunRecords.option("music"), "music OFF survives a new process")
		check(SaveData.sound_enabled, "SFX ON survives a new process")
		print("MUSIC RESTART: ",passed," passed, ",failed," failed")
		get_tree().quit(failed); return
	RunRecords.set_option("music", true)
	SaveData.sound_enabled = true
	Audio.set_process(false)
	var id := Audio.music.get_instance_id()
	check(Audio.music.bus == "Music", "dedicated Music bus")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), -16), "bus gain")
	for cycle in range(12):
		for map in ["village", "city", "river", "railway"]:
			var profile: EnvironmentProfile = load("res://resources/environments/"+map+".tres")
			for track in [profile.music_track, profile.challenge_music_track]:
				Audio.request_music(track)
				Audio._process(.35)
				check(Audio.current_track == track and Audio.music.volume_db <= -59.9, "swap only at silence")
				Audio._process(.35)
				check(is_equal_approx(Audio.music.volume_db, 0), "fade reaches nominal gain")
				var loop := Audio.music.stream as AudioStreamWAV
				check(loop.loop_mode == AudioStreamWAV.LOOP_FORWARD, "forward loop")
				check(loop.format == AudioStreamWAV.FORMAT_16_BITS, "lossless PCM import")
				check(absf(loop.loop_end - loop.get_length()*loop.mix_rate) < 1.1, "full length loop")
				Audio.music.seek(5.0)
				Audio.request_music(track); Audio._process(.1)
				check(Audio.music.get_playback_position() >= 4.9, "same track does not restart")
	check(Audio.music.get_instance_id() == id and Audio.get_child_count() == 5, "one music and four SFX voices after 96 swaps")
	check(Audio.loop_cache.size() <= 9, "bounded stream cache")
	for cue in ["ui", "hop", "coin"]:
		Audio.play_cue(cue); check(Audio.duck_left == 0, "routine cue does not duck")
	for cue in ["dog_bark", "rail_warning", "countdown", "go", "time_up", "impact_car", "water_entry", "complete"]:
		Audio.play_cue(cue); Audio._process(.05)
		check(is_equal_approx(Audio.duck_gain_db, -5), "critical cue ducks 5 dB")
		Audio._process(2)
		check(Audio.duck_gain_db == 0, "duck recovers")
	RunRecords.set_option("music", false); Audio._process(.01)
	check(Audio.music.stream_paused, "mute pauses")
	var position := Audio.music.get_playback_position()
	RunRecords.set_option("music", true); Audio._process(.35)
	check(Audio.music.get_playback_position() >= position - .1, "unmute resumes")
	RunRecords.set_option("music", false)
	Audio.request_music(load("res://assets/audio/city_steps.wav")); Audio._process(.01)
	check(Audio.music.stream_paused and Audio.music.volume_db <= -59.9, "map change while muted remains silent")
	Audio.play_cue("coin")
	check(Audio.voices.any(func(v): return v.playing), "SFX on while music off")
	SaveData.sound_enabled = false; RunRecords.set_option("music", true); Audio._process(.35)
	check(not Audio.music.stream_paused and not Audio.voices.any(func(v): return v.playing), "music on while SFX off")
	SaveData.sound_enabled = true; RunRecords.set_option("music", false); Profiles.save_active()
	print("MUSIC PASS: ",passed," passed, ",failed," failed")
	get_tree().quit(failed)
