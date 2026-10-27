extends Node
## Real ENet peers; controlled host fixtures exercise outcomes after real movement.
var game: ModeGame
var count:=2
var number:=0
var host:=true
var soak:=0
var passed:=0
var failed:=0
var rounds:=0
var snapshots:=0
var roads_seen:=false
var water_seen:=false
var train_seen:=false
var selected:=false
var due:=0.0
var frozen:=Vector2.ZERO
var results: Array=[]
var finished:=false
var node_min:=0
var node_max:=0
func check(value: bool,label: String) -> void:
	if value:passed+=1;print("PASS ",label)
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:
	var args:=OS.get_cmdline_user_args()
	host=args[0]=="host";count=int(args[1]);number=int(args[2]);soak=int(args[3]) if args.size()>3 else 0
	Profiles.storage_path="user://peer_test_%d.cfg"%number
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=preload("res://scenes/main.tscn").instantiate();game.name="PocketCrossing";add_child(game)
	check(Account.create("Host_User" if host else "Guest_%d"%number).is_empty(),"create isolated account")
	if host:
		for id in Profiles.MAP_IDS:Profiles.profiles[Profiles.active_key].maps[id]=true
		Profiles.save_active()
	game.ui.mode_menu();await shot("menu")
	game._action("settings","");await shot("settings")
	game._action("friends","");await shot("friends")
	game.session.changed.connect(changed)
	game.session.results_received.connect(result_received)
	game.session.snapshot_received.connect(snapshot)
	game.session.hazards_received.connect(hazard_snapshot)
	check(game.session.host(Account.identity())==OK if host else game.session.join("127.0.0.1",Account.identity())==OK,"host bind" if host else "client connect")
	get_tree().create_timer(125+soak).timeout.connect(func() -> void:check(false,"timeout");finish())
func _process(_delta: float) -> void:
	if finished or game==null or not host:return
	if game.session.phase=="lobby" and game.session.members.size()==count and game.session.can_start():
		if not selected:
			selected=true;game.session.select_map(Profiles.MAP_IDS[rounds]);due=game.session.now()+0.35
			check(not game.session.can_start(),"map clears stale readiness")
		elif game.session.now()>due:
			if soak>0:game.session.select_rules(150,"time")
			game.session.request_start()
func changed() -> void:
	if game.session.phase=="lobby":shot("lobby")
	if game.session.phase=="countdown":
		frozen=game.world.player.position
		check(game.session.start_at-game.session.server_now()>4.5,"future countdown")
		game.session.send_direction(Vector2i.UP)
		shot("countdown")
	if game.session.phase=="racing":
		check(game.world.player.position.distance_to(frozen)<1,"no early movement")
		check(absf(game.session.server_now()-game.session.start_at)<0.3,"synchronized GO")
		exercise.call_deferred()
func snapshot(data: Dictionary) -> void:
	snapshots+=1
	if snapshots==1:
		check(data.players.size()==count,"all logical players replicated")
		check(data.has("owner"),"only recipient physical correction")
		for value: Dictionary in data.players.values():check(not value.has("p") and not value.has("hop"),"no remote transforms")
func hazard_snapshot(data: Dictionary) -> void:
	roads_seen=roads_seen or not data.roads.is_empty()
	water_seen=water_seen or not data.water.is_empty()
	for train: Array in data.trains:train_seen=train_seen or int(train[1])!=0
