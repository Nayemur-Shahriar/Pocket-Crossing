class_name LevelConfig
extends Resource
## The editable rules and geometry for a level; no gameplay code belongs here.

@export var display_name: String = "Greenway"
@export var level_number: int = 1
@export var time_limit: float = 90.0
@export var starting_lives: int = 3
@export var columns: int = 18
@export var goal_row: int = 6
@export var cell_size: float = 64.0
@export var grid_origin: Vector2 = Vector2(96, 576)
@export var spawn_cell: Vector2i = Vector2i(8, 0)
@export var goal_columns: Array[int] = [2, 6, 11, 15]
@export var lanes: Array[LaneConfig] = []
@export var forward_points: int = 10
@export var destination_points: int = 100
@export var seconds_bonus: int = 5
@export var life_bonus: int = 50

@export_group("Movement feel")
@export_range(0.08, 0.25) var hop_seconds: float = 0.14
@export_range(0.0, 20.0) var hop_height: float = 11.0
@export_range(0.0, 2.0) var spawn_protection: float = 0.9
@export_range(0.2, 2.0) var hit_reset_seconds: float = 0.9
@export_range(0.2, 2.0) var destination_reset_seconds: float = 0.65
@export_group("Learning curve")
@export_range(0.5, 1.0) var starting_speed_scale: float = 0.72
@export_range(0.5, 1.5) var final_speed_scale: float = 1.0
@export_range(10.0, 120.0) var difficulty_ramp_seconds: float = 60.0

func cell_position(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell.x, -cell.y) * cell_size

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y <= goal_row

@export_group("Progression and environment")
@export var level_id: String = "greenway"
@export_enum("Greenway", "City", "Highway", "Village", "Railway") var theme: String = "Greenway"
@export var difficulty_label: String = "Beginner"
@export var obstacles: Array[Vector2i] = []
@export var score_target: int = 600
@export var target_reward: int = 100

func legacy_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if level_id.is_empty() or not is_finite(time_limit) or time_limit <= 0 or goal_columns.is_empty():
		errors.append("ID, positive time, and destinations are required")
	if columns < 1 or columns > 256 or goal_row < 1 or goal_row > 4095 or not is_finite(cell_size) or cell_size <= 0:
		errors.append("Invalid grid dimensions")
		return errors
	# Inspector ranges are UI hints, not validation of hand-edited Resource data.
	if not grid_origin.is_finite() or not is_finite(hop_seconds) or hop_seconds <= 0:
		errors.append("Finite grid origin and positive finite hop duration are required")
	if starting_lives < 1 or starting_lives > 3:
		errors.append("Starting lives must be 1–3")
	for value in [hop_height, spawn_protection, hit_reset_seconds, destination_reset_seconds]:
		if not is_finite(value) or value < 0:
			errors.append("Movement/reset settings must be finite and nonnegative")
	for value in [starting_speed_scale, final_speed_scale, difficulty_ramp_seconds]:
		if not is_finite(value) or value <= 0:
			errors.append("Speed scales and ramp duration must be finite and positive")
	if not is_finite(star_time_fraction) or star_time_fraction < 0 or star_time_fraction > 1 or star_lives_required < 1 or star_lives_required > starting_lives:
		errors.append("Star thresholds must fit the available time and lives")
	for value in [forward_points, destination_points, seconds_bonus, life_bonus, score_target, target_reward]:
		if value < 0:
			errors.append("Score values must be nonnegative")
	if not is_in_bounds(spawn_cell) or obstacles.has(spawn_cell):
		errors.append("Invalid starting cell")
	var rows: Array[int] = []
	for lane in lanes:
		if lane == null:
			errors.append("Missing lane resource")
			continue
		errors.append_array(lane.validation_errors())
		if lane.row <= 0 or lane.row >= goal_row or rows.has(lane.row):
			errors.append("Lane rows must be unique and between start and goals")
		rows.append(lane.row)
		if lane.row == spawn_cell.y:
			errors.append("Starting cell must be on a safe row")
		if lane.vehicle_types.is_empty() or lane.vehicle_colors.is_empty() or lane.spawn_min <= 0 or lane.spawn_max < lane.spawn_min or absi(lane.direction) != 1:
			errors.append("Invalid traffic configuration")
		if lane.pattern != "steady" and lane.cycle_seconds <= lane.open_seconds + lane.warning_seconds:
			errors.append("Pattern must leave time after its warning")
	var goal_seen := {}
	for column in goal_columns:
		if column < 0 or column >= columns or goal_seen.has(column):
			errors.append("Destination outside board or duplicated")
		goal_seen[column] = true
	# Obstacles may decorate safe rows, never obstruct a live traffic escape.
	for cell in obstacles:
		if not is_in_bounds(cell) or rows.has(cell.y) or cell.y == goal_row:
			errors.append("Obstacles must be on safe rows")
	# Every destination must remain reachable through static geometry.
	var visited: Array[Vector2i] = [spawn_cell]
	var seen := {spawn_cell: true}
	var cursor := 0
	while cursor < visited.size():
		var cell := visited[cursor]
		cursor += 1
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + direction
			if is_in_bounds(next) and not obstacles.has(next) and not seen.has(next):
				if next.y != goal_row or goal_columns.has(next.x):
					visited.append(next)
					seen[next] = true
	for column in goal_columns:
		if not seen.has(Vector2i(column, goal_row)):
			errors.append("Unreachable destination")
	return errors

@export_group("Rewards")
@export_range(0, 12) var coin_count: int = 6
@export var power_ups: Array[PowerUpConfig] = [preload("res://resources/powerups/shield.tres"), preload("res://resources/powerups/slow.tres"), preload("res://resources/powerups/double.tres")]
@export_range(0.1, 0.8) var star_time_fraction: float = 0.35
@export_range(1, 3) var star_lives_required: int = 2

func rate_completion(seconds: float, lives: int) -> int:
	return 1 + int(seconds >= time_limit * star_time_fraction) + int(lives >= star_lives_required)

@export_group("Section architecture")
## Empty preserves the existing flat-lane level format. Nonempty is authoritative.
@export var sections: Array[LevelSectionConfig] = []
## Drag a resources/themes/*.tres preset here. The legacy Theme string above
## is an environment category, not the M10 time/weather preset selector.
@export var presentation: LevelThemeConfig
## Optional scenery profile, independent of weather. Null retains M1–M11 appearance.
@export var environment: EnvironmentProfile
## Explicit legacy art choice; never infer gameplay or art from level_number.
@export var classic_greenway_art: bool = false

func compile_layout() -> CompiledLevelLayout:
	return SectionLayoutCompiler.compile(self)

func validation_errors() -> PackedStringArray:
	return compile_layout().errors

func playability_errors() -> PackedStringArray:
	return compile_layout().runtime_errors()
