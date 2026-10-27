class_name CharacterCatalog
extends RefCounted
## Cosmetic IDs are stable save keys. Every skin uses identical movement/hitboxes.
const PRICES := preload("res://resources/progression/character_prices.tres")
const SKINS := [
	{"id": "pip", "name": "Pip / Young boy", "cost": 0, "texture": "res://assets/art/courier.svg"},
	{"id": "mint", "name": "Mika / Young girl", "cost": 0, "texture": "res://assets/art/courier_mint.svg"},
	{"id": "coral", "name": "Rio / Adult man", "cost": 20, "texture": "res://assets/art/courier_coral.svg"},
	{"id": "violet", "name": "Nova / Adult woman", "cost": 40, "texture": "res://assets/art/courier_violet.svg"},
	{"id": "elder_man", "name": "Arun / Older man", "cost": 30, "texture": "res://assets/art/courier_elder_man.svg"},
	{"id": "elder_woman", "name": "Leela / Older woman", "cost": 30, "texture": "res://assets/art/courier_elder_woman.svg"},
]
static func find_skin(id: String) -> Dictionary:
	for skin in SKINS:
		if skin.id == id:
			var selected: Dictionary = skin.duplicate()
			if id in ["coral", "violet"]: selected.cost = clampi(int(PRICES.get(id)),0,1000)
			return selected
	return {}
