extends Node
## M14 source/resource and profile edge cases. Never touches normal campaign saves.
var passed := 0
var failed := 0
func _ready() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		push_error("FAIL "+label)
func visit(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".tres") or file.ends_with(".tscn"):
			check(ResourceLoader.load(path+"/"+file)!=null,"Resource load "+path+"/"+file)
	for dir in DirAccess.get_directories_at(path): visit(path+"/"+dir)
func clean() -> void:
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(SaveData.storage_path+suffix)
func run() -> void:
	SaveData.storage_path="user://m14_validation.cfg"
	clean()
	SaveData.load_profile()
	check(SaveData.coins==0 and SaveData.completed_levels.is_empty(),"Missing save defaults")
	visit("res://resources")
	visit("res://scenes")
	var catalog: LevelCatalog=load("res://resources/levels/campaign.tres")
	var ids: Dictionary={}
	for i in range(catalog.levels.size()):
		var level: LevelConfig=catalog.levels[i]
		var layout:=level.compile_layout()
		check(layout.runtime_errors().is_empty(),"Playable Level "+str(i+1))
		check(not ids.has(level.level_id) and level.level_number==i+1,"Unique ordered ID")
		ids[level.level_id]=true
		check(level.environment!=null and level.environment.is_valid(),"Environment valid")
		check(level.presentation!=null and level.presentation.validation_errors().is_empty(),"Theme valid")
		var hazards:=0
		for section in level.sections: hazards+=section.road_lanes.size()+section.railway_tracks.size()+section.water_lanes.size()
		check(hazards>=5,"Minimum five real hazards")
		check(SaveData.is_unlocked(i,catalog),"Sequential unlock")
		check(not SaveData.is_unlocked(i+1,catalog),"Cannot skip next locked level")
		SaveData.complete_level(level.level_id,1000+i,3)
		SaveData.load_profile()
		check(SaveData.level_scores[level.level_id]==1000+i and SaveData.level_stars[level.level_id]==3,"Best results persist")
		SaveData.complete_level(level.level_id,1,1)
		SaveData.load_profile()
		check(SaveData.level_scores[level.level_id]==1000+i and SaveData.level_stars[level.level_id]==3,"Worse replay preserves best")
	check(not SaveData.is_unlocked(15,catalog) and not SaveData.is_unlocked(-1,catalog),"Campaign bounds reject invalid next")
	# Sparse recovery must never relock a level that itself is completed.
	SaveData.completed_levels={catalog.levels[5].level_id:true}
	SaveData.save()
	SaveData.load_profile()
	check(SaveData.is_unlocked(5,catalog) and SaveData.is_unlocked(6,catalog) and not SaveData.is_unlocked(7,catalog),"Sparse completed profile stays playable without arbitrary unlock")
	# Old v2 schema uses the same stable keys and values; no migration/version bump.
	var legacy:=ConfigFile.new()
	legacy.set_value("profile","version",2)
	legacy.set_value("profile","coins",123)
	legacy.set_value("profile","best_score",9999)
	legacy.set_value("progress","completed",{catalog.levels[0].level_id:true})
	legacy.set_value("progress","scores",{catalog.levels[0].level_id:9999,"future_route":888})
	legacy.set_value("progress","stars",{catalog.levels[0].level_id:3,"future_route":2})
	legacy.set_value("characters","unlocked",{"pip":true,"mint":true,"coral":true,"violet":true})
	legacy.set_value("characters","selected","violet")
	legacy.set_value("settings","sound",false)
	legacy.set_value("settings","vibration",false)
	legacy.save(SaveData.storage_path)
	SaveData.load_profile()
	check(SaveData.coins==123 and SaveData.best_score==9999 and SaveData.selected_character=="violet","M13 schema wallet/best/skin retained")
	check(SaveData.level_scores.future_route==888 and SaveData.level_stars.future_route==2 and not SaveData.sound_enabled and not SaveData.vibration_enabled,"M13 arbitrary IDs and settings retained")
	SaveData.save()
	for round_index in range(50):
		var skin: Dictionary=CharacterCatalog.SKINS[round_index%4]
		check(SaveData.choose_character(skin.id),"Repeated owned-character selection")
		SaveData.load_profile()
		check(SaveData.selected_character==skin.id and SaveData.coins==123,"Selection persists without recharge")
	# A syntactically valid but empty/unrelated primary is recoverable from .bak.
	for content in ["","[unrelated]\nx=1\n"]:
		SaveData.coins=41
		SaveData.save()
		SaveData.coins=42
		SaveData.save()
		var file:=FileAccess.open(SaveData.storage_path,FileAccess.WRITE)
		file.store_string(content)
		file.close()
		SaveData.load_profile()
		check(SaveData.coins==41,"Empty/unrecognized primary recovers last-good backup")
		SaveData.save()
		var backup:=ConfigFile.new()
		backup.load(SaveData.storage_path+".bak")
		check(backup.get_value("profile","coins",0)==41,"Empty primary never overwrites good backup")
	# Wrong types/nonfinite values cannot reach gameplay or the wallet.
	var bad:=ConfigFile.new()
	bad.set_value("profile","coins",NAN)
	bad.set_value("progress","scores",{"bad":INF,"negative":-1,"array":[]})
	bad.set_value("characters","selected",{"id":"pip"})
	bad.save(SaveData.storage_path)
	SaveData.load_profile()
	check(SaveData.coins==0 and SaveData.level_scores.bad==0 and SaveData.selected_character=="pip","Nonfinite/wrong typed profile safely sanitized")
	# Failed purchases roll back transaction using existing save architecture.
	var path:=SaveData.storage_path
	SaveData.storage_path="user://missing_m14_directory/profile.cfg"
	SaveData.coins=100
	SaveData.unlocked_characters={"pip":true,"mint":true}
	SaveData.selected_character="pip"
	check(not SaveData.choose_character("coral") and SaveData.coins==100 and SaveData.selected_character=="pip" and not SaveData.unlocked_characters.has("coral"),"Failed write rolls back purchase")
	SaveData.storage_path=path
	# Invalid authoring is diagnosed before runtime; valid campaign data unchanged.
	for property in ["hop_seconds","difficulty_ramp_seconds","starting_speed_scale","final_speed_scale"]:
		for value in [0.0,-1.0,NAN,INF]:
			var level:=catalog.levels[0].duplicate(true) as LevelConfig
			level.set(property,value)
			check(not level.playability_errors().is_empty(),"Reject invalid "+property)
	for property in ["hop_height","spawn_protection","hit_reset_seconds","destination_reset_seconds"]:
		var level:=catalog.levels[0].duplicate(true) as LevelConfig
		level.set(property,NAN)
		check(not level.playability_errors().is_empty(),"Reject nonfinite "+property)
	for value in [0,4]:
		var level:=catalog.levels[0].duplicate(true) as LevelConfig
		level.starting_lives=value
		check(not level.playability_errors().is_empty(),"Reject unsupported starting lives")
	var wrong:=catalog.levels[0].duplicate(true) as LevelConfig
	wrong.grid_origin=Vector2(NAN,576)
	check(not wrong.playability_errors().is_empty(),"Reject nonfinite origin")
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/main.tscn","Production main scene")
	for action in ["move_up","move_down","move_left","move_right","pause_game","restart_game","toggle_sound"]:
		check(InputMap.has_action(action) and InputMap.action_get_events(action).size()>0,"Required mapped action: "+action)
	clean()
	print("QA VALIDATION RESULTS: %d passed, %d failed"%[passed,failed])
	get_tree().quit(1 if failed else 0)
