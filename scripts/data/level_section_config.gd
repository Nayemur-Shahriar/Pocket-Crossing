class_name LevelSectionConfig
extends Resource
## Ordered horizontal band. Lane/track counts come from arrays, never duplicated counts.
enum Kind { START_SECTION, ROAD_SECTION, SAFE_SECTION, RAILWAY_SECTION, WATER_SECTION, DESTINATION_SECTION }
@export var section_id: String = ""
@export var kind: Kind = Kind.SAFE_SECTION
@export_range(1, 512) var safe_rows: int = 1
@export var road_lanes: Array[LaneConfig] = []
@export var railway_tracks: Array[RailwayTrackConfig] = []
@export var water_lanes: Array[WaterLaneConfig] = []
@export var spawn_column: int = 8
@export var destination_columns: Array[int] = [2, 6, 11, 15]
## Local cells, Y=0 at the bottom of this section; only start/safe can hold obstacles.
@export var blocked_cells: Array[Vector2i] = []
## Optional authored rewards. If any section has these, they replace automatic placement.
@export var pickups: Array[PickupPlacement] = []

func row_count() -> int:
	match kind:
		Kind.ROAD_SECTION: return road_lanes.size()
		Kind.RAILWAY_SECTION: return railway_tracks.size()
		Kind.WATER_SECTION: return water_lanes.size()
		Kind.SAFE_SECTION: return safe_rows
	return 1

func is_rest_area() -> bool:
	return kind == Kind.START_SECTION or kind == Kind.SAFE_SECTION

func validation_errors(columns: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if kind < Kind.START_SECTION or kind > Kind.DESTINATION_SECTION:
		errors.append("Unknown section kind")
	if row_count() < 1 or row_count() > 512:
		errors.append("Section must contain 1–512 rows")
	if kind != Kind.ROAD_SECTION and not road_lanes.is_empty():
		errors.append("Road lanes belong only in ROAD_SECTION")
	if kind != Kind.RAILWAY_SECTION and not railway_tracks.is_empty():
		errors.append("Tracks belong only in RAILWAY_SECTION")
	if kind != Kind.WATER_SECTION and not water_lanes.is_empty():
		errors.append("Water lanes belong only in WATER_SECTION")
	if kind == Kind.START_SECTION and (spawn_column < 0 or spawn_column >= columns):
		errors.append("Spawn column outside board")
	if kind == Kind.DESTINATION_SECTION:
		if destination_columns.is_empty():
			errors.append("At least one destination is required")
		var seen := {}
		for column in destination_columns:
			if column < 0 or column >= columns or seen.has(column):
				errors.append("Destination columns must be unique and inside board")
			seen[column] = true
	for cell in blocked_cells:
		if not is_rest_area() or cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= row_count():
			errors.append("Obstacle must be inside a START/SAFE section")
		if kind == Kind.START_SECTION and cell == Vector2i(spawn_column, 0):
			errors.append("Obstacle blocks the starting cell")
	var pickup_cells := {}
	for pickup in pickups:
		if pickup == null:
			errors.append("Missing pickup placement")
			continue
		var cell := pickup.cell
		if not (is_rest_area() or (pickup.on_hazard and pickup.power==null and kind in [Kind.ROAD_SECTION,Kind.RAILWAY_SECTION,Kind.WATER_SECTION])) or cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= row_count() or blocked_cells.has(cell) or pickup_cells.has(cell):
			errors.append("Pickups need unique unblocked START/SAFE cells")
		if kind == Kind.START_SECTION and cell == Vector2i(spawn_column, 0):
			errors.append("Pickup cannot overlap player spawn")
		if pickup.power != null and (pickup.power.effect not in ["shield", "slow", "double"] or pickup.power.duration <= 0):
			errors.append("Invalid pickup power")
		if pickup.coin_value not in [1,3]:errors.append("Invalid coin value")
		pickup_cells[cell] = true
	for lane in road_lanes:
		if lane == null:
			errors.append("Missing road lane resource")
		else:
			errors.append_array(lane.validation_errors())
			if lane.pattern == "railway" or lane.vehicle_types.has("train"):
				errors.append("New ROAD sections cannot contain railway/train behavior")
	if kind == Kind.RAILWAY_SECTION and railway_tracks.size() > 3:
		errors.append("Railway section supports 1–3 configured tracks")
	for track in railway_tracks:
		if track == null:
			errors.append("Missing track resource")
		else:
			errors.append_array(track.validation_errors())
	for lane in water_lanes:
		if lane == null:
			errors.append("Missing water lane resource")
		else:
			errors.append_array(lane.validation_errors())
	return errors
