class_name SectionLayoutCompiler
extends RefCounted
## Compiles ordered section data into the proven grid/world contract.
## No spawning, simulation, weather or save access here.
static func compile(source: LevelConfig) -> CompiledLevelLayout:
	var result := CompiledLevelLayout.new()
	if source == null:
		result.errors.append("Missing level configuration")
		return result
	if source.sections.is_empty():
		result.legacy = true
		result.config = source
		result.errors = source.legacy_validation_errors()
		if not result.errors.is_empty():
			return result
		result.total_rows = source.goal_row + 1
		for row in range(result.total_rows - 1):
			var safe := true
			for lane in source.lanes:
				if lane != null and lane.row == row:
					safe = false
			if safe:
				result.safe_rows.append(row)
		return result
	if source.sections.size() < 2:
		result.errors.append("Layout requires START and DESTINATION sections")
	var ids := {}
	var total := 0
	for i in range(source.sections.size()):
		var section := source.sections[i]
		if section == null:
			result.errors.append("Section %d is missing" % i)
			continue
		for error in section.validation_errors(source.columns):
			result.errors.append("Section %d: %s" % [i, error])
		if section.kind == LevelSectionConfig.Kind.RAILWAY_SECTION:
			if not is_finite(source.hop_seconds) or source.hop_seconds <= 0:
				result.errors.append("Railway requires a positive finite player hop duration")
			for track in section.railway_tracks:
				if track != null and track.warning_seconds < (section.railway_tracks.size() + 1) * source.hop_seconds + 1.0:
					result.errors.append("Railway warning must allow section traversal plus one second reaction time")
		if section.kind == LevelSectionConfig.Kind.WATER_SECTION:
			if not is_finite(source.hop_seconds) or source.hop_seconds <= 0:
				result.errors.append("Water requires a positive finite hop duration")
			for lane in section.water_lanes:
				if lane != null and lane.platform_speed * (1.0 + lane.speed_variation) * source.hop_seconds > (lane.platform_length - 36.0) * 0.25:
					result.errors.append("Platform travels too far during one hop; lower speed or increase deck length")
		if (i == 0) != (section.kind == LevelSectionConfig.Kind.START_SECTION):
			result.errors.append("START must occur exactly once, first")
		if (i == source.sections.size() - 1) != (section.kind == LevelSectionConfig.Kind.DESTINATION_SECTION):
			result.errors.append("DESTINATION must occur exactly once, last")
		if not section.section_id.is_empty():
			if ids.has(section.section_id):
				result.errors.append("Duplicate section_id: " + section.section_id)
			ids[section.section_id] = true
		total += section.row_count()
	if total > 4096 or source.columns < 1 or source.columns > 256:
		result.errors.append("Authoring safety limits: 4096 rows, 256 columns")
	if not result.errors.is_empty():
		return result
	# Shallow-copy immutable resources; clone every lane before assigning global rows.
	var runtime := source.duplicate(false) as LevelConfig
	runtime.sections = []
	runtime.lanes = []
	runtime.obstacles = []
	runtime.classic_greenway_art = false
	var row := 0
	for section in source.sections:
		result.sections.append({"id": section.section_id, "kind": section.kind, "first_row": row, "row_count": section.row_count(), "resource": section})
		match section.kind:
			LevelSectionConfig.Kind.START_SECTION:
				runtime.spawn_cell = Vector2i(section.spawn_column, row)
			LevelSectionConfig.Kind.ROAD_SECTION:
				for i in range(section.road_lanes.size()):
					var lane := section.road_lanes[i].duplicate(true) as LaneConfig
					lane.row = row + i
					runtime.lanes.append(lane)
			LevelSectionConfig.Kind.DESTINATION_SECTION:
				runtime.goal_row = row
				runtime.goal_columns = section.destination_columns.duplicate()
			LevelSectionConfig.Kind.RAILWAY_SECTION:
				pass # Runtime reads track settings from the compiled section descriptors.
			LevelSectionConfig.Kind.WATER_SECTION:
				pass # Water lanes are built from descriptors by the runtime adapter.
		if section.is_rest_area():
			for offset in range(section.row_count()):
				result.safe_rows.append(row + offset)
		for cell in section.blocked_cells:
			runtime.obstacles.append(Vector2i(cell.x, cell.y + row))
		row += section.row_count()
	result.config = runtime
	result.total_rows = row
	result.errors.append_array(runtime.legacy_validation_errors())
	return result
