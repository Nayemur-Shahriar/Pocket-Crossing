class_name LanRace
extends Node
## Single hazard world, independently scored racers. Clients never simulate damage.
const ACTOR:=preload("res://scenes/actors/player.tscn")
var world: RoadLevel
var session: LanSession
var racers: Dictionary={}
var sites: Dictionary={}
var local_taken: Dictionary={}
var pending_finish: Array[int]=[]
var finish_order:=0
var elapsed:=0.0
var running:=false
var snapshot_left:=0.0
var replica: LanReplica
var config: MapConfig
var hidden_actors: Node2D
var state_hashes: Dictionary={}
var last_state_time:=-1.0
func setup(view: RoadLevel, link: LanSession) -> void:
	world=view;session=link;process_physics_priority=20
	session.prepare_match.connect(prepare)
	session.command_received.connect(command)
	session.snapshot_received.connect(_snapshot)
	world.collision.connect(_queue_contact)
	world.water_hazard.connect(_water_hit)
	replica=LanReplica.new();add_child(replica);replica.world=world
	replica.hazards=LanHazards.new();add_child(replica.hazards);replica.hazards.setup(world,session)
	hidden_actors=Node2D.new();hidden_actors.name="AuthorityActors";hidden_actors.visible=false;world.add_child(hidden_actors)
func clear() -> void:
	running=false;pending_finish.clear()
	for id in racers:
		var r: Dictionary=racers[id]
		if r.actor==null:continue
		if r.actor.step_completed.is_connected(r.callback):r.actor.step_completed.disconnect(r.callback)
		if r.actor!=world.player:
			r.support.clear_support();r.support.queue_free();r.actor.queue_free()
		elif r.actor.has_node("LanName"):
			var label: Node=r.actor.get_node("LanName")
			r.actor.remove_child(label);label.queue_free()
	racers.clear();sites.clear();local_taken.clear();state_hashes.clear();last_state_time=-1
	world.camera.player=world.player
	world.water_support.clear_support();world.set_active(false);replica.clear()
func prepare(id: String, roster: Dictionary, seed_value: int) -> void:
	clear()
	if id not in Profiles.MAP_IDS:return
	session.match_participants.assign(roster.keys())
	config=load("res://resources/maps/"+id+".tres")
	world.configure(config);world.reset(seed_value)
	world.activation.streaming=false;world.activation.refresh(true);world.activation.set_physics_process(false)
	world.set_active(true);world.traffic.process_mode=Node.PROCESS_MODE_DISABLED
	if not session.is_host():
		for lane in world.lanes:
			for vehicle in lane.get_children():lane.remove_child(vehicle);vehicle.queue_free()
	world.presentation.visible=true;world.decorations.set_running(false,false)
	for cell: Vector2i in world.rewards.pickups:
		var pickup: RewardPickup=world.rewards.pickups[cell]
		sites[cell]={"kind":pickup.kind,"power":pickup.power,"value":pickup.coin_value}
	var ids:=roster.keys();ids.sort()
	for peer_id: int in ids:
		var actor: CrossingPlayer=world.player if peer_id==session.local_id() else (ACTOR.instantiate() if session.is_host() else null)
		if actor!=null and actor!=world.player:hidden_actors.add_child(actor)
		var support: WaterSupport=world.water_support if actor==world.player else (WaterSupport.new() if actor!=null else null)
		if support!=null and support!=world.water_support:world.add_child(support)
		var data: Dictionary={"peer":peer_id,"actor":actor,"support":support,"lives":config.starting_lives,"occupied":{},"collected":{},"powers":PowerUpController.new(),"state":"active","respawn":0.0,"finish":0.0,"rank":0,"coins":0,"score":0,"furthest":0,"name":roster[peer_id].name,"id":roster[peer_id].id,"skin":roster[peer_id].skin,"ack":0,"active_seq":0,"commands":[],"generation":0,"deaths":0,"remaining":0.0,"water_deaths":0,"train_deaths":0,"risk_coins":0,"dog":DogEncounter.new(),"dog_state":{}}
		racers[peer_id]=data
		if actor==null:continue
		actor.setup(world.config,func(cell: Vector2i) -> bool:return can_enter(peer_id,cell))
		actor.apply_skin(data.skin);actor.presentation_highlight=true;actor.collision_mask=0
		support.setup(actor,world.config,world.water_lanes)
		if support!=world.water_support:support.hazard.connect(_water_hit)
		var callback:=func(cell: Vector2i) -> void:arrive(peer_id,cell)
		data.callback=callback;actor.step_completed.connect(callback)
		actor.enabled=false;actor.set_physics_process(false);support.set_physics_process(false)
	elapsed=0;finish_order=0;running=false;snapshot_left=0
	replica.snapshot_hz=session.settings.snapshot_hz
	if not session.is_host():replica.prediction.setup(world.player,world.water_support,session)
