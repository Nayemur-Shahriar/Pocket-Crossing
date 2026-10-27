class_name VehicleCatalog
extends Resource
@export var entries: Array[VehicleVisualConfig] = []
func find_visual(id: String) -> VehicleVisualConfig:
	for entry in entries:
		if entry != null and entry.id == id:
			return entry
	return null
