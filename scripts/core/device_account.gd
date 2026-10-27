extends Node
## One device identity; old profiles remain archived in the existing database.
func adopt_loaded() -> bool:
	if Profiles.profiles.is_empty():return false
	var chosen:=Profiles.active_key
	for key: String in Profiles.profiles:
		if Profiles.profiles[key].has("device_id"):chosen=key;break
	if chosen.is_empty():chosen=String(Profiles.profiles.keys()[0])
	Profiles.active_key=chosen
	var data: Dictionary=Profiles.profiles[chosen]
	if not data.has("device_id"):
		data.device_id=Crypto.new().generate_random_bytes(16).hex_encode()
		if not Profiles._write():data.erase("device_id");return false
	Profiles._apply()
	return true
func exists() -> bool:
	return Profiles.profiles.has(Profiles.active_key) and Profiles.profiles[Profiles.active_key].has("device_id")
func create(username: String) -> String:
	if not Profiles.profiles.is_empty():return "This device already has an account. Rename it in Settings."
	var error:=Profiles.create_profile(username)
	if not error.is_empty():return error
	return "" if adopt_loaded() else "Could not save account. Check storage."
func identity() -> Dictionary:
	if not exists():return {}
	var data: Dictionary=Profiles.profiles[Profiles.active_key]
	return {"id":data.device_id,"name":data.username,"skin":SaveData.selected_character}
func rename_account(value: String) -> String:
	var error:=Profiles.username_error(value)
	if not error.is_empty():return error
	if not exists():return "Create your account first."
	var before: Dictionary=Profiles.profiles[Profiles.active_key].duplicate(true)
	Profiles.profiles[Profiles.active_key].username=value.strip_edges()
	if Profiles.save_active():return ""
	Profiles.profiles[Profiles.active_key]=before
	return "Could not save rename."
func best_time(id: String) -> float:
	return float(Profiles.profiles[Profiles.active_key].get("friends_times",{}).get(id,0)) if exists() else 0.0
func award_match(receipt: String, map_id: String, coins: int, finish: float) -> bool:
	if not exists() or receipt.length()!=32 or not receipt.is_valid_hex_number() or map_id not in Profiles.MAP_IDS or coins<0 or coins>200 or not is_finite(finish) or finish<0:return false
	var data: Dictionary=Profiles.profiles[Profiles.active_key]
	var old:=data.duplicate(true)
	var receipts: Array=data.get("lan_receipts",[])
	if receipts.has(receipt):return true
	receipts.append(receipt)
	while receipts.size()>64:receipts.pop_front()
	data.lan_receipts=receipts
	var bests: Dictionary=data.get("friends_times",{})
	if finish>0 and (not bests.has(map_id) or finish<float(bests[map_id])):bests[map_id]=finish
	data.friends_times=bests
	var wallet:=SaveData.coins
	SaveData.coins=mini(SaveData.LIMIT,wallet+coins)
	if Profiles.save_active():return true
	Profiles.profiles[Profiles.active_key]=old
	SaveData.coins=wallet
	return false
