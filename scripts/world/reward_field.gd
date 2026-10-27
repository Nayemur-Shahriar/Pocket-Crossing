class_name RewardField
extends Node2D
## Layout-independent pickups. The world supplies safe sites with opaque keys and positions.
var pickups: Dictionary = {}
func setup(candidates: Array[Dictionary], coin_count: int, power_ups: Array[PowerUpConfig]) -> void:
	for node in get_children():
		remove_child(node)
		node.queue_free()
	pickups.clear()
	# Power-ups distributed between safe rows; coin count always bounded.
	var available := candidates.duplicate()
	for i in range(power_ups.size()):
		if available.is_empty() or i >= 3:
			break
		var index := mini(i * 2, available.size() - 1)
		var site: Dictionary = available.pop_at(index)
		var power: PowerUpConfig = power_ups[i]
		if power != null:
			add_pickup(site, power.effect, power)
	for i in range(mini(clampi(coin_count, 0, 12), available.size())):
		add_pickup(available[i], "coin")
func add_pickup(site: Dictionary, kind: String, power: PowerUpConfig = null, coin_value: int = 1) -> void:
	if not site.has("key") or not site.get("position") is Vector2 or pickups.has(site.key):
		return
	var pickup := RewardPickup.new()
	pickup.kind = kind
	pickup.coin_value = coin_value
	pickup.power = power
	pickup.position = site.position
	add_child(pickup)
	pickups[site.key] = pickup
func take(cell: Variant) -> RewardPickup:
	if not pickups.has(cell):
		return null
	var pickup: RewardPickup = pickups[cell]
	pickups.erase(cell)
	pickup.collect()
	return pickup
