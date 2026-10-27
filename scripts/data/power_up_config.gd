class_name PowerUpConfig
extends Resource
## Add a resource to LevelConfig.power_ups to configure a temporary effect.
@export_enum("shield", "slow", "double") var effect: String = "shield"
@export var display_name: String = "Shield"
@export_range(1.0, 20.0) var duration: float = 12.0
@export_range(0.4, 1.0) var traffic_scale: float = 0.65
@export_range(1, 3) var reward_multiplier: int = 2
@export var color: Color = Color("91d6ec")
