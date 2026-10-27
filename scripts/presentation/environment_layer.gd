class_name EnvironmentLayer
extends Node2D
## One cached draw list for the camera window, no prop nodes/colliders or global RNG.
const GATE := preload("res://assets/environment/props/finish_gate.svg")
const REEDS := preload("res://assets/environment/props/reeds.svg")
const CROSSBUCK := preload("res://assets/environment/props/railway_sign.svg")
var profile: EnvironmentProfile
var theme: LevelThemeConfig = LevelThemeConfig.new()
var layout: CompiledLevelLayout
var camera: LevelCamera
var kinds: Dictionary = {}
var rest: Dictionary = {}
var rows := Vector2i(-1,-1)
var prop_sites: Array[Dictionary] = []
var ambience: AudioStreamPlayer
var running := false
var in_menu := true
var rebuild_count := 0

func _ready() -> void:
	z_index = 1 # Behind haze, pickups, every hazard, signals and player.
	ambience = AudioStreamPlayer.new()
	ambience.max_polyphony = 1
	add_child(ambience)
	ambience.finished.connect(_on_ambience_finished)

func setup(compiled: CompiledLevelLayout, view: LevelCamera) -> void:
	layout = compiled
	camera = view
	profile = compiled.config.environment
	if profile!=null:Audio.request_music(profile.music_track)
	if profile != null and not profile.is_valid(): profile = null
	kinds.clear()
	rest.clear()
	for row in compiled.safe_rows: rest[row] = true
	for section in compiled.sections:
		for row in range(section.first_row, section.first_row + section.row_count):
			kinds[row] = section.kind
	ambience.stop()
	ambience.stream = profile.ambience if profile != null else null
	ambience.volume_db = profile.ambience_volume_db if profile != null else -26
	rows = Vector2i(-1,-1)
	refresh(true)

func set_theme(settings: LevelThemeConfig) -> void:
	theme = settings
	queue_redraw()

func set_running(active: bool, menu: bool) -> void:
	running = active
	in_menu = menu
	visible = not menu
	if menu:
		ambience.stop()
	else:
		ambience.stream_paused = not active
		if active and SaveData.sound_enabled and ambience.stream != null and not ambience.playing:
			ambience.play()

func sync_sound() -> void:
	if not SaveData.sound_enabled:
		ambience.stop()
	elif running and not in_menu and ambience.stream != null and not ambience.playing:
		ambience.play()

func _on_ambience_finished() -> void:
	sync_sound() # Optional stream loops only while live and unmuted.

func _process(_delta: float) -> void:
	refresh()

func refresh(force: bool = false) -> void:
	if camera == null or layout == null: return
	var next := camera.visible_rows()
	next.x = maxi(0,next.x-2)
	next.y = mini(layout.config.goal_row,next.y+2)
	if not force and next == rows: return
	rows = next
	prop_sites.clear()
	if profile != null:
		for row in range(rows.x,rows.y+1):
			# Rail signal shoulders are reserved. Never cover the warning signs.
			if kinds.get(row,-1) == LevelSectionConfig.Kind.RAILWAY_SECTION: continue
			for side in range(2):
				var value := absi(row * 7919 + side * 1013 + profile.profile_id.hash())
				var vegetation := side == 0 and not profile.vegetation.is_empty()
				var choices := profile.vegetation if vegetation else profile.props
				var density := profile.vegetation_density if vegetation else profile.prop_density
				var rest_index := layout.safe_rows.find(row)
				var guaranteed := rest_index in [0,1] and density > 0
				if choices.is_empty() or (not guaranteed and float(value % 100) / 100.0 >= density): continue
				# Only plant props on rest rows; hazard rows get small ground details instead.
				if not rest.has(row) and row != layout.config.goal_row: continue
				var y := layout.config.cell_position(Vector2i(0,row)).y
				prop_sites.append({"row":row,"side":side,"texture":choices[maxi(0,rest_index) % choices.size()],"rect":Rect2(4 if side==0 else 1220,y-28,56,56)})
		if rows.y == layout.config.goal_row:
			var y := layout.config.cell_position(Vector2i(0,layout.config.goal_row)).y
			var choices := profile.vegetation + profile.props
			if not choices.is_empty():
				for i in range(6):
					# Reserve facade space around every valid destination, not just the center.
					var near_finish := false
					for column in layout.config.goal_columns:
						if absf(130+i*192-layout.config.cell_position(Vector2i(column,layout.config.goal_row)).x)<98:
							near_finish=true
					if near_finish: continue
					prop_sites.append({"row":layout.config.goal_row,"side":i+2,"texture":choices[i%choices.size()],"rect":Rect2(100+i*192,y-82,60,48)})
	rebuild_count += 1
	queue_redraw()

