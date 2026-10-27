extends Node
## Versioned local profile. Typed migration + temp-file replacement + last-good backup.
const PATH := "user://profile.cfg"
const LIMIT := 1000000000
var storage_path: String = PATH
var profile_writer: Callable
var best_score: int = 0
var completed_levels: Dictionary = {}
var level_scores: Dictionary = {}
var level_stars: Dictionary = {}
var coins: int = 0
var unlocked_characters: Dictionary = {"pip": true, "mint": true}
var selected_character: String = "pip"
var sound_enabled: bool = true
var vibration_enabled: bool = true
var last_save_error: Error = OK

func _ready() -> void:
	load_profile()

func number(value: Variant, fallback: int = 0, maximum: int = LIMIT) -> int:
	if value is int:
		return clampi(value, 0, maximum)
	if value is float and is_finite(value):
		return int(clampf(value, 0, maximum))
	return fallback

func clean_map(value: Variant, flags: bool = false, maximum: int = LIMIT) -> Dictionary:
	var result := {}
	if value is Dictionary:
		for key in value:
			if key is String and not key.is_empty() and key.length() <= 100:
				if flags:
					if value[key] is bool and value[key]:
						result[key] = true
				else:
					result[key] = number(value[key], 0, maximum)
	return result

func load_profile() -> void:
	last_save_error = OK
	best_score = 0
	coins = 0
	sound_enabled = true
	vibration_enabled = true
	completed_levels = {}
	level_scores = {}
	level_stars = {}
	unlocked_characters = {"pip": true, "mint": true}
	selected_character = "pip"
	var data := ConfigFile.new()
	if data.load(storage_path) != OK or not _has_profile_data(data):
		if data.load(storage_path + ".bak") != OK or not _has_profile_data(data):
			return
	completed_levels = clean_map(data.get_value("progress", "completed", {}), true)
	level_scores = clean_map(data.get_value("progress", "scores", {}))
	level_stars = clean_map(data.get_value("progress", "stars", {}), false, 3)
	best_score = number(data.get_value("profile", "best_score", 0))
	coins = number(data.get_value("profile", "coins", 0))
	var sound: Variant = data.get_value("settings", "sound", true)
	var vibration: Variant = data.get_value("settings", "vibration", true)
	sound_enabled = sound if sound is bool else true
	vibration_enabled = vibration if vibration is bool else true
	var unlocked := clean_map(data.get_value("characters", "unlocked", {}), true)
	for id in unlocked:
		if not CharacterCatalog.find_skin(id).is_empty():
			unlocked_characters[id] = true
	var selected: Variant = data.get_value("characters", "selected", "pip")
	if selected is String and unlocked_characters.get(selected, false):
		selected_character = selected

func _has_profile_data(data: ConfigFile) -> bool:
	# An empty/truncated file parses successfully; it must not replace a good backup.
	# Accept partial legacy profiles with any established key, without a schema reset.
	var known := {
		"profile": ["version", "best_score", "coins"],
		"progress": ["completed", "scores", "stars"],
		"characters": ["unlocked", "selected"],
		"settings": ["sound", "vibration"],
	}
	for section: String in known:
		for key: String in known[section]:
			if data.has_section_key(section, key):
				return true
	return false

func save() -> bool:
	if profile_writer.is_valid(): return profile_writer.call()
	var data := ConfigFile.new()
	data.set_value("profile", "version", 2)
	data.set_value("progress", "completed", completed_levels)
	data.set_value("progress", "scores", level_scores)
	data.set_value("progress", "stars", level_stars)
	data.set_value("profile", "best_score", best_score)
	data.set_value("profile", "coins", coins)
	data.set_value("characters", "unlocked", unlocked_characters)
	data.set_value("characters", "selected", selected_character)
	data.set_value("settings", "sound", sound_enabled)
	data.set_value("settings", "vibration", vibration_enabled)
	var target := ProjectSettings.globalize_path(storage_path)
	last_save_error = data.save(storage_path + ".tmp")
	if last_save_error == OK:
		var previous := ConfigFile.new()
		if previous.load(storage_path) == OK and _has_profile_data(previous):
			last_save_error = previous.save(storage_path + ".bak")
	if last_save_error == OK:
		last_save_error = DirAccess.rename_absolute(target + ".tmp", target)
	if last_save_error != OK:
		push_warning("Could not save local progress: " + error_string(last_save_error))
	return last_save_error == OK

func submit_score(value: int) -> bool:
	if value <= best_score:
		return false
	best_score = number(value)
	save()
	return true

func record_level_score(id: String, value: int) -> void:
	level_scores[id] = maxi(int(level_scores.get(id, 0)), number(value))
	best_score = maxi(best_score, number(value))
	save()

func is_unlocked(index: int, catalog: LevelCatalog) -> bool:
	if index < 0 or index >= catalog.levels.size():
		return false
	return index == 0 or completed_levels.get(catalog.levels[index].level_id, false) == true or completed_levels.get(catalog.levels[index - 1].level_id, false) == true

func complete_level(id: String, value: int, stars: int = 1) -> void:
	completed_levels[id] = true
	level_stars[id] = maxi(int(level_stars.get(id, 0)), clampi(stars, 1, 3))
	record_level_score(id, value)

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins = mini(LIMIT, coins + amount)
	save()

func choose_character(id: String) -> bool:
	var skin := CharacterCatalog.find_skin(id)
	if skin.is_empty():
		return false
	var old_coins := coins
	var old_selected := selected_character
	var old_unlocked := unlocked_characters.duplicate()
	if not unlocked_characters.get(id, false):
		if coins < int(skin.cost):
			return false
		coins -= int(skin.cost)
		unlocked_characters[id] = true
	selected_character = id
	if save():
		return true
	coins = old_coins
	selected_character = old_selected
	unlocked_characters = old_unlocked
	return false
