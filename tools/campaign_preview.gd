extends CrossingGame
## Developer-only unlocked catalog. Never writes the normal campaign profile.
@export_range(1, 15) var starting_level: int = 1
func _ready() -> void:
	SaveData.storage_path = "user://campaign_preview_profile.cfg"
	SaveData.load_profile()
	for level in CAMPAIGN.levels:
		SaveData.completed_levels[level.level_id] = true
	super._ready()
	select_level(starting_level - 1)