func exercise() -> void:
	await get_tree().create_timer(0.25).timeout
	var x:=game.world.player.position.x
	game._on_direction(Vector2i.RIGHT)
	await get_tree().create_timer(0.5).timeout
	check(game.world.player.position.x>x+20,"predicted/authoritative hop")
	var rendered:=0;var total_actors:=0
	for actor in game.world.find_children("*","CrossingPlayer",true,false):
		total_actors+=1
		if actor.is_visible_in_tree():rendered+=1
	check(rendered==1,"only own actor rendered")
	check(total_actors==(count if host else 1),"no client remote actor nodes")
	game.toggle_pause();var elapsed:=game.race.elapsed
	await get_tree().create_timer(0.25).timeout
	check(not get_tree().paused and game.race.elapsed>elapsed,"local pause continues race")
	game.toggle_pause()
	game.controls._touch_id=123;game._process(0.016)
	check(game.controls._touch_id==123,"swipe survives render frame");game.controls.reset_gestures()
	await shot("race_"+game.session.map_id)
	if not host:return
	var ids:=game.race.racers.keys();ids.sort()
	var a: Dictionary=game.race.racers[ids[0]]
	var b: Dictionary=game.race.racers[ids[1]]
	var seq:=game.session.sequences.duplicate()
	game.session.validate_command(1,"stale",9000,Vector2i.UP)
	game.session.validate_command(1,game.session.match_id,999999,Vector2i.UP)
	game.session.validate_command(1,game.session.match_id,3,Vector2i(2,0))
	check(game.session.sequences==seq,"invalid client commands ignored")
	var lives: int=a.lives;var other_lives: int=b.lives
	a.actor.invulnerable_left=0;a.powers.activate(preload("res://resources/powerups/shield.tres"))
	game.race.damage(a.actor,"test shield",false)
	check(a.lives==lives and not a.powers.active.has("shield"),"shield consumes one hit")
	a.actor.invulnerable_left=0;game.race.damage(a.actor,"was hit by traffic",false)
	check(a.lives==lives-1 and b.lives==other_lives,"independent life loss")
	await get_tree().create_timer(1.5).timeout
	check(a.state=="active" and a.actor.visible,"respawn")
	var coin:=Vector2i(0,0);game.race.sites[coin]={"kind":"coin","power":null}
	for id in ids:
		game.race.arrive(id,coin);game.race.arrive(id,coin)
		check(game.race.racers[id].coins==1,"independent once-only coin")
	var goal:=Vector2i(game.world.goals.keys()[0],game.world.config.goal_row)
	for id in ids:game.race.arrive(id,goal)
	await get_tree().create_timer(0.8).timeout
	for id in ids:
		game.race.arrive(id,goal)
		check(game.race.racers[id].occupied.size()==1,"independent destination no double count")
	if rounds==2:
		var lane:=game.world.water_lanes[0];var platform:=lane.platforms[1]
		for r: Dictionary in [a,b]:
			r.actor.position=Vector2(platform.position.x,lane.position.y);r.actor.cell.y=lane.row;r.support.check_landing()
		var before: float=a.actor.position.x
		await get_tree().create_timer(0.12).timeout
		check(absf(a.actor.position.x-before)>1 and platform.carrying_player,"shared boat carries racers")
		a.actor.reset_to_spawn();check(platform.carrying_player,"one rider leaves without releasing other")
		b.actor.reset_to_spawn()
		if soak>0:
			node_min=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT));node_max=node_min
			for i in range(soak):
				await get_tree().create_timer(1).timeout
				var nodes:=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT));node_min=mini(node_min,nodes);node_max=maxi(node_max,nodes)
			check(node_max-node_min<100,"bounded nodes during soak")
	await get_tree().create_timer(2).timeout
	fixture_finish(ids[0])
	await get_tree().create_timer(0.2).timeout
	check(a.rank==1 and game.session.phase=="racing","first finisher does not stop others")
	for i in range(1,ids.size()):fixture_finish(ids[i])
func fixture_finish(id: int) -> void:
	for col in game.world.goals:
		if not game.race.racers[id].occupied.has(col):
			game.race.racers[id].state="active";game.race.arrive(id,Vector2i(col,game.world.config.goal_row))
func result_received(rows: Array,receipt: String) -> void:
	results.append(rows.duplicate(true));await shot("results_"+game.session.map_id)
	check(rows.size()==count,"all results")
	for i in range(rows.size()):check(rows[i].rank==i+1,"ordered unique rank")
	var wallet:=SaveData.coins
	for row: Dictionary in rows:
		if row.peer==game.session.local_id():Account.award_match(receipt,game.session.map_id,row.coins,row.time)
	check(SaveData.coins==wallet,"results reward once")
	check(Profiles.best_time(game.session.map_id)==0,"Local Best unchanged")
	if not host and rounds>0:check(not Profiles.is_unlocked(game.session.map_id),"guest locked map remains locked")
	rounds+=1;selected=false
	await get_tree().create_timer(0.6).timeout
	if rounds<4:
		if host:game.session.return_lobby()
	else:
		if not host:check(snapshots>20 and roads_seen and water_seen and train_seen,"road train water snapshots")
		finish()
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	for i in range(3):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/lan_"+label+".png")
func finish() -> void:
	if finished:return
	finished=true
	var packet_bytes:=game.session.max_packet_bytes
	game.leave_friends();await get_tree().process_frame
	check(game.session.peer==null and game.race.racers.is_empty() and game.race.replica.vehicles.is_empty(),"network cleanup")
	game._action("local","");game.select_level(0);await get_tree().physics_frame
	check(game.state==game.State.PLAYING and game.world.player.enabled and not game.world.player.has_node("LanName"),"Local Play after LAN")
	var file:=FileAccess.open("user://peer_results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"results":results,"passed":passed,"failed":failed,"snapshots":snapshots,"max_compressed_bytes":packet_bytes,"soak_node_min":node_min,"soak_node_max":node_max}));file.close()
	print("RESULT ",passed," passed / ",failed," failed");get_tree().quit(failed)
