class_name LanHazards
extends Node
## Reliable spawn/state changes plus sparse repair anchors; local smooth motion.
var world: RoadLevel
var session: LanSession
var vehicles: Dictionary={}
var roads: Dictionary={}
var trains: Dictionary={}
var water: Dictionary={}
var previous_roads: Dictionary={}
var previous_trains: Dictionary={}
var previous_water: Dictionary={}
var correction_left:=0.0
var last_full:=-1.0
var frame_count:=0
var visual_errors: Dictionary={}
func setup(view: RoadLevel, link: LanSession) -> void:
	world=view;session=link;process_physics_priority=-25
	session.hazards_received.connect(receive)
func clear() -> void:
	for vehicle in vehicles.values():
		if is_instance_valid(vehicle):vehicle.queue_free()
	vehicles.clear();visual_errors.clear();roads.clear();trains.clear();water.clear();previous_roads.clear();previous_trains.clear();previous_water.clear();correction_left=0;last_full=-1
func capture(delta: float, elapsed: float) -> void:
	correction_left-=delta
	var full:=correction_left<=0
	if full:correction_left=1.0/session.settings.hazard_correction_hz
	var message:={"at":elapsed,"full":full,"roads":[],"removed":[],"trains":[],"water":[]}
	var now_roads: Dictionary={}
	for i in range(world.lanes.size()):
		for v: TrafficVehicle in world.lanes[i].get_children():
			if v.is_queued_for_deletion():continue
			var id:=v.get_instance_id();now_roads[id]=v.speed
			if full or not previous_roads.has(id) or absf(float(previous_roads[id])-v.speed)>10.0:message.roads.append([id,i,v.vehicle_type,v.position.x,v.speed,v.direction,v.paint])
	for id in previous_roads:
		if not now_roads.has(id):message.removed.append(id)
	previous_roads=now_roads
	var index:=0
	for railway in world.railways:
		for track in railway.tracks:
			var key:=Vector2(track.state,track.effect_scale)
			if full or previous_trains.get(index,Vector2(-1,-1))!=key:message.trains.append([index,track.state,track.remaining,track.elapsed,track.train.position.x,track.train.running,track.config.speed*track.effect_scale*track.config.direction])
			previous_trains[index]=key;index+=1
	for i in range(world.water_lanes.size()):
		var lane:=world.water_lanes[i];var positions: Array=[];var wrapped:=false
		for k in range(lane.platforms.size()):
			positions.append(lane.platforms[k].position.x)
			if previous_water.has(i) and absf(float(previous_water[i][k])-lane.platforms[k].position.x)>100:wrapped=true
		if full or wrapped or not previous_water.has(i):message.water.append([i,lane.elapsed,positions])
		previous_water[i]=positions
	if full or not message.roads.is_empty() or not message.removed.is_empty() or not message.trains.is_empty() or not message.water.is_empty():session.send_hazards(message,not full)
func receive(data: Dictionary) -> void:
	if session.is_host():return
	var at: float=data.at
	if at<last_full:return
	frame_count+=1
	if data.full:
		last_full=at
		var seen: Dictionary={}
		for item: Array in data.roads:seen[item[0]]=true
		for id in roads.keys():
			if not seen.has(id) and float(roads[id].at)<=at:remove_vehicle(id)
	for id in data.removed:remove_vehicle(id)
	for item: Array in data.roads:
		var id: int=item[0]
		if roads.has(id) and float(roads[id].at)>at:continue
		var target:=float(item[3])+float(item[4])*int(item[5])*clampf(session.server_now()-session.start_at-at,0,2)
		if not vehicles.has(id):
			var v: TrafficVehicle=TrafficLane.VEHICLE_SCENE.instantiate();v.vehicle_type=item[2];v.direction=item[5];v.paint=item[6]
			v.speed=item[4];v.position=Vector2(target,0);v.set_physics_process(false);v.monitoring=false;v.collision_layer=0;v.collision_mask=0
			world.lanes[item[1]].add_child(v);v.set_physics_process(false);v.reset_physics_interpolation();v.apply_theme(world.presentation.theme);vehicles[id]=v
			visual_errors[id]=0.0
		else:
			var error: float=vehicles[id].position.x-target
			visual_errors[id]=error if absf(error)<180 else 0.0
		roads[id]={"at":at,"x":item[3],"velocity":float(item[4])*int(item[5])}
	for item: Array in data.trains:
		if not trains.has(item[0]) or float(trains[item[0]].at)<=at:trains[item[0]]={"at":at,"data":item}
	for item: Array in data.water:
		if not water.has(item[0]) or float(water[item[0]].at)<=at:water[item[0]]={"at":at,"data":item}
func remove_vehicle(id: int) -> void:
	if vehicles.has(id):vehicles[id].queue_free();vehicles.erase(id)
	roads.erase(id);visual_errors.erase(id)
func _physics_process(delta: float) -> void:
	if session==null or session.is_host() or session.phase!="racing":return
	var elapsed:=maxf(0,session.server_now()-session.start_at)
	for id in roads:
		var anchor: Dictionary=roads[id]
		visual_errors[id]=float(visual_errors.get(id,0))*exp(-12.0*delta)
		vehicles[id].position.x=float(anchor.x)+float(anchor.velocity)*clampf(elapsed-float(anchor.at),0,2)+float(visual_errors[id])
	var index:=0
	for railway in world.railways:
		for track in railway.tracks:
			if trains.has(index):
				var anchor: Dictionary=trains[index];var item: Array=anchor.data;var dt:=clampf(elapsed-float(anchor.at),0,2)
				track.state=item[1];track.remaining=maxf(0,float(item[2])-dt);track.elapsed=float(item[3])+dt
				track.train.running=item[5];track.train.visible=item[5];track.train.monitoring=false
				track.train.position.x=float(item[4])+(float(item[6])*dt if item[5] else 0.0)
				track.signal_art.update_state(track.state,track.state!=0 and fmod(track.elapsed,0.6)<0.3)
			index+=1
	for i in water:
		var lane: WaterLane=world.water_lanes[i];var anchor: Dictionary=water[i];var item: Array=anchor.data
		var dt:=clampf(elapsed-float(anchor.at),0,2);var begin: float=item[1];var w:=TAU/lane.config.variation_period
		var distance:=lane.config.platform_speed*(dt+lane.config.speed_variation*(cos(w*begin)-cos(w*(begin+dt)))/w)*lane.config.direction
		lane.elapsed=begin+dt
		for k in range(lane.platforms.size()):
			var platform:=lane.platforms[k];var x:=float(item[2][k])+distance
			platform.motion_x=x-platform.position.x if absf(x-platform.position.x)<100 else 0.0
			platform.position.x=x
		lane.queue_redraw()
