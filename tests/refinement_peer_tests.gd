extends Node
var game: ModeGame
var host:=false
var number:=0
var passed:=0
var failed:=0
var warning_seen:=false
var running_seen:=false
var dog_messages:=0
var hurt_causes: Array[String]=[]
var cues: Array[String]=[]
var done:=false
func check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:
	var args:=OS.get_cmdline_user_args();host=args[0]=="host";number=int(args[1])
	Profiles.storage_path="user://refinement_peer.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=load("res://scenes/main.tscn").instantiate();game.name="PocketCrossing";add_child(game)
	Account.create("Refine_"+str(number));SaveData.coins=1000;SaveData.choose_character("elder_woman" if number==1 else "pip");SaveData.sound_enabled=true
	game.friends=true
	game.session.local_hurt.connect(func(cause: String,_at: Vector2):hurt_causes.append(cause))
	Audio.cue_played.connect(func(cue: String):
		if cue in ["dog_bark","dog_catch","water_entry"] or cue.begins_with("impact_"):cues.append(cue))
	game.session.notice.connect(func(message: String,_priority: bool):
		if message.contains("was caught by a dog"):dog_messages+=1)
	game.session.changed.connect(func():
		if game.session.phase=="racing":exercise.call_deferred())
	game.session.results_received.connect(results)
	check(game.session.host(Account.identity())==OK if host else game.session.join("127.0.0.1",Account.identity())==OK,"connect")
	get_tree().create_timer(35).timeout.connect(func():check(false,"timeout");finish())
	if host:
		while game.session.members.size()<4 or not game.session.can_start():await get_tree().process_frame
		game.session.request_start()
func _process(_delta: float) -> void:
	if game==null or done:return
	warning_seen=warning_seen or game.dog_view.phase=="warning"
	running_seen=running_seen or game.dog_view.phase=="running"
func exercise() -> void:
	await get_tree().create_timer(0.3).timeout
	check(game.world.player.art.texture==load(CharacterCatalog.find_skin("elder_woman" if number==1 else "pip").texture),"own selected skin")
	if not host:return
	var victim: Dictionary={}
	for r: Dictionary in game.race.racers.values():
		if r.name=="Refine_1":victim=r
	var row:=0
	for section in game.world.layout.sections:
		if section.kind==LevelSectionConfig.Kind.SAFE_SECTION:row=section.first_row;break
	victim.actor.cell=Vector2i(8,row);victim.actor.position=game.world.config.cell_position(victim.actor.cell);victim.actor.invulnerable_left=0
	while victim.deaths==0:await get_tree().process_frame
	check(victim.deaths==1 and victim.lives==2,"authoritative stationary dog takes one life")
	game.race.damage(victim.actor,"was caught by a dog",false,"dog")
	game.session.send_hurt(victim.peer,1,"dog",victim.actor.position)
	check(victim.deaths==1,"duplicate damage guarded")
	await get_tree().create_timer(0.5).timeout
	victim.actor.reset_to_spawn(0);victim.state="active"
	game.race._water_hit(victim.actor);game.race._water_hit(victim.actor)
	check(victim.deaths==2 and victim.water_deaths==1,"one authoritative water death")
	await get_tree().create_timer(0.5).timeout
	for r: Dictionary in game.race.racers.values():
		for col in game.world.goals:
			r.state="active";game.race.arrive(r.peer,Vector2i(col,game.world.config.goal_row))
	game.race.resolve_finishes();game.race.freeze();game.session.finish(game.race.rows())
func results(rows: Array,_receipt: String) -> void:
	await get_tree().create_timer(0.2).timeout
	check(dog_messages==1,"one dog feed message on every peer")
	check(hurt_causes==(["dog","water"] if number==1 else []),"reliable own-only cause delivery/dedup")
	check(cues==(["dog_bark","dog_catch","water_entry"] if number==1 else []),"own-only full hazard audio; no remote spam")
	check(warning_seen==(number==1) and running_seen==(number==1),"only victim renders warning and chase")
	var actors:=game.world.find_children("*","CrossingPlayer",true,false)
	check(actors.size()==(4 if host else 1),"remote client actors not created")
	check(game.world.find_children("*","DogView",true,false).size()==1,"one local dog view")
	check(rows.size()==4 and rows==LanMatchRules.ranked(rows,game.session.selected_ranking_mode),"ranking unchanged")
	for row in rows:check(row.score==LanMatchRules.score(row.safe,row.coins,row.deaths,row.remaining),"score formula preserved")
	check(game.dog_view.phase=="idle","result cleanup")
	finish()
func finish() -> void:
	if done:return
	done=true
	game.leave_friends();game.queue_free();await get_tree().process_frame
	Audio.music.stop()
	for voice in Audio.voices:voice.stop();voice.stream=null
	# Let the audio mixer release stopped WAV playbacks before this test exits.
	await get_tree().create_timer(0.25).timeout
	print("REFINEMENT PEER RESULTS: %d passed, %d failed"%[passed,failed]);get_tree().quit(failed)