func _draw() -> void:
	if profile == null or layout == null: return
	var config := layout.config
	var edge := theme.surface(profile.edge_color)
	for row in range(rows.x,rows.y+1):
		var y := config.cell_position(Vector2i(0,row)).y
		var kind: int = kinds.get(row,-1)
		if rest.has(row):
			_draw_rest(y, row)
		elif kind == LevelSectionConfig.Kind.ROAD_SECTION:
			# Edge/wear marks are ground paint, never collision or raised props.
			draw_line(Vector2(0,y+29),Vector2(1280,y+29),Color(edge,0.45),2)
			for x in range(160,1180,240):
				draw_line(Vector2(x,y+18),Vector2(x+52,y+18),Color(0.7,0.75,0.68,0.10),2)
			if profile.guard_rails:
				for x in [9,1246]:
					draw_rect(Rect2(x,y-20,25,5),theme.surface(Color("c9d1b6")))
					draw_rect(Rect2(x+4,y-15,4,14),edge)
		if row == config.spawn_cell.y:
			var at := config.cell_position(config.spawn_cell)
			draw_arc(at,27,0,TAU,32,theme.destination_border,2,true)
			draw_string(ThemeDB.fallback_font,Vector2(at.x+42,at.y+6),"START",HORIZONTAL_ALIGNMENT_LEFT,-1,13,theme.markings_color)
		if row == config.goal_row:
			for column in config.goal_columns:
				var x := config.cell_position(Vector2i(column,row)).x
				var facade: Texture2D = profile.destination_art if profile.destination_art != null else GATE
				var tint := Color.WHITE
				if config is MapConfig:
					var slot := config.goal_columns.find(column)
					if slot < config.destination_art_overrides.size() and config.destination_art_overrides[slot] != null:
						facade = config.destination_art_overrides[slot]
					if slot < config.destination_tints.size(): tint = config.destination_tints[slot]
				draw_texture_rect(facade,Rect2(x-64,y-82,128,52),false,theme.surface(tint))
			draw_string(ThemeDB.fallback_font,Vector2(1160,y-52),"FINISH",HORIZONTAL_ALIGNMENT_LEFT,-1,16,theme.markings_color)
	_draw_polish()
	var tint := theme.surface(Color.WHITE)
	# Atmosphere fades scenery more than hazards, with no actor modulation.
	tint = tint.lerp(theme.atmosphere_color,theme.fog_strength*0.65)
	for site in prop_sites:
		draw_texture_rect(site.texture,site.rect,false,tint)
		if theme.vehicle_lights and site.texture.resource_path.ends_with("/lamp.svg"):
			var light_at: Vector2 = site.rect.position + Vector2(51,12) * site.rect.size / 64.0
			draw_circle(light_at,9,Color(1.0,0.87,0.55,0.10))
			draw_circle(light_at,3,Color(1.0,0.94,0.71,0.9))

func _draw_rest(y: float, row: int) -> void:
	var color := theme.surface(profile.safe_color) * theme.safe_tint
	draw_rect(Rect2(64,y-28,1152,56),color)
	var detail := color.darkened(0.12)
	if profile.rest_style == "Paving":
		for x in range(64,1216,64):
			draw_line(Vector2(x,y-27),Vector2(x,y+27),detail,1)
		draw_line(Vector2(64,y),Vector2(1216,y),detail,1)
	elif profile.rest_style == "Bank":
		for x in range(76,1210,40):
			draw_line(Vector2(x,y-25),Vector2(x,y+25),detail,2)
	elif profile.rest_style == "Gravel":
		for x in range(78,1210,42):
			draw_circle(Vector2(x,y+17),1.5,detail)
	else:
		draw_rect(Rect2(64,y-18,1152,36),color.lightened(0.08))
	for edge_y in [y-30,y+30]:
		draw_line(Vector2(64,edge_y),Vector2(1216,edge_y),theme.surface(profile.edge_color),2)
	# Bank/rail landmarks sit only on the reserved outside shoulders.
	if kinds.get(row+1,-1) == LevelSectionConfig.Kind.WATER_SECTION or kinds.get(row-1,-1) == LevelSectionConfig.Kind.WATER_SECTION:
		for x in [6,1226]: draw_texture_rect(REEDS,Rect2(x,y-25,48,50),false,theme.surface(Color.WHITE))
	elif kinds.get(row+1,-1) == LevelSectionConfig.Kind.RAILWAY_SECTION:
		for x in [8,1224]: draw_texture_rect(CROSSBUCK,Rect2(x,y-25,48,50),false,theme.surface(Color.WHITE))
	# A quiet ground inscription, not a gameplay instruction or an obstacle.
	if row > 0:
		draw_string(ThemeDB.fallback_font,Vector2(174,y+5),profile.sign_caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(detail,0.75))
	ThemeArt.surface_details(self,y,theme,false)

func _draw_polish() -> void:
	# Bounded camera-window ground detail; no new prop/physics nodes.
	for row in range(rows.x,rows.y+1):
		var y:=layout.config.cell_position(Vector2i(0,row)).y
		if rest.has(row):
			for x in range(78,1210,80):
				var shade:=theme.surface(profile.safe_color).darkened(0.18)
				match profile.rest_style:
					"Path":
						draw_line(Vector2(x,y+20),Vector2(x-3,y+14),Color(shade,0.6),1)
						draw_line(Vector2(x,y+20),Vector2(x+4,y+16),Color(shade,0.6),1)
					"Paving":
						draw_rect(Rect2(x,y+22,35,4),theme.surface(Color("ede2bf")))
						draw_line(Vector2(x,y+26),Vector2(x+35,y+26),shade,2)
					"Bank":
						draw_circle(Vector2(x,y+21),3,Color(shade,0.5))
						draw_line(Vector2(x+8,y+19),Vector2(x+20,y+19),Color(shade,0.4),2)
					"Gravel":
						draw_rect(Rect2(x,y+23,8,3),Color("e0d29b"))
		if kinds.get(row,-1)==LevelSectionConfig.Kind.WATER_SECTION:
			for x in range(90,1200,150):
				draw_arc(Vector2(x+(row%3)*13,y+22),18,0.1,1.9,9,Color(0.7,0.9,0.9,0.20),1,true)
	for site in prop_sites:
		var rect: Rect2=site.rect
		draw_rect(Rect2(rect.position+Vector2(5,rect.size.y-6),Vector2(rect.size.x-5,5)),Color(0.05,0.10,0.12,0.24))
