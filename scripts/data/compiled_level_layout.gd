class_name CompiledLevelLayout
extends RefCounted
## Transient derived data; never saved over the editable source resource.
var config: LevelConfig
var sections: Array[Dictionary] = []
var safe_rows: Array[int] = []
var deferred_features := PackedStringArray()
var errors := PackedStringArray()
var total_rows: int = 0
var legacy: bool = false

func runtime_errors() -> PackedStringArray:
	var reasons := errors.duplicate()
	if not reasons.is_empty() or legacy:
		return reasons
	for feature in deferred_features:
		reasons.append(feature + " is configuration-only in this milestone")
	# Horizontal art/vehicle envelopes still use the landscape board width.
	# Vertical length is data-driven; there is no screen-height runtime limit.
	if config.columns != 18 or not is_equal_approx(config.cell_size, 64.0) or config.grid_origin != Vector2(96, 576):
		reasons.append("Landscape renderer requires 18 columns, 64px cells, and origin (96,576)")
	return reasons

func section_at(row: int) -> Dictionary:
	for section in sections:
		if row >= section.first_row and row < section.first_row + section.row_count:
			return section
	return {}
