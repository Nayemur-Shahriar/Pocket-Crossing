extends CrossingGame
## F6 runs the real game directly, with an isolated example catalog and profile.
@export var example: LevelConfig = preload("res://resources/examples/road_sections_demo.tres")
var _preview_starting := true

func _ready() -> void:
	# Set the profile before any game initialization or gameplay can write progress.
	SaveData.storage_path = "user://section_preview_profile.cfg"
	SaveData.load_profile()
	var catalog := LevelCatalog.new()
	catalog.levels = [example]
	CAMPAIGN = catalog
	super._ready()
	_preview_starting = false
	select_level(0)

func show_menu() -> void:
	# CrossingGame._ready() calls this virtually. Skip only its startup menu;
	# later explicit returns to the preview's one-level menu work normally.
	if not _preview_starting:
		super.show_menu()