func can_enter(id: int, cell: Vector2i) -> bool:
	if not racers.has(id) or not world.config.is_in_bounds(cell) or world.config.obstacles.has(cell):return false
	if cell.y==world.config.goal_row:return world.goals.has(cell.x) and not racers[id].occupied.has(cell.x)
	return true
func begin() -> void:
	running=true;world.decorations.set_running(true,false)
	if not session.is_host():
		world.player.enabled=true;world.player.set_physics_process(true)
		world.water_support.set_physics_process(not world.water_lanes.is_empty())
		return
	world.traffic.process_mode=Node.PROCESS_MODE_INHERIT
	for r: Dictionary in racers.values():
		r.actor.enabled=true;r.actor.set_physics_process(true);r.support.set_physics_process(not world.water_lanes.is_empty())
func command(id: int, direction: Vector2i) -> void:
	if not session.is_host() or not running or session.expired() or session.phase!="racing" or not racers.has(id):return
	var r: Dictionary=racers[id]
	var seq:=int(session.sequences.get(id,0))
	if r.state!="active" or (session.command_generation>=0 and session.command_generation!=r.generation):r.ack=seq;return
	if r.commands.size()<8:r.commands.append({"seq":seq,"direction":direction});apply_commands(r)
func request_local(direction: Vector2i) -> void:
	if not running or session.expired() or session.phase!="racing":return
	if session.is_host():session.send_direction(direction)
	else:replica.prediction.request(direction)
func apply_commands(r: Dictionary) -> void:
	if r.state!="active" or r.actor.moving or r.commands.is_empty():return
	var item: Dictionary=r.commands.pop_front();r.active_seq=item.seq
	r.actor.request_step(item.direction)
	if not r.actor.moving:r.ack=item.seq
func reset_commands(r: Dictionary) -> void:
	r.commands.clear();r.ack=int(session.sequences.get(r.peer,0));r.generation+=1
func _queue_contact(actor: CrossingPlayer) -> void:
	_contact.call_deferred(actor,actor.contact_cause)
func _contact(actor: CrossingPlayer, cause: String) -> void:
	actor.contact_cause=cause
	_road_hit(actor)
func _road_hit(actor: CrossingPlayer) -> void:
	var description:="was hit by a train" if actor.contact_cause=="train" else "was hit by traffic"
	damage(actor,description,false,actor.contact_cause)
func _water_hit(actor: CrossingPlayer) -> void:damage(actor,"fell into the river",true)
func damage(actor: CrossingPlayer, description: String, water: bool, cause: String="car") -> void:
	if not session.is_host() or not running or session.expired() or session.phase!="racing":return
	for id: int in racers:
		var r: Dictionary=racers[id]
		if r.actor!=actor or r.state!="active":continue
		var outcome:=CollisionRules.hit(actor,r.powers)
		if outcome!=CollisionRules.Hit.LIFE_LOST:
			if water:reset_commands(r);actor.reset_to_spawn()
			return
		reset_commands(r)
		if water:cause="water"
		elif description.contains("train"):cause="train"
		if water:r.water_deaths+=1
		elif description.contains("train"):r.train_deaths+=1
		r.lives-=1;r.deaths+=1;rescore(r);actor.stop_and_hide();r.state="out" if r.lives<=0 else "respawning";r.respawn=world.config.hit_reset_seconds
		session.send_hurt(id,r.deaths,cause,actor.position)
		session.broadcast_event(String(r.name)+" "+description+(" · OUT" if r.lives<=0 else ""),r.lives<=0)
		return
func arrive(id: int, cell: Vector2i) -> void:
	if not session.is_host() or not running or session.expired() or session.phase!="racing" or not racers.has(id):return
	var r: Dictionary=racers[id]
	if r.state!="active":return
	r.ack=r.active_seq
	if sites.has(cell) and not r.collected.has(cell):
		r.collected[cell]=true
		if sites[cell].kind=="coin":
			var value: int=int(sites[cell].get("value",1))
			var amount: int=r.powers.multiplier()*value
			if value==3:r.risk_coins+=1
			r.coins+=amount;rescore(r)
		else:r.powers.activate(sites[cell].power)
	
	if cell.y!=world.config.goal_row or not can_enter(id,cell):return
	reset_commands(r)
	r.occupied[cell.x]=true;r.actor.stop_and_hide()
	if r.occupied.size()==config.required_crossings:
		r.state="finishing";r.finish=maxf(0,session.server_now()-session.start_at);r.remaining=maxf(0,session.selected_match_time-r.finish);pending_finish.append(id)
	else:r.state="respawning";r.respawn=world.config.destination_reset_seconds;r.furthest=0
	rescore(r)
