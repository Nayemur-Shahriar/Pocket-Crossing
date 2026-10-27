class_name MapRunStats
extends RefCounted
var deaths:=0
var water_deaths:=0
var train_deaths:=0
var risk_coins:=0
var coins:=0
func record_death(kind: int) -> void:
	deaths+=1
	if kind==LevelSectionConfig.Kind.WATER_SECTION:water_deaths+=1
	if kind==LevelSectionConfig.Kind.RAILWAY_SECTION:train_deaths+=1
func snapshot(safe: int, seconds: float) -> Dictionary:
	return {"safe":safe,"time":seconds,"coins":coins,"risk_coins":risk_coins,"deaths":deaths,"water_deaths":water_deaths,"train_deaths":train_deaths}
