class_name MapDepthProgress
extends RefCounted
## Additive account fields, saved atomically through the existing profile writer.
static func valid(data: Dictionary) -> bool:
	var records: Variant=data.get("challenges",{})
	if not records is Dictionary:return false
	for key in records:
		if not key is String or key.length()>160 or not records[key] is Dictionary:return false
		var row: Dictionary=records[key]
		if not row.get("completed") is bool or not row.get("score") is int or row.score<0 or row.score>SaveData.LIMIT:return false
		var seconds: Variant=row.get("time",null)
		if not (seconds is int or seconds is float) or not is_finite(float(seconds)) or seconds<0:return false
	return true
static func key(map_id: String, id: String) -> String:return map_id+"/"+id
static func record(map_id: String, challenge_id: String) -> Dictionary:
	return Profiles.profiles.get(Profiles.active_key,{}).get("challenges",{}).get(key(map_id,challenge_id),{"completed":false,"time":0.0,"score":0}).duplicate(true)
static func save_challenge(map: MapConfig, challenge: ChallengeConfig, finished: bool, seconds: float, score: int) -> bool:
	if not Profiles.is_unlocked(map.level_id) or not is_finite(seconds) or seconds<=0 or score<0 or score>SaveData.LIMIT:return false
	var data: Dictionary=Profiles.profiles[Profiles.active_key]
	var old:=data.duplicate(true);var wallet:=SaveData.coins
	var rows: Dictionary=data.get("challenges",{}).duplicate(true)
	var previous:=record(map.level_id,challenge.challenge_id)
	previous.completed=previous.completed or finished
	previous.score=maxi(previous.score,score)
	if finished and (previous.time==0 or seconds<previous.time):previous.time=seconds
	rows[key(map.level_id,challenge.challenge_id)]=previous;data.challenges=rows
	if finished:SaveData.coins=mini(SaveData.LIMIT,wallet+map.completion_coins)
	if Profiles.save_active():return true
	Profiles.profiles[Profiles.active_key]=old;SaveData.coins=wallet;return false
