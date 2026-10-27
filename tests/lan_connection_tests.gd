extends Node
var game: ModeGame
var host:=true
var scenario:=""
var number:=0
var passed:=0
var failed:=0
var finished:=false
var joined:=false
var began:=0.0
var race_at:=0.0
func check(value: bool,label: String) -> void:
	if value:passed+=1;print("PASS ",label)
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:
	var args:=OS.get_cmdline_user_args();host=args[0]=="host";scenario=args[1];number=int(args[2])
	Profiles.storage_path="user://connection_%s_%d.cfg"%[scenario,number]
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=preload("res://scenes/main.tscn").instantiate();game.name="PocketCrossing";add_child(game)
	Account.create("Host_User" if host or scenario=="duplicate" else "Guest_%d"%number)
	game.friends=true;game.session.closed.connect(closed)
	if scenario=="version" and not host:game.session.settings=game.session.settings.duplicate();game.session.settings.content_revision="wrong"
	if scenario=="full" and number==4:await get_tree().create_timer(2).timeout
	if scenario=="midmatch" and number==2:await get_tree().create_timer(8).timeout
	began=Time.get_ticks_msec()/1000.0
	check(game.session.host(Account.identity())==OK if host else game.session.join("127.0.0.1",Account.identity())==OK,"open transport")
	get_tree().create_timer(25).timeout.connect(func() -> void:check(false,"timeout");finish())
func _process(_delta: float) -> void:
	if finished or game==null or began==0:return
	var elapsed:=Time.get_ticks_msec()/1000.0-began
	if host:
		joined=joined or game.session.members.size()>=2
		if scenario in ["match_disconnect","host_disconnect","midmatch"] and game.session.can_start():game.session.request_start()
		if game.session.phase=="racing" and race_at==0:race_at=elapsed
		if scenario=="lobby_disconnect" and joined and game.session.members.size()==1:check(true,"lobby departure");finish()
		if scenario=="match_disconnect" and joined:
			for id in game.session.members:
				if id!=1 and not game.session.members[id].connected and game.race.racers.get(id,{}).get("state")=="disconnected":check(true,"racer DNF");finish();return
		if scenario=="host_disconnect" and race_at>0 and elapsed-race_at>1:check(true,"close host during race");finish()
		if scenario in ["duplicate","version"] and elapsed>4:check(game.session.members.size()==1,"rejection retains host only");finish()
		if scenario=="full" and elapsed>6:check(game.session.members.size()==4,"four admitted maximum");finish()
		if scenario=="midmatch" and elapsed>12:check(game.session.members.size()==2,"midmatch roster unchanged");finish()
	else:
		if scenario=="lobby_disconnect" and game.session.phase=="lobby" and elapsed>2:check(true,"client leaves lobby");finish()
		if scenario=="match_disconnect" and game.session.phase=="racing":
			if race_at==0:race_at=elapsed
			if elapsed-race_at>1:check(true,"client leaves race");finish()
func closed(reason: String) -> void:
	if finished or reason.is_empty():return
	var expected: String="username" if scenario=="duplicate" else ("versions" if scenario=="version" else ("full" if scenario=="full" and number==4 else ("progress" if scenario=="midmatch" and number==2 else "Host disconnected")))
	check(reason.contains(expected),"correct rejection/disconnect: "+reason);finish()
func finish() -> void:
	if finished:return
	finished=true;game.leave_friends()
	check(game.session.peer==null and game.race.racers.is_empty(),"cleanup")
	print("RESULT ",passed," passed / ",failed," failed");get_tree().quit(failed)
