extends Node
var game: ModeGame
var host:=false
var number:=0
var passed:=0
var failed:=0
var rounds:=0
var expiry_count:=0
var prepare_count:=0
var records: Array=[]
var seen_rules: Dictionary={}
var done:=false
func check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS ",label)
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:
	var args:=OS.get_cmdline_user_args();host=args[0]=="host";number=int(args[1])
	Profiles.storage_path="user://competitive.cfg"
	game=preload("res://scenes/main.tscn").instantiate();game.name="PocketCrossing";add_child(game)
	Account.create("Player_"+str(number));game.friends=true
	game.session.changed.connect(changed);game.session.results_received.connect(result_received)
	game.session.prepare_match.connect(func(_id: String,_roster: Dictionary,_seed: int) -> void:prepare_count+=1)
	check(game.session.host(Account.identity())==OK if host else game.session.join("127.0.0.1",Account.identity())==OK,"connect")
	get_tree().create_timer(100).timeout.connect(func() -> void:check(false,"timeout");finish())
	if host:await start_round()
func start_round() -> void:
	while game.session.members.size()<4 or not game.session.can_start():await get_tree().process_frame
	var revision:=game.session.revision;var seed_value:=game.session.seed_value;var loads:=prepare_count
	for duration in LanMatchRules.DURATIONS:
		for mode in LanMatchRules.MODES:
			game.session.select_rules(duration,mode)
			await get_tree().create_timer(0.08).timeout
	check(game.session.revision==revision and game.session.seed_value==seed_value and prepare_count==loads and game.session.can_start(),"settings preserve map and readiness")
	game.session.select_rules(60,"time" if rounds==0 else "score")
	await get_tree().create_timer(0.2).timeout
	game.session.request_start()
func changed() -> void:
	if not host and game.session.phase=="lobby":
		var duration:=game.session.selected_match_time;var mode:=game.session.selected_ranking_mode
		seen_rules[str(duration)+mode]=true
		game.session.select_rules(90,"score" if mode=="time" else "time")
		check(game.session.selected_match_time==duration and game.session.selected_ranking_mode==mode,"guest cannot change rules")
	if game.session.phase=="countdown":
		if not host:check(seen_rules.size()==8,"all eight setting combinations replicated")
		check(game.session.selected_match_time==60 and game.session.selected_ranking_mode==("time" if rounds==0 else "score"),"authoritative settings received")
		check(game.session.start_at-game.session.server_now()>4.5,"five second countdown")
	if game.session.phase=="racing":exercise.call_deferred()
	if game.session.phase=="time_up":
		expiry_count+=1
		check(game.session.remaining()==0 and not game.controls.enabled and not game.world.player.enabled,"expiry freezes controls")
		if host:
			var before:=game.race.rows();var r: Dictionary=game.race.racers[1]
			game.race.arrive(1,Vector2i(game.world.goals.keys()[0],game.world.config.goal_row))
			game.race.damage(r.actor,"late hit",false);game.session.send_direction(Vector2i.UP);game.race.expire_match()
			check(game.race.rows()==before,"late events and repeated expiry ignored")
func exercise() -> void:
	check(absf(game.session.remaining()-60)<0.3,"same host-derived GO timer")
	await get_tree().create_timer(0.4).timeout
	if not host:
		game.session.finish([]);check(game.session.phase=="racing","guest cannot finalize")
		return
	game.session.select_rules(150,"score" if rounds==0 else "time")
	check(game.session.selected_match_time==60 and game.session.selected_ranking_mode==("time" if rounds==0 else "score"),"settings locked during race")
	var ids:=game.race.racers.keys();ids.sort()
	for i in range(ids.size()):
		var r: Dictionary=game.race.racers[ids[i]]
		r.actor.invulnerable_left=0
		game.race.damage(r.actor,"fixture death",false);game.race.damage(r.actor,"duplicate",false)
		check(r.deaths==1,"one penalty per death")
		r.state="active";r.actor.reset_to_spawn()
		var coin:=Vector2i(0,0);game.race.sites[coin]={"kind":"coin","power":null}
		game.race.arrive(ids[i],coin);game.race.arrive(ids[i],coin)
		check(r.coins==1,"coin once")
		var safe: int=(4-i if rounds==0 else 5)
		var col_index:=0
		for col in game.world.goals:
			if col_index>=safe:break
			r.state="active";game.race.arrive(ids[i],Vector2i(col,game.world.config.goal_row));col_index+=1
		if rounds==1:
			var before: int=r.occupied.size();game.race.arrive(ids[i],Vector2i(0,game.world.config.goal_row));check(r.occupied.size()==before and r.state=="finishing","no sixth crossing")
		else:
			# Keep fixture players in their safe start zone through a real 60-second match.
			r.actor.reset_to_spawn();r.state="active";r.actor.invulnerable_left=100
	if rounds==0:
		await get_tree().create_timer(30).timeout
		check(absf(game.session.remaining()-29.6)<1,"real countdown halfway")
func result_received(rows: Array,receipt: String) -> void:
	check(rows.size()==4 and receipt==game.session.match_id,"host results")
	for row: Dictionary in rows:
		check(row.score==LanMatchRules.score(row.safe,row.coins,row.deaths,row.remaining),"host exact score")
	check(rows==LanMatchRules.ranked(rows,game.session.selected_ranking_mode),"host ranking")
	check(game.session.result_awards==LanMatchRules.awards(rows),"host awards")
	check(expiry_count==(1 if rounds==0 else 1),"expiry once across rounds")
	check(Profiles.best_time(game.session.map_id)==0,"local best unchanged")
	records.append({"rows":rows.duplicate(true),"awards":game.session.result_awards.duplicate(true)})
	rounds+=1
	await get_tree().create_timer(0.5).timeout
	if rounds==1:
		if host:game.session.return_lobby();await start_round()
	else:finish()
func finish() -> void:
	if done:return
	done=true
	FileAccess.open("user://competitive_results.json",FileAccess.WRITE).store_string(JSON.stringify({"records":records,"passed":passed,"failed":failed}))
	game.leave_friends();print("RESULT ",passed," passed / ",failed," failed");get_tree().quit(failed)
