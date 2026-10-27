class_name ChallengeCatalog
extends RefCounted
const IDS=["rush_hour","fast_river","heavy_fog","one_life","double_coins","no_shield"]
static func find(id: String) -> ChallengeConfig:
	return load("res://resources/challenges/"+id+".tres") if id in IDS else null
static func for_map(id: String) -> Array[ChallengeConfig]:
	var result: Array[ChallengeConfig]=[]
	for key in IDS:
		var c:=find(key)
		if id in c.maps:result.append(c)
	return result
