class_name PickupPlacement
extends Resource
@export_enum("Normal:1","Risk:3") var coin_value: int=1
@export var on_hazard: bool=false
## Coordinates are local to a START/SAFE section. Null power means a coin.
@export var cell: Vector2i = Vector2i(8, 0)
@export var power: PowerUpConfig
