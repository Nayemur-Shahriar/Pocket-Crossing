class_name PowerUpController
extends RefCounted
## Simulation-only effects. Owner ticks active time; duplicate types refresh, never stack.
var active: Dictionary = {}
func activate(config: PowerUpConfig) -> void:
	if config.effect not in ["shield", "slow", "double"]:
		return
	active[config.effect] = {"config": config, "left": clampf(config.duration, 1.0, 20.0)}
func tick(delta: float) -> void:
	for id in active.keys():
		active[id].left = maxf(0.0, float(active[id].left) - delta)
		if active[id].left <= 0.0:
			active.erase(id)
func clear() -> void:
	active.clear()
func consume_shield() -> bool:
	return active.erase("shield")
func traffic_scale() -> float:
	return clampf(active.slow.config.traffic_scale, 0.4, 1.0) if active.has("slow") else 1.0
func multiplier() -> int:
	return clampi(active.double.config.reward_multiplier, 1, 3) if active.has("double") else 1
func caption() -> String:
	var labels := PackedStringArray()
	for id in active:
		labels.append("%s %ds" % [active[id].config.display_name, ceili(active[id].left)])
	return "  /  ".join(labels)
