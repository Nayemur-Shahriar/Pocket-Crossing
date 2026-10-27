extends "res://tools/section_preview.gd"
## One layout and one running game; theme changes do not rebuild lanes or reset a run.
const PRESETS = [preload("res://resources/themes/day.tres"),preload("res://resources/themes/evening.tres"),preload("res://resources/themes/night.tres"),preload("res://resources/themes/rain.tres"),preload("res://resources/themes/snow.tres"),preload("res://resources/themes/fog.tres")]
@export var preview_theme: LevelThemeConfig = preload("res://resources/themes/day.tres")
var picker: OptionButton

func _ready() -> void:
	example = example.duplicate(false) as LevelConfig
	example.presentation = preview_theme
	super._ready()
	# This developer-only picker sits in the footer, outside movement/swipe space.
	picker = OptionButton.new()
	picker.position = Vector2(650,630)
	picker.size = Vector2(348,46)
	picker.add_theme_font_size_override("font_size",18)
	for theme: LevelThemeConfig in PRESETS:
		picker.add_item(theme.display_name)
	picker.item_selected.connect(select_theme)
	hud.root.add_child(picker)
	picker.select(maxi(0,PRESETS.find(preview_theme)))
	hud.message_label.size.x = 465

func select_theme(index: int) -> void:
	if index < 0 or index >= PRESETS.size(): return
	preview_theme = PRESETS[index]
	example.presentation = preview_theme
	world.apply_theme(preview_theme)
	hud.show_tip(preview_theme.display_name + " — same layout and gameplay.",3)

func _process(_delta: float) -> void:
	if is_instance_valid(picker):
		picker.visible = state == State.PLAYING
