class_name DogConfig
extends Resource
## Optional map rule. Only dry SAFE sections qualify; start/destination never do.
@export var section_ids: Array[String] = []
@export_range(2.5, 6.0) var stationary_seconds:=3.0
@export_range(0.7, 2.0) var warning_seconds:=1.0
@export_range(180.0, 420.0) var run_speed:=300.0
@export_range(3.0, 12.0) var cooldown_seconds:=5.0
func allows(section: Dictionary) -> bool:
	return int(section.get("kind",-1))==LevelSectionConfig.Kind.SAFE_SECTION and (section_ids.is_empty() or String(section.get("id","")) in section_ids)
