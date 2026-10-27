extends Node
## Independent versioned database. Legacy profile.cfg is never overwritten.
const DEFAULT_MAP := "village_crossing"
const MAP_IDS := ["village_crossing","city_rush","river_delta","night_express"]
var storage_path := "user://map_profiles.cfg"
var profiles: Dictionary = {}
var active_key := ""
var migration_pending := false
var legacy_snapshot: Dictionary = {}
var last_error: Error = OK
var recovery_notice := ""
static func username_error(value: String) -> String:
	var name:=value.strip_edges()
	if name.length()<3:return "Enter at least 3 characters."
	if name.length()>16:return "Use at most 16 characters."
	for i in range(name.length()):
		var c:=name.unicode_at(i)
		if not (c>=65 and c<=90 or c>=97 and c<=122 or c>=48 and c<=57 or c==95):return "Use letters, numbers or underscores."
	return ""
func _snapshot() -> Dictionary:
	return {"coins":SaveData.coins,"characters":SaveData.unlocked_characters.duplicate(),"selected":SaveData.selected_character,"sound":SaveData.sound_enabled,"vibration":SaveData.vibration_enabled,"legacy":{"scores":SaveData.level_scores.duplicate(),"stars":SaveData.level_stars.duplicate(),"completed":SaveData.completed_levels.duplicate(),"best_score":SaveData.best_score}}
func load_profiles() -> void:
	SaveData.profile_writer=save_active
	profiles={}
	active_key=""
	last_error=OK
	recovery_notice=""
	var existed:=FileAccess.file_exists(storage_path) or FileAccess.file_exists(storage_path+".bak")
	migration_pending=not existed
	legacy_snapshot=_snapshot() if migration_pending else {}
	var file:=ConfigFile.new()
	if file.load(storage_path)!=OK or not _valid(file):
		file=ConfigFile.new()
		if file.load(storage_path+".bak")!=OK or not _valid(file):
			if existed:recovery_notice="Profile files could not be read. Originals were kept for recovery."
			return
		recovery_notice="Profiles recovered from backup."
	profiles=file.get_value("database","profiles").duplicate(true)
	active_key=file.get_value("database","active","")
	if not profiles.has(active_key):active_key=""
	migration_pending=false
	if not active_key.is_empty():_apply()
func _valid(file: ConfigFile) -> bool:
	if file.get_value("database","version",0)!=1:return false
	if not file.get_value("database","active","") is String:return false
	var entries: Variant=file.get_value("database","profiles",null)
	if not entries is Dictionary or entries.is_empty():return false
	for key in entries:
		if not key is String or not entries[key] is Dictionary:return false
		var data: Dictionary=entries[key]
		if not MapDepthProgress.valid(data):return false
		var name: Variant=data.get("username",null)
		if not name is String or not username_error(name).is_empty() or name!=name.strip_edges() or (not data.has("device_id") and name.to_lower()!=key):return false
		if data.has("device_id"):
			var identity: Variant=data.device_id
			if not identity is String or identity.length()!=32 or not identity.is_valid_hex_number():return false
		var receipts: Variant=data.get("lan_receipts",[])
		if not receipts is Array or receipts.size()>64:return false
		for receipt in receipts:
			if not receipt is String or receipt.length()!=32 or not receipt.is_valid_hex_number():return false
		var friends_times: Variant=data.get("friends_times",{})
		if not friends_times is Dictionary:return false
		for map_id in friends_times:
			var seconds: Variant=friends_times[map_id]
			if map_id not in MAP_IDS or not (seconds is float or seconds is int) or not is_finite(float(seconds)) or seconds<=0:return false
		var coins: Variant=data.get("coins",null)
		if not coins is int or coins<0 or coins>SaveData.LIMIT:return false
		if not data.get("maps") is Dictionary or not data.maps.get(DEFAULT_MAP,false):return false
		for id in data.maps:
			if id not in MAP_IDS or not data.maps[id] is bool or not data.maps[id]:return false
		if not data.get("characters") is Dictionary or not data.characters.get("pip",false):return false
		for id in data.characters:
			if not id is String or CharacterCatalog.find_skin(id).is_empty() or not data.characters[id] is bool or not data.characters[id]:return false
		if not data.get("selected") is String or not data.characters.get(data.selected,false):return false
		if not data.get("times") is Dictionary:return false
		for id in data.times:
			var time: Variant=data.times[id]
			if id not in MAP_IDS or not (time is float or time is int) or not is_finite(float(time)) or time<=0:return false
		if not data.get("sound") is bool or not data.get("vibration") is bool:return false
	return true
