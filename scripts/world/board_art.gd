extends Node2D
## Original vector scenery. Replace this node with a TileMapLayer when upgrading art.

const INK := Color("273943")
const ASPHALT := preload("res://assets/art/asphalt.svg")
const PAVEMENT := preload("res://assets/art/pavement.svg")
const GRASS := preload("res://assets/art/grass.svg")
const TREE := preload("res://assets/art/tree.svg")

var theme: LevelThemeConfig = LevelThemeConfig.new()
var config: LevelConfig

func _draw() -> void:
	if config != null and not config.classic_greenway_art:
		_draw_configured_board()
		_surface_details()
		return
	_theme_texture(GRASS, Rect2(0, 104, 1280, 512), true)
	# Destination garden and warm starting pavement.
	_theme_texture(GRASS, Rect2(0, 112, 1280, 112), true)
	draw_rect(Rect2(0, 112, 1280, 112), Color(0.92, 0.96, 0.73, 0.14))
	_theme_texture(PAVEMENT, Rect2(0, 544, 1280, 72), true)
	draw_rect(Rect2(0, 544, 1280, 5), Color("edf0d8"))
	draw_rect(Rect2(0, 549, 1280, 3), Color(0.12, 0.25, 0.24, 0.13))
	# Two pairs of lanes, separated by a safe median.
	for road_top in [224, 416]:
		draw_rect(Rect2(0, road_top + 4, 1280, 128), Color(0.07, 0.14, 0.13, 0.20))
		_theme_texture(ASPHALT, Rect2(0, road_top, 1280, 128), true)
		draw_rect(Rect2(0, road_top + 64, 1280, 64), Color(0.05, 0.12, 0.17, 0.16))
		draw_line(Vector2(0, road_top + 3), Vector2(1280, road_top + 3), Color("d0d8bc"), 3.0)
		draw_line(Vector2(0, road_top + 125), Vector2(1280, road_top + 125), Color("d0d8bc"), 3.0)
		var curb_lines := PackedVector2Array()
		for curb_x in range(0, 1280, 64):
			curb_lines.append_array(PackedVector2Array([Vector2(curb_x, road_top), Vector2(curb_x, road_top + 4),
				Vector2(curb_x, road_top + 124), Vector2(curb_x, road_top + 128)]))
		draw_multiline(curb_lines, Color("617b76"), 1)
		for x in range(18, 1280, 76):
			draw_rect(Rect2(x, road_top + 63, 34, 2), theme.markings_color)
	# Median paving leaves a clear path along its full width.
	_theme_texture(GRASS, Rect2(0, 352, 1280, 64), true)
	for x in range(64, 1220, 64):
		draw_rect(Rect2(x + 7, 369, 50, 33), Color(0.12, 0.28, 0.23, 0.15))
		draw_rect(Rect2(x + 6, 366, 50, 33), Color("c6d2ae"))
		draw_line(Vector2(x + 8, 367), Vector2(x + 54, 367), Color("e3e5c7"), 1)
	for x in [26.0, 1254.0]:
		_draw_bush(Vector2(x, 383))
	# Direction markings at the shoulders do not overlap playable columns.
	for spec in [Vector3(38, 512, 1), Vector3(1242, 512, 1), Vector3(38, 448, -1), Vector3(1242, 448, -1), Vector3(38, 320, 1), Vector3(1242, 320, 1), Vector3(38, 256, -1), Vector3(1242, 256, -1)]:
		_draw_arrow(Vector2(spec.x, spec.y), spec.z)
	# Top border planting. All decorative geometry is outside traffic hitboxes.
	for p in [Vector2(75, 151), Vector2(355, 149), Vector2(635, 147), Vector2(923, 149), Vector2(1200, 153)]:
		_theme_texture(TREE, Rect2(p - Vector2(37, 41), Vector2(74, 74)), false)
	for x in [140, 309, 564, 708, 889, 1140]:
		_draw_flowers(Vector2(x, 206))
	# Starting position: a small painted launch marker.
	draw_arc(Vector2(608, 576), 25, 0, TAU, 48, Color("ad9e72"), 2.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(674, 583), "START", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("827b62"))
	# Fence posts at the destination garden's rear edge.
	for x in range(15, 1280, 40):
		draw_rect(Rect2(x, 111, 4, 12), Color("91ad84"))
	draw_line(Vector2(0, 115), Vector2(1280, 115), Color("91ad84"), 3.0)
	_surface_details()

