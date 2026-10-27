extends Node
var game: ModeGame
var host:=false
var index:=0
var running:=false
var done:=false
var results: Array=[]
var counts: Dictionary={}
var frames:=0
var costs:=0.0
var physics_costs:=0.0
func _ready() -> void:
	var args:=OS.get_cmdline_user_args();host=args[0]=="host"
	Profiles.storage_path="user://probe.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=load("res://scenes/main.tscn").instantiate();game.name="PocketCrossing";add_child(game)
	Account.create("Host_Test" if host else "Guest_Test")
	for id in Profiles.MAP_IDS:Profiles.profiles[Profiles.active_key].maps[id]=true
	game.friends=true;game.session.changed.connect(changed);game.session.snapshot_received.connect(snapshot)
	if game.session.has_signal("hazards_received"):game.session.connect("hazards_received",hazards)
	if host:game.session.host(Account.identity())
	else:game.session.join("127.0.0.1",Account.identity())
	get_tree().create_timer(100).timeout.connect(func() -> void:finish(1))
func _process(_delta: float) -> void:
	if done or game==null:return
	if running:frames+=1;costs+=Performance.get_monitor(Performance.TIME_PROCESS);physics_costs+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	if host and game.session.can_start():
		if game.session.map_id!=Profiles.MAP_IDS[index]:game.session.select_map(Profiles.MAP_IDS[index])
		else:game.session.request_start()
func changed() -> void:
	if game.session.phase=="racing" and not running:measure.call_deferred()
func snapshot(data: Dictionary) -> void:
	if not running:return
	counts.state_rpc+=1;counts.bytes+=var_to_bytes(data).compress(FileAccess.COMPRESSION_DEFLATE).size()
	for item: Dictionary in data.get("players",{}).values():
		if item.has("p"):counts.transforms+=1
	if data.has("owner"):counts.owner_updates+=1
	counts.roads+=data.get("roads",[]).size();counts.trains+=data.get("trains",[]).size()
	for lane: Array in data.get("water",[]):counts.boats+=lane[2].size()
func hazards(data: Dictionary) -> void:
	if not running:return
	counts.hazard_rpc+=1;counts.bytes+=var_to_bytes(data).compress(FileAccess.COMPRESSION_DEFLATE).size()
	counts.roads+=data.get("roads",[]).size();counts.trains+=data.get("trains",[]).size()
	for lane: Array in data.get("water",[]):counts.boats+=lane[2].size()
func measure() -> void:
	running=true;frames=0;costs=0;physics_costs=0
	counts={"map":game.session.map_id,"state_rpc":0,"hazard_rpc":0,"bytes":0,"transforms":0,"owner_updates":0,"roads":0,"trains":0,"boats":0}
	var began:=Time.get_ticks_msec()
	await get_tree().create_timer(0.25).timeout
	var before:=game.world.player.position;var at:=Time.get_ticks_usec();game._on_direction(Vector2i.RIGHT)
	while game.world.player.position.distance_to(before)<0.1 and Time.get_ticks_usec()-at<1000000:await get_tree().process_frame
	counts.input_ms=(Time.get_ticks_usec()-at)/1000.0
	await get_tree().create_timer(0.5).timeout
	if not host:
		get_tree().multiplayer_poll=false;before=game.world.player.position;game._on_direction(Vector2i.LEFT)
		await get_tree().create_timer(0.2).timeout
		counts.moves_without_reply=game.world.player.position.distance_to(before)>10
		get_tree().multiplayer_poll=true
	await get_tree().create_timer(6).timeout
	counts.seconds=(Time.get_ticks_msec()-began)/1000.0;counts.fps=frames/counts.seconds
	counts.process_ms=costs/maxi(1,frames)*1000;counts.physics_ms=physics_costs/maxi(1,frames)*1000
	counts.nodes=Performance.get_monitor(Performance.OBJECT_NODE_COUNT);counts.rtt_ms=game.session.best_rtt*1000 if is_finite(game.session.best_rtt) else 0
	counts.actors=0;counts.sync_nodes=0
	for node in game.find_children("*","",true,false):
		if node is CrossingPlayer:counts.actors+=1
		if node is MultiplayerSynchronizer or node is MultiplayerSpawner:counts.sync_nodes+=1
	results.append(counts.duplicate(true));running=false;index+=1
	await get_tree().create_timer(0.6 if host else 0.1).timeout
	if index==4:finish(0)
	elif host:game.session.return_lobby()
func finish(code: int) -> void:
	if done:return
	done=true;get_tree().multiplayer_poll=true
	var f:=FileAccess.open("user://profile.json",FileAccess.WRITE);f.store_string(JSON.stringify(results));f.close()
	game.leave_friends();get_tree().quit.call_deferred(code)
