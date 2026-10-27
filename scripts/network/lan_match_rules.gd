class_name LanMatchRules
extends RefCounted
## Pure, host-used competitive rules. No Local Play or persistence dependencies.
const DURATIONS := [60, 90, 120, 150]
const MODES := ["time", "score"]
static func mode_name(mode: String) -> String:
	return "HIGHEST SCORE" if mode == "score" else "FASTEST TIME"
static func score(safe: int, coins: int, deaths: int, remaining: float) -> int:
	return maxi(0, safe * 1000 + coins * 50 - deaths * 150 + (2500 + maxi(0, floori(remaining)) * 25 if safe == 5 else 0))
static func before(a: Dictionary, b: Dictionary, mode: String) -> bool:
	var both: bool = a.safe == 5 and b.safe == 5
	if mode == "time":
		if (a.safe == 5) != (b.safe == 5): return a.safe == 5
		if both and a.time != b.time: return a.time < b.time
		if not both and a.safe != b.safe: return a.safe > b.safe
		if a.score != b.score: return a.score > b.score
		if a.coins != b.coins: return a.coins > b.coins
		if a.deaths != b.deaths: return a.deaths < b.deaths
	else:
		if a.score != b.score: return a.score > b.score
		if a.safe != b.safe: return a.safe > b.safe
		if both and a.time != b.time: return a.time < b.time
		if a.deaths != b.deaths: return a.deaths < b.deaths
		if a.coins != b.coins: return a.coins > b.coins
	return int(a.peer) < int(b.peer)
static func ranked(source: Array, mode: String) -> Array:
	var result := source.duplicate(true)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return before(a, b, mode))
	for i in range(result.size()): result[i].rank = i + 1
	return result
static func awards(rows: Array) -> Array:
	var result: Array = []
	for key in ["time", "score", "coins", "deaths"]:
		var best: Dictionary = {}
		for row: Dictionary in rows:
			if key == "time" and row.safe != 5: continue
			if key in ["score", "coins"] and row[key] <= 0: continue
			if key == "deaths" and row.safe == 0 and row.coins == 0: continue
			if best.is_empty(): best = row; continue
			var lower: bool = key in ["time", "deaths"]
			if (row[key] < best[key] if lower else row[key] > best[key]) or (row[key] == best[key] and row.peer < best.peer): best = row
		if not best.is_empty(): result.append({"kind":key, "name":best.name, "value":best[key], "peer":best.peer})
	return result
