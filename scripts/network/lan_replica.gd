class_name LanReplica
extends Node
## Logical standings for everyone; physical correction only for the recipient.
var world: RoadLevel
var prediction:=LanPrediction.new()
var hazards: LanHazards
var vehicles: Dictionary:
	get:return hazards.vehicles if hazards!=null else {}
var snapshot_hz:=10.0
func clear() -> void:
	prediction.clear()
	if hazards!=null:hazards.clear()
func capture(actors: Dictionary, elapsed: float, recipient: int=1) -> Dictionary:
	var players: Dictionary={}
	for id in actors:
		var r: Dictionary=actors[id]
		players[id]={"lives":r.lives,"occupied":r.occupied,"coins":r.coins,"score":r.score,"state":r.state,"rank":r.rank,"finish":r.finish,"deaths":r.deaths}
	var r: Dictionary=actors[recipient]
	var row:=-1;var platform:=-1;var offset:=0.0
	if r.support.support!=null:
		row=r.actor.cell.y;platform=r.support.lanes[row].platforms.find(r.support.support);offset=r.actor.position.x-r.support.support.position.x
	var owner:={"p":r.actor.position,"cell":r.actor.cell,"moving":r.actor.moving,"visible":r.actor.visible,"active":r.state=="active","ack":r.ack,"generation":r.generation,"protection":r.actor.invulnerable_left,"shield":r.actor.shield_visible,"collected":r.collected,"caption":r.powers.caption(),"water_row":row,"platform":platform,"deck_offset":offset,"dog":r.get("dog_state",{})}
	return {"time":elapsed,"players":players,"owner":owner}
func receive(data: Dictionary, actors: Dictionary, local_id: int) -> void:
	for id in data.players:
		if not actors.has(id):continue
		for key in data.players[id]:actors[id][key]=data.players[id][key]
	if not actors.has(local_id):return
	var local: Dictionary=actors[local_id]
	local.dog_state=data.owner.get("dog",{})
	local.collected=data.owner.collected;local.caption=data.owner.caption
	local.actor.set_shield_visual(data.owner.shield)
	prediction.receive(data.owner)
