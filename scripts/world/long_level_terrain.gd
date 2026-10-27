class_name LongLevelTerrain
extends Node2D
## Draw only visible rows plus an edge margin; reuse existing original textures.
const GRASS := preload("res://assets/art/grass.svg")
const ASPHALT := preload("res://assets/art/asphalt.svg")
const PAVEMENT := preload("res://assets/art/pavement.svg")
var theme: LevelThemeConfig = LevelThemeConfig.new()
var config: LevelConfig
var camera: LevelCamera
var roads: Dictionary = {}
var rest_rows: Dictionary = {}
var obstacles: Dictionary = {}
var rows := Vector2i(-1, -1)

func setup(layout: CompiledLevelLayout, view: LevelCamera) -> void:
	config = layout.config
	camera = view
	roads.clear()
	rest_rows.clear()
	obstacles.clear()
	for lane in config.lanes:
		roads[lane.row] = lane
	for row in layout.safe_rows:
		rest_rows[row] = true
	for cell in config.obstacles:
		if not obstacles.has(cell.y):
			obstacles[cell.y] = []
		obstacles[cell.y].append(cell)
	rows = Vector2i(-1, -1)
	refresh()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if camera == null:
		return
	var visible_rows := camera.visible_rows()
	visible_rows.x = maxi(0, visible_rows.x - 1)
	visible_rows.y = mini(config.goal_row, visible_rows.y + 1)
	if rows != visible_rows:
		rows = visible_rows
		queue_redraw()

func _draw() -> void:
	if config == null:
		return
	var tint := theme.ground_tint
	var ground := theme.grass_tint
	if config.environment != null and config.environment.is_valid():
		ground *= config.environment.ground_tint
	for row in range(rows.x, rows.y + 1):
		var y := config.cell_position(Vector2i(0, row)).y
		var area := Rect2(0, y - 32.0, 1280, 64)
		draw_texture_rect(GRASS, area, true, theme.surface(ground))
		draw_rect(area, tint)
		if roads.has(row):
			draw_texture_rect(ASPHALT, area, true, theme.surface(theme.road_tint))
			for x in range(18, 1280, 76):
				draw_rect(Rect2(x, y - 32, 34, 2), theme.markings_color)
		elif rest_rows.has(row):
			draw_texture_rect(PAVEMENT, Rect2(56, y - 28, 1168, 56), true, theme.surface(theme.safe_tint))
			draw_line(Vector2(0, y - 31), Vector2(1280, y - 31), Color("b6c5a1"), 2)
		ThemeArt.surface_details(self,y,theme,roads.has(row))
		for cell in obstacles.get(row, []):
			var at := config.cell_position(cell)
			draw_rect(Rect2(at - Vector2(27, 25), Vector2(54, 50)), theme.surface(Color("9a9873")))
			draw_circle(at, 21, theme.surface(Color("628d72")))
		if row == 0:
			draw_texture_rect(PAVEMENT, Rect2(0, y + 32, 1280, 8), true, theme.surface(theme.safe_tint))
			draw_arc(config.cell_position(config.spawn_cell), 25, 0, TAU, 48, Color("ad9e72"), 2, true)
		if row == config.goal_row:
			draw_texture_rect(GRASS, Rect2(0, y - 84, 1280, 52), true, theme.surface(ground))
			draw_rect(Rect2(0,y-84,1280,42),theme.background_color)
			draw_line(Vector2(0, y - 78), Vector2(1280, y - 78), Color("91ad84"), 3)
