class_name RunRecords
extends RefCounted
## Additive profile fields. Bad optional statistics never invalidate the account.
const CAP:=1000000000
static func data() -> Dictionary:return Profiles.profiles.get(Profiles.active_key,{})
static func option(key: String, fallback: bool=true) -> bool:
	var options: Variant=data().get("presentation_options",{})
	return options.get(key,fallback) if options is Dictionary and options.get(key,fallback) is bool else fallback
static func set_option(key: String, value: bool) -> bool:
	var profile:=data();var old:=profile.duplicate(true)
	var options: Variant=profile.get("presentation_options",{})
	if not options is Dictionary:options={}
	options=options.duplicate();options[key]=value;profile.presentation_options=options
	if Profiles.save_active():return true
	Profiles.profiles[Profiles.active_key]=old;return false
static func defaults() -> Dictionary:
	return {"plays":0,"completions":0,"first":0,"second":0,"third":0,"score":0,"coins":0,"deaths":-1,"time":0.0}
static func read(category: String, map_id: String) -> Dictionary:
	var result:=defaults()
	var all: Variant=data().get("records_v1",{})
	var row: Variant=all.get(category+"/"+map_id,{}) if all is Dictionary else {}
	if row is Dictionary:
		for key in result:
			var value: Variant=row.get(key,result[key])
			if (value is int or value is float) and is_finite(float(value)) and value>=(-1 if key=="deaths" else 0) and value<=CAP:result[key]=float(value) if key=="time" else int(value)
	# Legacy best times remain visible without inventing historical play counts.
	var legacy:=Profiles.best_time(map_id) if category=="local" else (Account.best_time(map_id) if category=="friends" else 0.0)
	if category.begins_with("challenge:"):
		var previous:=MapDepthProgress.record(map_id,category.trim_prefix("challenge:"))
		legacy=previous.time;result.score=maxi(result.score,previous.score)
	if legacy>0 and (result.time==0 or legacy<result.time):result.time=legacy
	return result
static func receipts() -> Array:
	var raw: Variant=data().get("record_receipts",[])
	return raw.duplicate() if raw is Array else []
static func apply(category: String, map_id: String, token: String, result: Dictionary={}) -> bool:
	if map_id not in Profiles.MAP_IDS or token.is_empty() or token.length()>96 or data().is_empty():return false
	var finished:=not result.is_empty()
	if finished:
		for field in ["safe","coins","deaths","score","time"]:
			var value: Variant=result.get(field)
			if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>CAP:return false
		if result.safe>5:return false
	var started:=category+"/"+map_id+"/"+token+"/start"
	var ended:=category+"/"+map_id+"/"+token+"/end"
	var seen:=receipts()
	if seen.has(ended) or (not finished and seen.has(started)):return true
	var profile:=data();var old:=profile.duplicate(true);var row:=read(category,map_id)
	if not seen.has(started):row.plays=mini(CAP,row.plays+1);seen.append(started)
	if finished:
		seen.append(ended)
		row.score=maxi(row.score,int(result.score));row.coins=maxi(row.coins,int(result.coins))
		if int(result.safe)==5:
			row.completions=mini(CAP,row.completions+1)
			row.deaths=int(result.deaths) if row.deaths<0 else mini(row.deaths,int(result.deaths))
			if result.time>0 and (row.time==0 or result.time<row.time):row.time=float(result.time)
		if category=="friends":
			var rank:=int(result.get("rank",0))
			if rank in [1,2,3]:
				var key: String=["first","second","third"][rank-1];row[key]=mini(CAP,row[key]+1)
	while seen.size()>256:seen.pop_front()
	var all: Variant=profile.get("records_v1",{})
	if not all is Dictionary:all={}
	all=all.duplicate(true);all[category+"/"+map_id]=row;profile.records_v1=all;profile.record_receipts=seen
	if Profiles.save_active():return true
	Profiles.profiles[Profiles.active_key]=old;return false
