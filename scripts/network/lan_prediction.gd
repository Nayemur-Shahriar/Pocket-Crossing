class_name LanPrediction
extends RefCounted
## Only the owning client's actor is predicted. Authority remains on the host.
var actor: CrossingPlayer
var support: WaterSupport
var session: LanSession
var pending: Array[Dictionary]=[]
var latest: Dictionary={}
var generation:=-1
var corrections:=0
var queued:=Vector2i.ZERO
var sequence:=0
func setup(player: CrossingPlayer, water: WaterSupport, link: LanSession) -> void:
	actor=player;support=water;session=link;clear()
func clear() -> void:
	pending.clear();latest.clear();generation=0;queued=Vector2i.ZERO;sequence=0
func request(direction: Vector2i) -> void:
	if actor==null or not actor.enabled or absi(direction.x)+absi(direction.y)!=1:return
	if actor.moving:queued=direction;return
	if pending.size()>=8:return # Bounded prediction during a stalled connection.
	actor.request_step(direction)
	if not actor.moving:return
	sequence=session.send_direction(direction,generation)
	pending.append({"seq":sequence,"cell":actor.cell})
func receive(state: Dictionary) -> void:
	latest=state
	var changed:=generation!=int(state.generation)
	generation=int(state.generation)
	if changed:
		pending.clear();queued=Vector2i.ZERO
		actor.stop_and_hide();support.clear_support()
		actor.cell=state.cell;actor.position=state.p;actor.visible=state.visible
		actor.enabled=state.visible and state.active
		actor.invulnerable_left=state.protection;actor.art.position.y=-5;actor.art.rotation=0
		return
	while not pending.is_empty() and int(pending[0].seq)<=int(state.ack):pending.pop_front()
func tick() -> void:
	if actor==null or latest.is_empty() or actor.moving:return
	if pending.is_empty() and not latest.moving and actor.enabled:
		# Reconcile once at a hop boundary, never chase every in-flight snapshot.
		var position: Vector2=latest.p
		if latest.get("water_row",-1)>=0 and support.lanes.has(int(latest.water_row)):
			var lane: WaterLane=support.lanes[int(latest.water_row)]
			var at:=int(latest.get("platform",-1))
			if at>=0 and at<lane.platforms.size():position.x=lane.platforms[at].position.x+float(latest.deck_offset)
		if actor.cell!=latest.cell or actor.position.distance_to(position)>12:
			actor.cell=latest.cell;actor.position=position;support.check_landing();corrections+=1
		latest.moving=true # Do not repeatedly apply a consumed ground correction.
	if queued!=Vector2i.ZERO and actor.enabled:
		var direction:=queued;queued=Vector2i.ZERO;request(direction)
