extends Node
var game: ModeGame
var host:=false
var started:=false
var rounds:=0
var old_match:=""
var failed:=0
var passed:=0
func check(value: bool,label: String) -> void:
	if value:passed+=1;print("PASS ",label)
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:
	host=OS.get_cmdline_user_args()[0]=="host";Profiles.storage_path="user://replay_tests.cfg"
	game=preload("res://scenes/main.tscn").instantiate();game.name="PocketCrossing";add_child(game)
	Account.create("Replay_Host" if host else "Replay_Guest");game._action("friends","")
	game.session.changed.connect(changed);game.session.results_received.connect(results);game.session.closed.connect(closed)
	if host:game._action("host","")
	else:game._action("connect","127.0.0.1")
	get_tree().create_timer(35).timeout.connect(func():check(false,"timeout");finish())
func _process(_delta: float) -> void:
	if host and not started and game.session.can_start():started=true;game._action("start","")
func changed() -> void:
	if game.session.phase!="racing":return
	check(game.session.map_id=="village_crossing","same map replay");check(game.session.match_id!=old_match,"fresh epoch");old_match=game.session.match_id
	check(game.race.replica.hazards.water.is_empty(),"no stale water anchors")
	if host:complete.call_deferred()
func complete() -> void:
	await get_tree().create_timer(0.5).timeout
	for id in game.race.racers:
		for col in game.world.goals:game.race.racers[id].state="active";game.race.arrive(id,Vector2i(col,game.world.config.goal_row))
func results(_rows: Array,_receipt: String) -> void:
	rounds+=1;await get_tree().create_timer(0.5).timeout
	if rounds==1:
		if host:game._action("replay","")
	elif host:
		game.navigation.last_back=-1000;game.navigation.back();check(game.navigation.modal=="leave_match","host results confirmation");game.navigation.accept()
		check(game.session.peer==null and game.race.racers.is_empty(),"confirmed host cleanup");await get_tree().create_timer(1).timeout;finish()
func closed(reason: String) -> void:
	if host or reason.is_empty():return
	check(rounds==2 and game.session.peer==null and game.ui.page=="friends","guest notified and cleaned");finish.call_deferred()
func finish() -> void:
	game.leave_friends();print("REPLAY RESULT: ",passed," passed, ",failed," failed");get_tree().quit.call_deferred(failed)
