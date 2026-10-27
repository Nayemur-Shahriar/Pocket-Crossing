class_name VehicleLibrary
extends RefCounted
# Lazy load: editor class discovery must not request SVGs before initial import.
static var _catalog: VehicleCatalog
static func get_catalog() -> VehicleCatalog:
	if _catalog == null:
		_catalog = load("res://resources/vehicles/catalog.tres") as VehicleCatalog
	return _catalog
static func find_visual(id: String) -> VehicleVisualConfig:
	return get_catalog().find_visual(id)
