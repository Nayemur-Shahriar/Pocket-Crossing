extends Node
var game: ModeGame
var host:=false
var number:=0
var passed:=0
var failed:=0
var frames:=0
var last_positions: Dictionary={}
var max_step:=0.0
var observed_active:=false
var result_seen:=false
var peak_vehicles:=0
var frame_times: Array[float]=[]
func _process(delta: float) -> void:
	if game!=null and game.session.phase=="racing":frame_times.append(delta*1000)
var done:=false
func check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:
	var args:=OS.get_cmdline_user_args();host=args[0]=="host";number=int(args[1])
	Profiles.storage_path="user://stability_peer.cfg"
	game=load("res://scenes/main.tscn").instantiate();game.name="PocketCrossing";add_child(game)
	Account.create("Stable_"+str(number));game.friends=true
	game.session.changed.connect(func():
		if game.session.phase=="racing":exercise.call_deferred())
	game.session.results_received.connect(results)
	check(game.session.host(Account.identity())==OK if host else game.session.join("127.0.0.1",Account.identity())==OK,"connect")
	get_tree().create_timer(45).timeout.connect(func():check(false,"timeout");finish())
	if host:
		while game.session.members.size()<3 or not game.session.can_start():await get_tree().process_frame
		game.session.request_start()
func _physics_process(_delta: float) -> void:
	if game==null or done or game.session.phase!="racing":return
	frames+=1
	var statuses:=game.race.racers.values()
	var finished:=0;var active:=0
	for r in statuses:
		if r.state=="finished":finished+=1
		if r.state in ["active","respawning"]:active+=1
	if finished==2 and active==1:observed_active=true
	if not host:
		peak_vehicles=maxi(peak_vehicles,game.race.replica.hazards.vehicles.size())
		for id in game.race.replica.hazards.vehicles:
			var v: TrafficVehicle=game.race.replica.hazards.vehicles[id]
			if last_positions.has(id):max_step=maxf(max_step,absf(v.position.x-float(last_positions[id])))
			last_positions[id]=v.position.x
func exercise() -> void:
	await get_tree().create_timer(.3).timeout
	if not host:return
	var racers:=game.race.racers.values()
	for i in range(2):
		for col in game.world.goals:
			racers[i].state="active";game.race.arrive(racers[i].peer,Vector2i(col,game.world.config.goal_row))
	game.race.resolve_finishes()
	# Must not accept premature results even if a caller asks directly.
	game.session.finish(game.race.rows())
	check(game.session.phase=="racing","result entry rejects last active")
	var last: Dictionary=racers[2];last.actor.invulnerable_left=30
	await get_tree().create_timer(8).timeout
	check(game.session.phase=="racing" and last.state=="active","last racer continues for eight seconds")
	check(racers[0].state=="finished" and racers[1].state=="finished","finishers remain waiting")
	for col in game.world.goals:
		last.state="active";game.race.arrive(last.peer,Vector2i(col,game.world.config.goal_row))
func results(rows: Array,_receipt: String) -> void:
	if result_seen:return
	result_seen=true
	check(observed_active,"observed two finished and one still racing")
	check(rows.size()==3,"three final participants")
	for row in rows:check(row.status=="finished","all finish before results")
	check(frames>300,"continuous simulation")
	if not host:
		check(last_positions.size()>0,"client reconstructs vehicles")
		check(max_step<30,"bounded per-tick vehicle corrections")
	await get_tree().create_timer(.4).timeout
	finish()
func finish() -> void:
	if done:return
	done=true;game.leave_friends();game.queue_free();await get_tree().process_frame
	Audio.music.stop()
	for voice in Audio.voices:voice.stop();voice.stream=null
	await get_tree().create_timer(.3).timeout
	frame_times.sort()
	print("CLIENT_PROFILE frames=%d peak_vehicles=%d p95_frame_ms=%.2f"%[frame_times.size(),peak_vehicles,frame_times[int(frame_times.size()*.95)] if not frame_times.is_empty() else 0.0])
	print("STABILITY PEER %d: %d passed, %d failed; max_vehicle_step=%.2f"%[number,passed,failed,max_step]);get_tree().quit(failed)