func rescore(r: Dictionary) -> void:
	r.score=LanMatchRules.score(r.occupied.size(),r.coins,r.deaths,r.remaining)
func resolve_finishes() -> void:
	for id in pending_finish:
		var r: Dictionary=racers[id]
		if r.state!="finishing":continue
		r.state="finished";rescore(r)
		session.broadcast_event("%s FINISHED!  5/5"%r.name,true)
	pending_finish.clear()
	for row: Dictionary in rows():
		if row.safe==5:racers[row.peer].rank=row.rank
func rows() -> Array:
	var result: Array=[]
	for id in racers:
		var r: Dictionary=racers[id]
		result.append({"peer":id,"id":r.id,"name":r.name,"rank":r.rank,"status":r.state,"time":r.finish,"score":r.score,"coins":r.coins,"safe":r.occupied.size(),"deaths":r.deaths,"water_deaths":r.get("water_deaths",0),"train_deaths":r.get("train_deaths",0),"risk_coins":r.get("risk_coins",0),"remaining":r.remaining,"timed_out":session.expired(),"reward_coins":r.coins+(config.completion_coins if r.occupied.size()==5 else 0)})
	return LanMatchRules.ranked(result,session.selected_ranking_mode)
func freeze() -> void:
	world.set_active(false)
	replica.prediction.clear()
	for r: Dictionary in racers.values():
		if r.actor==null:continue
		reset_commands(r);r.actor.enabled=false;r.actor.set_physics_process(false);r.support.set_physics_process(false)
func expire_match() -> void:
	if not session.is_host() or session.phase!="racing":return
	resolve_finishes()
	for r: Dictionary in racers.values():
		if r.state in ["active","respawning"]:r.state="time_up"
	freeze();session.time_up()
func _physics_process(delta: float) -> void:
	if racers.is_empty():return
	if session.phase=="time_up":
		if session.is_host() and session.now()>=session.results_at:session.finish(rows())
		return
	if session.phase=="racing" and session.expired():
		if session.is_host():expire_match()
		else:freeze()
		return
	if session.phase=="racing" and not running:begin()
	if session.phase!="racing":return
	elapsed=maxf(0,session.server_now()-session.start_at)
	if session.is_host():
		var scale:=1.0
		for id: int in racers:
			var r: Dictionary=racers[id]
			if not session.members.get(id,{}).get("connected",false) and r.state not in ["finished","out","disconnected"]:r.state="disconnected";r.actor.stop_and_hide()
			r.powers.tick(delta);scale=minf(scale,r.powers.traffic_scale());r.actor.set_shield_visual(r.powers.active.has("shield"))
			if r.state=="respawning":
				r.respawn-=delta
				if r.respawn<=0:r.actor.reset_to_spawn();r.state="active";r.generation+=1
		for r: Dictionary in racers.values():
			apply_commands(r)
			var event: String=r.dog.tick(delta,r.actor,world.layout.section_at(r.actor.cell.y),config.dog,r.state=="active")
			if event=="hit":damage(r.actor,"was caught by a dog",false,"dog")
			r.dog_state=r.dog.snapshot()
		world.set_traffic_scale(scale) # Shared world: Slow Traffic benefits all racers.
		resolve_finishes()
		var done:=session.can_finalize(rows())
		snapshot_left-=delta
		if snapshot_left<=0:
			snapshot_left=1.0/session.settings.snapshot_hz
			for id: int in racers:
				if id==1 or not session.members.get(id,{}).get("connected",false):continue
				var data:=replica.capture(racers,elapsed,id)
				var fingerprint:=hash([data.players,data.owner])
				if state_hashes.get(id,-1)!=fingerprint or elapsed-last_state_time>=1:
					session.send_snapshot(data,id);state_hashes[id]=fingerprint
			if elapsed-last_state_time>=1:last_state_time=elapsed
		replica.hazards.capture(delta,elapsed)
		if done:freeze();session.finish(rows())
	else:replica.prediction.tick()
	update_local_visuals()
func update_local_visuals() -> void:
	if not racers.has(session.local_id()):return
	var local: Dictionary=racers[session.local_id()]
	for col: int in world.goals:
		var goal: DestinationZone=world.goals[col]
		var occupied: bool=local.occupied.has(col)
		if goal.occupied!=occupied:goal.set_occupied(occupied);goal.character_texture=world.player.art.texture if occupied else null
	for cell: Vector2i in world.rewards.pickups.keys():
		if local.collected.has(cell) and not local_taken.has(cell):
			local_taken[cell]=true
			var pickup:=world.rewards.take(cell)
			Audio.play_cue("coin" if pickup!=null and pickup.kind=="coin" else "ui")
func _snapshot(data: Dictionary) -> void:
	if session.is_host():return
	replica.receive(data,racers,session.local_id());elapsed=float(data.get("time",elapsed));update_local_visuals()
