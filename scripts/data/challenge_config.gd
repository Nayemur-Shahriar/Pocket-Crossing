class_name ChallengeConfig
extends Resource
## Runtime modifiers operate on a deep copy; original maps remain immutable.
@export var challenge_id: String=""
@export var title: String=""
@export var description: String=""
@export var maps: Array[String]=[]
@export_enum("rush","river","fog","one_life","double_coins","no_shield") var modifier: String="rush"
func apply(source: MapConfig) -> MapConfig:
	if source==null or source.level_id not in maps:return null
	var result:=source.duplicate(true) as MapConfig
	if modifier=="one_life":
		result.starting_lives=1
		result.star_lives_required=1
	if modifier=="fog":
		result.presentation=LevelThemeConfig.resolve(source.presentation).duplicate(true)
		result.presentation.weather="Fog"
		result.presentation.weather_intensity=0.55
		result.presentation.fog_strength=0.22
		result.presentation.player_highlight=true
		result.presentation.vehicle_lights=true
		result.presentation.train_lights=true
	for section in result.sections:
		if modifier=="rush":
			for lane in section.road_lanes:
				lane.speed=minf(350,lane.speed*1.12)
				lane.spawn_min=maxf(0.8,lane.spawn_min*0.8)
				lane.spawn_max=maxf(lane.spawn_min,lane.spawn_max*0.8)
		if modifier=="river":
			for lane in section.water_lanes:
				lane.platform_speed=minf(110,lane.platform_speed*1.12)
				lane.minimum_spacing=maxf(24,lane.minimum_spacing*0.9)
		if modifier=="no_shield":
			for i in range(section.pickups.size()-1,-1,-1):
				if section.pickups[i].power!=null and section.pickups[i].power.effect=="shield":section.pickups.remove_at(i)
	if modifier=="no_shield":
		for i in range(result.power_ups.size()-1,-1,-1):
			if result.power_ups[i].effect=="shield":result.power_ups.remove_at(i)
	return result
func coin_multiplier() -> int:return 2 if modifier=="double_coins" else 1
