extends Resource
## Final soundtrack slots. Empty means awaiting supplied and auditioned music.
## Assign imported WAV/Ogg streams in resources/audio/playful_music.tres.
## These resource references also ensure supplied tracks are included in exports.
@export_group("Normal map scores")
@export var village: AudioStream
@export var city: AudioStream
@export var river: AudioStream
@export var night: AudioStream
@export_group("Challenge variations")
@export var village_challenge: AudioStream
@export var city_challenge: AudioStream
@export var river_challenge: AudioStream
@export var night_challenge: AudioStream

const LEGACY_SLOTS := {
	"morning_walk": "village",
	"village_breeze": "village",
	"city_steps": "city",
	"river_drift": "river",
	"night_rails": "night",
	"village_breeze_challenge": "village_challenge",
	"city_steps_challenge": "city_challenge",
	"river_drift_challenge": "river_challenge",
	"night_rails_challenge": "night_challenge",
}

func resolve(request: AudioStream) -> AudioStream:
	if request == null: return null
	var basename := request.resource_path.get_file().get_basename()
	var slot: String = LEGACY_SLOTS.get(basename, "")
	if slot.is_empty(): return null
	var selected := get(slot) as AudioStream
	# An approved normal score is a useful interim fallback for its own
	# missing challenge mix; never fall back to the rejected legacy scores.
	if selected == null and slot.ends_with("_challenge"):
		selected = get(slot.trim_suffix("_challenge")) as AudioStream
	if selected is AudioStreamWAV or selected is AudioStreamOggVorbis:
		return selected
	return null

func missing_slots() -> PackedStringArray:
	var missing := PackedStringArray()
	for slot in ["village", "city", "river", "night", "village_challenge", "city_challenge", "river_challenge", "night_challenge"]:
		if get(slot) == null: missing.append(slot)
	return missing
