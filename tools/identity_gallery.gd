extends Node2D
## Developer art inspection only. Reuses actual actors; no gameplay/save writes.
const THEME_IDS := ["day","evening","night","rain","snow","fog"]
const VEHICLE_IDS := ["cng","rickshaw","local_bus","small_car","microbus","pickup","delivery_van","medium_truck","large_truck"]
const BOAT_IDS := ["wooden_boat","passenger_boat","fishing_boat","engine_boat","ferry"]
const PROP_IDS := ["banana","palm","bamboo","leafy_tree","bush","reeds","flowers","crop_patch","dirt_patch","grass_patch","bamboo_fence","fence","utility_pole","lamp","bench","road_sign","railway_sign","signal_box","market_stall","tea_stall","rural_house","urban_facade","bridge_rail","ghat_steps","finish_gate"]
var theme: LevelThemeConfig
var content: Node2D
var theme_picker: OptionButton
var page_picker: OptionButton
var page := 0
func _ready() -> void:
	content = Node2D.new()
	add_child(content)
	theme_picker = OptionButton.new()
	theme_picker.position = Vector2(785,28)
	theme_picker.size = Vector2(210,50)
	for id in THEME_IDS: theme_picker.add_item(id.capitalize())
	add_child(theme_picker)
	theme_picker.item_selected.connect(func(index: int) -> void: show_page(page,index))
	page_picker = OptionButton.new()
	page_picker.position = Vector2(1010,28)
	page_picker.size = Vector2(240,50)
	for title in ["Road vehicles","Train / boats","Environment props"]: page_picker.add_item(title)
	add_child(page_picker)
	page_picker.item_selected.connect(func(index: int) -> void: show_page(index,theme_picker.selected))
	show_page(0,0)
func caption(text: String, at: Vector2, width: float = 360, font: int = 20) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = Vector2(width,30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",font)
	label.add_theme_color_override("font_color",Color("eee5cb"))
	content.add_child(label)
func show_page(index: int, theme_index: int) -> void:
	page = index
	page_picker.select(index)
	theme_picker.select(theme_index)
	theme = load("res://resources/themes/"+THEME_IDS[theme_index]+".tres")
	for node in content.get_children():
		content.remove_child(node)
		node.queue_free()
	caption("POCKET CROSSING / ORIGINAL ART",Vector2(30,38),680,27)
	if page == 0:
		for i in range(VEHICLE_IDS.size()):
			var at := Vector2(220+(i%3)*420,190+(i/3)*174)
			var actor: TrafficVehicle = load("res://scenes/actors/vehicle.tscn").instantiate()
			actor.vehicle_type = VEHICLE_IDS[i]
			actor.direction = 1 if i%2==0 else -1
			actor.position = at
			content.add_child(actor)
			actor.set_physics_process(false)
			actor.apply_theme(theme)
			caption(actor.visual.display_name,at+Vector2(-180,47))
	elif page == 1:
		for i in range(2):
			var actor: RailwayTrain = load("res://scenes/railway/train.tscn").instantiate()
			content.add_child(actor)
			actor.configure(440,1 if i==0 else -1,load("res://resources/railway/visuals/"+("riverline" if i==0 else "sunrise")+".tres"))
			actor.theme = theme
			actor.position = Vector2(325+i*630,188)
			actor.visible = true
			actor.queue_redraw()
			caption(actor.visual.display_name,actor.position+Vector2(-180,39))
		for i in range(BOAT_IDS.size()):
			var at := Vector2(220+(i%3)*420,378+(i/3)*190)
			var settings := WaterLaneConfig.new()
			settings.visual = load("res://resources/water/visuals/"+BOAT_IDS[i]+".tres")
			settings.platform_length = 288
			settings.direction = 1 if i%2==0 else -1
			var platform := FloatingPlatform.new()
			platform.setup(settings)
			platform.position = at
			content.add_child(platform)
			caption(settings.visual.display_name,at+Vector2(-180,42))
	else:
		for i in range(PROP_IDS.size()):
			var at := Vector2(136+(i%5)*252,160+(i/5)*109)
			var art := Sprite2D.new()
			art.texture = load("res://assets/environment/props/"+PROP_IDS[i]+".svg")
			art.position = at
			art.modulate = theme.surface(Color.WHITE).lerp(theme.atmosphere_color,theme.fog_strength*0.65)
			content.add_child(art)
			caption(PROP_IDS[i].replace("_"," ").capitalize(),at+Vector2(-118,35),236,16)
	queue_redraw()
func _draw() -> void:
	if theme == null: return
	draw_rect(Rect2(0,0,1280,720),Color("17343e"))
	if page == 0:
		for y in [140,314,488]:
			draw_rect(Rect2(0,y,1280,96),theme.surface(Color("45585d")))
			for x in range(20,1280,76): draw_rect(Rect2(x,y+92,32,2),theme.markings_color)
	elif page == 1:
		draw_rect(Rect2(0,146,1280,78),theme.surface(theme.railway_color))
		for y in [170,206]:draw_line(Vector2(0,y),Vector2(1280,y),theme.rail_color,3)
		for y in [332,522]:draw_rect(Rect2(0,y,1280,88),theme.water_color)
	else:
		draw_rect(Rect2(0,105,1280,615),theme.surface(Color("78957f")))