func create_profile(value: String) -> String:
	var error:=username_error(value)
	if not error.is_empty():return error
	var name:=value.strip_edges()
	var key:=name.to_lower()
	if profiles.has(key):return "Username already exists."
	if not active_key.is_empty() and not save_active():return "Could not save. Check free storage."
	var old_key:=active_key
	var data: Dictionary=legacy_snapshot.duplicate(true) if migration_pending else {"coins":0,"characters":{"pip":true,"mint":true},"selected":"pip","sound":true,"vibration":true,"legacy":{}}
	data.username=name
	data.maps={DEFAULT_MAP:true}
	data.times={}
	profiles[key]=data
	active_key=key
	if not _write():
		profiles.erase(key)
		active_key=old_key
		return "Could not save. Check free storage."
	migration_pending=false
	legacy_snapshot={}
	_apply()
	return ""
func select_profile(key: String) -> bool:
	key=key.strip_edges().to_lower()
	if not profiles.has(key):return false
	if not active_key.is_empty() and not save_active():return false
	var previous:=active_key
	active_key=key
	if not _write():
		active_key=previous
		return false
	_apply()
	return true
func _apply() -> void:
	var data: Dictionary=profiles[active_key]
	SaveData.coins=data.coins
	SaveData.unlocked_characters=data.characters.duplicate()
	SaveData.selected_character=data.selected
	SaveData.sound_enabled=data.sound
	SaveData.vibration_enabled=data.vibration
	SaveData.completed_levels={}
	SaveData.level_scores={}
	SaveData.level_stars={}
	SaveData.best_score=0
	SaveData.profile_writer=save_active
func save_active() -> bool:
	if not profiles.has(active_key):return false
	var old: Dictionary=profiles[active_key].duplicate(true)
	var data: Dictionary=profiles[active_key]
	data.coins=SaveData.coins
	data.characters=SaveData.unlocked_characters.duplicate()
	data.selected=SaveData.selected_character
	data.sound=SaveData.sound_enabled
	data.vibration=SaveData.vibration_enabled
	if _write():return true
	profiles[active_key]=old
	return false
func _write() -> bool:
	var data:=ConfigFile.new()
	data.set_value("database","version",1)
	data.set_value("database","active",active_key)
	data.set_value("database","profiles",profiles)
	if not _valid(data):
		last_error=ERR_INVALID_DATA
		SaveData.last_save_error=last_error
		return false
	last_error=data.save(storage_path+".tmp")
	if last_error==OK:
		var verification:=ConfigFile.new()
		last_error=verification.load(storage_path+".tmp")
		if last_error==OK and not _valid(verification):last_error=ERR_INVALID_DATA
	if last_error==OK:
		var previous:=ConfigFile.new()
		if previous.load(storage_path)==OK and _valid(previous):last_error=previous.save(storage_path+".bak")
		elif FileAccess.file_exists(storage_path) and not FileAccess.file_exists(storage_path+".unreadable"):
			last_error=DirAccess.copy_absolute(ProjectSettings.globalize_path(storage_path),ProjectSettings.globalize_path(storage_path+".unreadable"))
	if last_error==OK:last_error=DirAccess.rename_absolute(ProjectSettings.globalize_path(storage_path+".tmp"),ProjectSettings.globalize_path(storage_path))
	SaveData.last_save_error=last_error
	return last_error==OK
func is_unlocked(id: String) -> bool:
	return profiles.has(active_key) and profiles[active_key].maps.get(id,false)==true
func purchase(map: MapConfig) -> String:
	if not profiles.has(active_key) or map.level_id not in MAP_IDS:return "Choose a player first."
	if map.unlock_cost<0 or map.unlock_cost>SaveData.LIMIT:return "Invalid map price."
	if is_unlocked(map.level_id):return ""
	if SaveData.coins<map.unlock_cost:return "Need %d more coins."%(map.unlock_cost-SaveData.coins)
	var before:=SaveData.coins
	SaveData.coins-=map.unlock_cost
	profiles[active_key].maps[map.level_id]=true
	if save_active():return ""
	SaveData.coins=before
	profiles[active_key].maps.erase(map.level_id)
	return "Could not save purchase. Coins returned."
func best_time(id: String) -> float:
	return float(profiles[active_key].times.get(id,0.0)) if profiles.has(active_key) else 0.0
func complete_map(map: MapConfig, seconds: float) -> bool:
	if not is_unlocked(map.level_id) or not is_finite(seconds) or seconds<=0:return false
	var before: Dictionary=profiles[active_key].duplicate(true)
	var wallet:=SaveData.coins
	var previous:=best_time(map.level_id)
	if previous==0 or seconds<previous:profiles[active_key].times[map.level_id]=seconds
	SaveData.coins=mini(SaveData.LIMIT,SaveData.coins+map.completion_coins)
	if save_active():return true
	profiles[active_key]=before
	SaveData.coins=wallet
	return false