func _draw_arrow(at: Vector2, direction: float) -> void:
	var color := Color("768488")
	draw_line(at - Vector2(12 * direction, 0), at + Vector2(12 * direction, 0), color, 3, true)
	draw_polyline(PackedVector2Array([at + Vector2(4 * direction, -7), at + Vector2(12 * direction, 0), at + Vector2(4 * direction, 7)]), color, 3, true)

func _draw_bush(at: Vector2) -> void:
	draw_circle(at + Vector2(2, 3), 22, Color(0.1, 0.2, 0.15, 0.18))
	draw_circle(at, 21, Color("628d72"))
	draw_circle(at + Vector2(-7, -5), 12, Color("7ca081"))

func _draw_flowers(at: Vector2) -> void:
	for offset in [Vector2(-7, 2), Vector2(4, -4), Vector2(11, 4)]:
		draw_circle(at + offset + Vector2(0, 2), 4, Color("82a07b"))
		draw_circle(at + offset, 2.7, Color("f7e6a3"))

func _draw_configured_board() -> void:
	_theme_texture(GRASS, Rect2(0, 108, 1280, 508), true)
	var tint := Color(0.24, 0.39, 0.4, 0.15) if config.theme == "Highway" else Color(0.8, 0.64, 0.33, 0.12)
	if config.presentation != null or theme.theme_id != "day":
		tint = theme.ground_tint
	draw_rect(Rect2(0, 108, 1280, 508), tint)
	for lane in config.lanes:
		var y := config.cell_position(Vector2i(0, lane.row)).y
		_theme_texture(ASPHALT, Rect2(0, y - 32, 1280, 64), true)
		if lane.pattern == "railway":
			for x in range(0, 1280, 24):
				draw_rect(Rect2(x, y - 24, 7, 48), Color("9e9279"))
			for offset in [-18, 18]:
				draw_line(Vector2(0, y + offset), Vector2(1280, y + offset), Color("c1cacc"), 4)
		else:
			for x in range(18, 1280, 76):
				draw_rect(Rect2(x, y - 32, 34, 2), theme.markings_color)
		_draw_arrow(Vector2(38, y), lane.direction)
		_draw_arrow(Vector2(1242, y), lane.direction)
	_theme_texture(PAVEMENT, Rect2(0, 544, 1280, 72), true)
	for cell in config.obstacles:
		var at := config.cell_position(cell)
		draw_rect(Rect2(at - Vector2(27, 25), Vector2(54, 50)), Color("9a9873"))
		_draw_bush(at)
	for x in [75, 355, 635, 923, 1200]:
		_theme_texture(TREE, Rect2(x - 30, 109, 60, 60), false)
	var spawn := config.cell_position(config.spawn_cell)
	draw_arc(spawn, 25, 0, TAU, 48, Color("ad9e72"), 2, true)

func _theme_texture(texture: Texture2D, area: Rect2, tiled: bool) -> void:
	var tint := theme.grass_tint
	if texture == GRASS and config != null and config.environment != null and config.environment.is_valid():
		tint *= config.environment.ground_tint
	if texture == ASPHALT: tint = theme.road_tint
	elif texture == PAVEMENT: tint = theme.safe_tint
	draw_texture_rect(texture,area,tiled,theme.surface(tint))

func _surface_details() -> void:
	if config == null: return
	for lane in config.lanes:
		ThemeArt.surface_details(self,config.cell_position(Vector2i(0,lane.row)).y,theme,true)
	if theme.time_of_day != "Day" or theme.weather != "Clear":
		draw_rect(Rect2(0,108,1280,26),theme.background_color)
