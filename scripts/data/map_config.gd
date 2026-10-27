class_name MapConfig
extends LevelConfig
## Map progression is separate from the section/traffic compiler.
@export_range(0,10000) var unlock_cost: int = 0
@export_range(0,100) var completion_coins: int = 20
@export var preview_art: Texture2D
@export var dog: DogConfig
@export var ambience: AudioStream
@export var signature: String=""
@export var atmosphere_label := "Day"
@export_range(1,18) var required_crossings: int = 5
@export_group("Destination presentation")
## In destination_columns order; null falls back to Environment.destination_art.
@export var destination_art_overrides: Array[Texture2D] = []
@export var destination_tints: Array[Color] = []
@export var occupied_color := Color("245b54")
@export var occupied_border := Color("aeeaa7")
@export var show_arrived_character := true
func map_errors() -> PackedStringArray:
	var errors:=playability_errors()
	var layout:=compile_layout()
	if required_crossings!=5 or layout.config==null or layout.config.goal_columns.size()!=required_crossings:
		errors.append("Campaign maps require five distinct destination choices")
	if unlock_cost<0 or completion_coins<0 or completion_coins>100:errors.append("Invalid map economy")
	if preview_art==null:errors.append("Missing map preview")
	return errors
