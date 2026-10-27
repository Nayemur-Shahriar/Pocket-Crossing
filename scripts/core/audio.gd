extends Node
## Persistent single music voice and four reusable SFX voices.

const MUSIC_DB := -14.0 # Review mix; physical speaker balance still needs listening.
const DUCK_DB := -5.0
const SILENT_DB := -60.0
const FADE_SECONDS := 0.35
const DUCK_SECONDS := {"rail_warning": 0.65, "dog_bark": 0.55, "countdown": 0.3, "go": 0.4, "time_up": 0.7, "dog_catch": 0.55, "water_entry": 0.85, "hit": 0.55, "splash": 0.55, "complete": 0.7, "dock": 0.4}
const CUE_DB := {"ui": -22.0, "hop": -26.0, "coin": -16.0, "dock": -14.0, "complete": -14.0, "rail_warning": -11.0, "dog_bark": -11.0, "time_up": -11.0, "dog_catch": -13.0, "water_entry": -13.0, "countdown": -13.0, "go": -12.0}
const CUES := {
	"impact_rickshaw": "res://assets/audio/impact_rickshaw.wav",
	"impact_cng": "res://assets/audio/impact_cng.wav",
	"impact_car": "res://assets/audio/impact_car.wav",
	"impact_van": "res://assets/audio/impact_van.wav",
	"impact_bus": "res://assets/audio/impact_bus.wav",
	"impact_truck": "res://assets/audio/impact_truck.wav",
	"impact_train": "res://assets/audio/impact_train.wav",
	"water_entry": "res://assets/audio/water_entry.wav",
	"dog_bark": "res://assets/audio/dog_bark.wav",
	"dog_catch": "res://assets/audio/dog_catch.wav",

	"coin": "res://assets/audio/coin.wav",
	"splash": "res://assets/audio/splash.wav",
	"rail_warning": "res://assets/audio/rail_warning.wav",
	"hop": "res://assets/audio/hop.wav",
	"hit": "res://assets/audio/hit.wav",
	"dock": "res://assets/audio/dock.wav",
	"complete": "res://assets/audio/complete.wav",
	"ui": "res://assets/audio/ui.wav",
	"time_up": "res://assets/audio/time_up.wav",
	"countdown": "res://assets/audio/ui.wav",
	"go": "res://assets/audio/dock.wav",
}
var music_catalog: Resource = preload("res://resources/audio/playful_music.tres")
var music: AudioStreamPlayer
var duck_left:=0.0
var fade_gain := 0.0
var duck_gain_db := 0.0
var requested_track: AudioStream
var current_track: AudioStream
var loop_cache: Dictionary={}
signal cue_played(cue: String)
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var cursor: int = 0
var last_cue: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cue: String in CUES:
		streams[cue] = load(CUES[cue])
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -13.0
		# Reserve the fourth existing voice for water impacts. Short overlapping
		# tails survive a fast respawn without allocating another player.
		voice.max_polyphony = 4 if i == 3 else 1
		add_child(voice)
		voices.append(voice)

	var bus := AudioServer.get_bus_index("Music")
	if bus < 0:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "Music")
		AudioServer.set_bus_send(bus, "Master")
	AudioServer.set_bus_volume_db(bus, MUSIC_DB)
	music=AudioStreamPlayer.new();music.name="Music";music.bus="Music";music.volume_db=-60;music.max_polyphony=1
	add_child(music)
	request_music(load("res://assets/audio/morning_walk.wav"))
	_switch_music()
	if not music_catalog.missing_slots().is_empty():
		print("Pocket Crossing: final playful music slots awaiting assets: ", music_catalog.missing_slots())
func request_music(track: AudioStream) -> void:
	requested_track = music_catalog.resolve(track)
func _switch_music() -> void:
	current_track = requested_track
	music.stop()
	music.stream = null
	if current_track == null: return
	if not loop_cache.has(current_track):
		var stream := current_track.duplicate() as AudioStream
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
		elif stream is AudioStreamOggVorbis:
			stream.loop = true
			stream.loop_offset = 0.0
		loop_cache[current_track] = stream
	music.stream = loop_cache[current_track]
	music.play()

func _process(delta: float) -> void:
	duck_left = maxf(0.0, duck_left - delta)
	var enabled := RunRecords.option("music")
	# One player: fade completely out, swap once, then fade in. UI requests
	# for the same resource leave playback position untouched.
	if not enabled:
		fade_gain = 0.0
		music.volume_db = SILENT_DB
		music.stream_paused = true
		if requested_track != current_track:
			_switch_music()
			music.stream_paused = true
	else:
		music.stream_paused = false
		if current_track == null and requested_track != null:
			fade_gain = 0.0
			_switch_music()
		var switching := requested_track != current_track
		fade_gain = move_toward(fade_gain, 0.0 if switching else 1.0, delta / FADE_SECONDS)
		if switching and fade_gain <= 0.0:
			music.volume_db = SILENT_DB
			_switch_music()
		var duck_target := DUCK_DB if duck_left > 0.0 else 0.0
		duck_gain_db = move_toward(duck_gain_db, duck_target, delta * (100.0 if duck_left > 0.0 else 12.5))
		music.volume_db = maxf(SILENT_DB, linear_to_db(maxf(fade_gain, 0.001)) + duck_gain_db)
	if not SaveData.sound_enabled:
		for voice in voices: voice.stop()

func duck_music(seconds: float) -> void:
	duck_left = maxf(duck_left, seconds)

func play_cue(cue: String) -> void:
	if not SaveData.sound_enabled or not CUES.has(cue):
		return
	var now := Time.get_ticks_msec()
	var gap := 450 if cue=="rail_warning" else (50 if cue=="coin" else 0)
	if now-int(last_cue.get(cue,-10000))<gap:return
	last_cue[cue]=now
	if cue.begins_with("impact_"):
		duck_music(0.65)
	elif DUCK_SECONDS.has(cue):
		duck_music(float(DUCK_SECONDS[cue]))
	var voice: AudioStreamPlayer
	if cue == "water_entry":
		voice = voices[3]
	else:
		# Reuse idle general voices first. Never steal a water impact for a hop,
		# UI click, coin or railway warning (even within the same audio frame).
		for i in range(3):
			var index := (cursor + i) % 3
			if not voices[index].playing:
				cursor = index
				break
		voice = voices[cursor]
		cursor = (cursor + 1) % 3
	voice.volume_db = float(CUE_DB.get(cue,-14.0))
	if voice.stream != streams[cue]: voice.stream = streams[cue]
	voice.play()
	cue_played.emit(cue)

func _exit_tree() -> void:
	for voice in voices:
		voice.stop();voice.stream=null
	if is_instance_valid(music):music.stop();music.stream=null
	streams.clear()
	loop_cache.clear()
	current_track = null
	requested_track = null
