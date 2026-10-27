extends Node
var passed:=0
var failed:=0
var game: ModeGame
func check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:run.call_deferred()
func stop() -> void:game.set_physics_process(false);game.world.set_active(false)
func run() -> void:
	Profiles.storage_path="user://m148_depth.cfg";SaveData.storage_path="user://m148_legacy.cfg"
	for path in [Profiles.storage_path,SaveData.storage_path]:
		for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	check(Account.create("Depth_Tester").is_empty(),"account create")
	SaveData.coins=1000;SaveData.sound_enabled=false

	var phased:=TrafficLane.new();var lane:=LaneConfig.new()
	lane.pattern="waves";lane.cycle_seconds=16;lane.open_seconds=6;phased.config=lane;phased.active_seconds=0
	check(not phased.spawning_allowed(),"phase zero begins with no new traffic")
	lane.phase_offset=8;check(phased.spawning_allowed(),"opposite phase begins busy")
	phased.active_seconds=8;check(not phased.spawning_allowed(),"opposite phase quiet window")
	phased.free()
	var catalog:=game.CAMPAIGN
	check(catalog.levels.size()==4,"four maps retained")
	for map: MapConfig in catalog.levels:
		check(Profiles.purchase(map).is_empty(),"unlock "+map.level_id)
		check(map.map_errors().is_empty(),"valid signature "+map.level_id+str(map.map_errors()))
		check(not map.signature.is_empty(),"map signature preserved")
		var value:=0;var risk:=0;var hazard:=0;var safe:=0
		for section in map.sections:
			for pickup in section.pickups:
				if pickup.power!=null:continue
				value+=pickup.coin_value
				if pickup.coin_value==3:risk+=1
				if pickup.on_hazard:hazard+=1
				else:safe+=1
		check(risk==2 and hazard>safe,"risk distribution "+map.level_id)
		check(value==(16 if map.level_id in ["river_delta","night_express"] else 12),"bounded economy")
		for c in ChallengeCatalog.for_map(map.level_id):
			var modified:=c.apply(map)
			check(modified!=map and modified.sections[0]!=map.sections[0],"isolated resources")
			check(modified.map_errors().is_empty(),"valid variant "+map.level_id+"/"+c.challenge_id+str(modified.map_errors()))
			if c.modifier=="one_life":check(modified.starting_lives==1 and map.starting_lives==3,"one life isolated")
			if c.modifier=="fog":check(modified.presentation.weather=="Fog" and modified.presentation.fog_strength<=0.3 and modified.presentation.time_of_day==map.presentation.time_of_day,"fog preserves identity")
			if c.modifier=="double_coins":check(c.coin_multiplier()==2,"double multiplier")
			for i in range(map.sections.size()):
				var source:=map.sections[i];var section:=modified.sections[i]
				if c.modifier=="rush":
					for j in range(source.road_lanes.size()):check(section.road_lanes[j].speed>source.road_lanes[j].speed and section.road_lanes[j].minimum_gap_seconds==source.road_lanes[j].minimum_gap_seconds,"rush preserves gaps")
				if c.modifier=="river":
					for j in range(source.water_lanes.size()):check(section.water_lanes[j].platform_speed>source.water_lanes[j].platform_speed and section.water_lanes[j].platform_length==source.water_lanes[j].platform_length,"fast river same decks")
				if c.modifier=="no_shield":
					for p in section.pickups:check(p.power==null or p.power.effect!="shield","no shield")
	var map:=catalog.levels[0] as MapConfig;var wallet:=SaveData.coins
	var storage:=Profiles.storage_path
	check(MapDepthProgress.valid({"mastery":{"bad":1}}) and not MapDepthProgress.valid({"challenges":{"bad":{"completed":true,"score":-1,"time":NAN}}}),"obsolete mastery ignored; invalid challenges rejected")
	game.select_challenge(0,"double_coins");stop()
	var risk_cell:=Vector2i.ZERO;var normal_cell:=Vector2i.ZERO
	for cell: Vector2i in game.world.rewards.pickups:
		var p: RewardPickup=game.world.rewards.pickups[cell]
		if p.kind=="coin":
			if p.coin_value==3:risk_cell=cell
			else:normal_cell=cell
	wallet=SaveData.coins;game._collect_reward(normal_cell);game._collect_reward(risk_cell);game._collect_reward(risk_cell)
	check(SaveData.coins==wallet+8 and game.run_stats.coins==8 and game.run_stats.risk_coins==1,"Double Coins 2+6 once")
	check(LanMatchRules.score(0,1,0,0)==50 and LanMatchRules.score(0,3,0,0)==150,"unchanged score formula")
	game.elapsed_seconds=90;game.destinations_reached=5;game.finish_game(true,"")
	var record:=MapDepthProgress.record(map.level_id,"double_coins")
	check(record.completed and record.time==90 and record.score==LanMatchRules.score(5,8,0,510),"separate challenge records shared formula")
	check(Profiles.best_time(map.level_id)==0,"normal time untouched")
	wallet=SaveData.coins;game.finish_game(true,"");check(SaveData.coins==wallet,"no duplicate completion")
	game.start_run(42);stop();check(game.challenge!=null and game.run_stats.coins==0 and game.destinations_reached==0,"retry reset")
	game.show_menu();check(game.ui.page=="challenges","return to challenges")
	game._action("local","");game.select_level(0);stop()
	check(game.challenge==null and game.coin_multiplier()==1 and game.lives==3 and game.current_map==map,"normal Local restored")
	game._collect_reward(risk_cell);check(game.run_stats.coins==3 and game.run_stats.risk_coins==1,"normal risk value")
	game.powers.activate(load("res://resources/powerups/shield.tres"));game.world.player.invulnerable_left=0;game._on_collision(game.world.player)
	check(game.run_stats.deaths==0 and game.lives==3,"shield not death")
	game.world.player.invulnerable_left=0;game._on_collision(game.world.player);check(game.run_stats.deaths==1 and game.lives==2,"death counted")
	game.select_challenge(0,"one_life");stop();game.world.player.invulnerable_left=0;game._on_collision(game.world.player)
	check(game.state==game.State.GAME_OVER and game.run_stats.deaths==1,"one life ends on death")
	game.select_challenge(3,"no_shield");stop()
	check(not game.world.rewards.pickups.values().any(func(p):return p.power!=null and p.power.effect=="shield"),"runtime shield absent")
	game._action("friends","");check(game.challenge==null and game.coin_multiplier()==1 and game.friends,"Friends cleanup")
	game.session.host(Account.identity())
	var roster:={1:Account.identity(),2:Account.identity()};roster[2]=roster[2].duplicate();roster[2].id="22222222222222222222222222222222"
	game.race.prepare(map.level_id,roster,42);game.session.phase="racing";game.session.start_at=game.session.now();game.race.begin();game.world.set_active(false)
	var normal:=Vector2i.ZERO;var risk:=Vector2i.ZERO
	for cell in game.race.sites:
		var site: Dictionary=game.race.sites[cell]
		if site.kind=="coin":
			if site.value==3:risk=cell
			else:normal=cell
	game.race.arrive(1,normal);game.race.arrive(1,risk);game.race.arrive(1,risk)
	check(game.race.racers[1].coins==4 and game.race.racers[1].score==200 and game.race.racers[2].coins==0,"host validates once per racer")
	game.race.arrive(2,risk)
	check(game.race.racers[2].coins==3 and game.race.racers[2].score==150 and game.race.racers[1].risk_coins==1,"independent risk collection")
	game.race.racers[1].actor.invulnerable_left=0;game.race.damage(game.race.racers[1].actor,"was hit by a train",false)
	check(game.race.racers[1].train_deaths==1 and game.race.racers[1].deaths==1,"host train stats")
	game.leave_friends();Profiles.load_profiles()
	check(MapDepthProgress.record(map.level_id,"double_coins").score==record.score,"account records persist")

	# Separate records never regress, never award mastery, and roll back on I/O failure.
	var challenge:=ChallengeCatalog.find("double_coins")
	check(MapDepthProgress.save_challenge(map,challenge,true,110,record.score-100),"slower challenge saves")
	check(MapDepthProgress.record(map.level_id,challenge.challenge_id).time==90 and MapDepthProgress.record(map.level_id,challenge.challenge_id).score==record.score,"best time and score monotonic")
	check(MapDepthProgress.save_challenge(map,challenge,false,10,10) and MapDepthProgress.record(map.level_id,challenge.challenge_id).completed,"failed run retains completed marker")
	wallet=SaveData.coins;Profiles.storage_path="user://missing_parent/depth.cfg"
	check(not MapDepthProgress.save_challenge(map,challenge,true,20,record.score+200) and SaveData.coins==wallet and MapDepthProgress.record(map.level_id,challenge.challenge_id).time==90,"challenge rollback")
	Profiles.storage_path=storage
	for index in range(4):
		game.select_challenge(index,"one_life");stop();game.pause_local()
		var elapsed:=game.elapsed_seconds;game._physics_process(5)
		check(game.elapsed_seconds==elapsed and game.state==game.State.PAUSED,"challenge pause freezes timer")
		game.resume_local();game.select_level(index);stop()
		check(game.lives==3 and game.challenge==null and game.current_map==catalog.levels[index],"all maps restore base after modifier")
	game.select_challenge(0,"double_coins");stop()
	game.powers.activate(load("res://resources/powerups/double.tres"))
	game._collect_reward(risk_cell)
	check(game.run_stats.coins==12,"risk3 x challenge2 x temporary power2")
	game._collect_reward(risk_cell);check(game.run_stats.coins==12,"stacked multiplier no duplicate")
	# Version-1 account fields remain optional; corruption uses the existing backup.
	Profiles.save_active();Profiles.save_active()
	var file:=ConfigFile.new();file.load(storage)
	var database: Dictionary=file.get_value("database","profiles")
	database[Profiles.active_key].mastery={"invalid":-1}
	file.set_value("database","profiles",database);file.save(storage)
	Profiles.load_profiles()
	check(Profiles.recovery_notice.is_empty(),"obsolete field ignored without backup or save loss")
	game.leave_friends()
	game.queue_free();await get_tree().process_frame;await get_tree().process_frame
	print("MAP DEPTH RESULTS: %d passed, %d failed"%[passed,failed]);get_tree().quit(failed)
