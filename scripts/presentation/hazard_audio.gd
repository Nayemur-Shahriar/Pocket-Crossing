class_name HazardAudio
extends RefCounted
## Called only for an accepted local life loss, never a remote feed message.
const CATEGORIES:={"rickshaw":"rickshaw","cng":"cng","car":"car","small_car":"car","pickup":"van","delivery_van":"van","microbus":"van","bus":"bus","local_bus":"bus","truck":"truck","medium_truck":"truck","large_truck":"truck","train":"train","water":"water","dog":"dog"}
static func category(cause: String) -> String:return CATEGORIES.get(cause,"car")
static func cue(cause: String) -> String:
	var kind:=category(cause)
	return "water_entry" if kind=="water" else ("dog_catch" if kind=="dog" else "impact_"+kind)
static func play(cause: String) -> void:Audio.play_cue(cue(cause))
