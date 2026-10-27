extends Node
var passed:=0
var failed:=0
var game: MapGame
func _ready() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:
		failed+=1
		push_error("FAIL "+label)
func clean(path: String) -> void:
	for suffix in ["",".bak",".tmp",".unreadable"]:DirAccess.remove_absolute(path+suffix)
func frames(n: int=3) -> void:
	for i in range(n):await get_tree().process_frame
func run() -> void:
	SaveData.storage_path="user://map_legacy_test.cfg"
	Profiles.storage_path="user://map_campaign_test.cfg"
	clean(SaveData.storage_path)
	clean(Profiles.storage_path)
	SaveData.load_profile()
	SaveData.coins=250
	SaveData.selected_character="mint"
	SaveData.sound_enabled=false
	SaveData.completed_levels={"old":true}
	SaveData.level_scores={"old":1234}
	check(SaveData.save(),"legacy fixture saved")
	var legacy:=FileAccess.get_file_as_string(SaveData.storage_path)
	game=load("res://scenes/m145_main.tscn").instantiate()
	add_child(game)
	await frames()
	check(game.state==CrossingGame.State.MENU and game.map_hud.profile_name!=null,"launch player chooser")
	check(not SaveData.save() and FileAccess.get_file_as_string(SaveData.storage_path)==legacy,"no legacy write before player chosen")
	for name in ["ab","abcdefghijklmnopq","has space","éclair","bad!name"]:check(not Profiles.create_profile(name).is_empty(),"reject "+name)
	check(Profiles.create_profile("  Alice_1  ").is_empty(),"trim valid username")
	check(Profiles.active_key=="alice_1" and Profiles.profiles.alice_1.username=="Alice_1","case normalization display preservation")
	check(not Profiles.create_profile("ALICE_1").is_empty(),"case-insensitive duplicate")
	check(SaveData.coins==250 and SaveData.selected_character=="mint" and not SaveData.sound_enabled,"migrate wallet skin settings")
	check(Profiles.profiles.alice_1.legacy.scores.old==1234 and Profiles.best_time("village_crossing")==0,"archive old scores not new times")
	var catalog: LevelCatalog=load("res://resources/maps/catalog.tres")
	check(catalog.levels.size()==4,"exactly four maps")
	var arrangements: Array=[]
	for map: MapConfig in catalog.levels:
		check(map.map_errors().is_empty(),"valid "+map.level_id+str(map.map_errors()))
		var compiled:=map.compile_layout().config
		check(compiled.goal_columns.size()==5,"five goals "+map.level_id)
		check(not arrangements.has(compiled.goal_columns),"unique destination arrangement")
		arrangements.append(compiled.goal_columns)
	check(Profiles.is_unlocked("village_crossing") and not Profiles.is_unlocked("city_rush"),"only village initially")
	check(Profiles.purchase(catalog.levels[3]).is_empty(),"buy night without previous maps")
	check(SaveData.coins==95 and Profiles.is_unlocked("night_express"),"purchase exact debit")
	check(Profiles.purchase(catalog.levels[3]).is_empty() and SaveData.coins==95,"double purchase no debit")
	check(not Profiles.purchase(catalog.levels[2]).is_empty() and SaveData.coins==95,"insufficient funds no mutation")
	var storage:=Profiles.storage_path
	Profiles.storage_path="user://absent_parent/map.cfg"
	check(not Profiles.purchase(catalog.levels[1]).is_empty() and SaveData.coins==95 and not Profiles.is_unlocked("city_rush"),"failed purchase rolled back")
	Profiles.storage_path=storage
	check(Profiles.complete_map(catalog.levels[0],80.0),"first time stored")
	check(Profiles.complete_map(catalog.levels[0],90.0) and Profiles.best_time("village_crossing")==80,"slower does not overwrite")
	check(Profiles.complete_map(catalog.levels[0],70.0) and Profiles.best_time("village_crossing")==70,"faster overwrites")
	check(not Profiles.complete_map(catalog.levels[0],NAN),"reject invalid time")
	var wallet:=SaveData.coins
	Profiles.storage_path="user://absent_parent/map.cfg"
	check(not Profiles.complete_map(catalog.levels[0],50.0) and Profiles.best_time("village_crossing")==70 and SaveData.coins==wallet,"failed completion rollback")
	Profiles.storage_path=storage
	check(Profiles.create_profile("Bob").is_empty() and SaveData.coins==0 and not Profiles.is_unlocked("night_express") and Profiles.best_time("village_crossing")==0,"independent second player")
	check(Profiles.select_profile("ALICE_1") and SaveData.coins==wallet and Profiles.is_unlocked("night_express"),"switch restores player")
	check(SaveData.choose_character("coral"),"character purchase with profile adapter")
	wallet=SaveData.coins
	check(Profiles.select_profile("bob") and not SaveData.unlocked_characters.has("coral"),"skin ownership isolated")
	check(Profiles.select_profile("alice_1") and SaveData.selected_character=="coral","selected purchased skin restored")
	Profiles.load_profiles()
	check(Profiles.active_key=="alice_1" and SaveData.coins==wallet,"reload persists profiles")
	check(FileAccess.get_file_as_string(SaveData.storage_path)==legacy,"legacy bytes unchanged")
	game.show_menu()
	await frames()
	check(game.hud.overlay.find_children("Map_*","Button",true,false).size()==4,"four card actions")
	check(game.hud.overlay.find_children("*","ScrollContainer",true,false).is_empty(),"no map scrollbar")
	game.hud.show_characters()
	await frames()
	var skin: Button=game.hud.overlay.find_child("Skin_pip",true,false)
	var tap_position:=skin.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventScreenTouch.new()
		event.index=3
		event.position=tap_position
		event.pressed=pressed
		get_viewport().push_input(event,true)
	check(SaveData.selected_character=="pip","nested character button receives touch tap")
	game.select_level(0)
	game.set_physics_process(false)
	game.world.set_active(false)
	check(game.state==CrossingGame.State.PLAYING,"map starts")
	var coin_cell:=Vector2i.ZERO
	for cell: Vector2i in game.world.rewards.pickups:
		if game.world.rewards.pickups[cell].kind=="coin" and game.world.rewards.pickups[cell].coin_value==1:
			coin_cell=cell
			break
	var before_coins:=SaveData.coins
	game._collect_reward(coin_cell)
	check(SaveData.coins==before_coins+1 and game.run_coins==1,"pickup saved immediately")
	game._collect_reward(coin_cell)
	check(SaveData.coins==before_coins+1,"same pickup cannot pay twice")
	game.powers.activate(load("res://resources/powerups/shield.tres"))
	game.world.player.invulnerable_left=0
	game._on_collision(game.world.player)
	check(game.lives==3 and not game.powers.active.has("shield"),"shield shares collision path")
	var lanes_before:=game.world.lanes.duplicate()
	var rewards_before:=game.world.rewards.pickups.size()
	game._physics_process(2)
	check(game.elapsed_seconds==2,"elapsed timer")
	game.toggle_pause()
	game._physics_process(5)
	check(game.elapsed_seconds==2,"pause freezes timer")
	game.toggle_pause()
	game.world.set_active(false)
	var goals:=game.world.config.goal_columns.duplicate()
	for i in range(5):
		game._on_step_completed(Vector2i(goals[i],game.world.config.goal_row))
		check(game.destinations_reached==i+1,"claim unique goal")
		check(not game.world.can_enter_cell(Vector2i(goals[i],game.world.config.goal_row)),"occupied goal blocks reentry")
		if i<4:
			check(game.state==CrossingGame.State.RESPAWNING,"next character delay")
			var at:=game.elapsed_seconds
			game._physics_process(0.6)
			check(game.elapsed_seconds>at and game.state==CrossingGame.State.PLAYING,"timer continues success respawn")
			check(game.world.lanes==lanes_before and game.world.rewards.pickups.size()==rewards_before,"success preserves hazards and collected pickups")
			game.world.set_active(false)
			game._on_step_completed(Vector2i(goals[i],game.world.config.goal_row))
			check(game.destinations_reached==i+1,"occupied cannot increment")
			if i==1:
				game.world.player.invulnerable_left=0
				game._on_collision(game.world.player)
				check(game.lives==2 and game.destinations_reached==2,"death preserves progress")
				game._physics_process(2)
				game.world.set_active(false)
	check(game.state==CrossingGame.State.LEVEL_COMPLETE and game.new_best_time,"fifth completion new record")
	check(is_instance_valid(game.map_hud.map_celebration),"record fireworks")
	var effect:=game.map_hud.map_celebration
	effect.set_process(false)
	var max_bursts:=0
	for frame in range(7200):
		effect._process(1.0/60)
		max_bursts=maxi(max_bursts,effect.bursts.size())
	check(effect.waves>20 and max_bursts<=36 and effect.get_child_count()==1,"two minute simulated rocket soak remains bounded")
	game.map_hud.map_result.hide()
	check(effect.finished and effect.bursts.is_empty(),"hidden result stops rockets immediately")
	wallet=SaveData.coins
	game.finish_game(true,"")
	check(SaveData.coins==wallet,"completion awarded once")
	game.start_run(42)
	game.world.set_active(false)
	check(game.elapsed_seconds==0 and game.destinations_reached==0 and game.lives==3,"retry reset")
	for goal: DestinationZone in game.world.goals.values():check(not goal.occupied,"retry clears goal")
	check(game.map_hud.map_celebration==null,"retry cleans rockets")
	check(game.world.rewards.pickups.has(coin_cell) and SaveData.coins==wallet,"retry restores pickups without granting coins")
	game.elapsed_seconds=100
	game.destinations_reached=5
	game.finish_game(true,"")
	check(not game.new_best_time and game.map_hud.map_celebration==null,"slower completion no fireworks")
	game.start_run()
	game.elapsed_seconds=Profiles.best_time(game.current_map.level_id)
	game.destinations_reached=5
	game.finish_game(true,"")
	check(not game.new_best_time and game.map_hud.map_celebration==null,"equal completion no fireworks")
	game.start_run()
	game.finish_game(false,"")
	check(game.map_hud.map_celebration==null,"failure no fireworks")
	game.show_menu()
	check(game.state==CrossingGame.State.MENU and not game.world.presentation.visible,"menu cleanup")
	check(FileAccess.get_file_as_string(SaveData.storage_path)==legacy,"all gameplay keeps legacy bytes")
	Profiles.save_active()
	var file:=FileAccess.open(storage,FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	Profiles.load_profiles()
	check(Profiles.profiles.size()==2 and not Profiles.recovery_notice.is_empty(),"corruption backup recovery")
	for suffix in ["",".bak"]:
		var broken:=FileAccess.open(storage+suffix,FileAccess.WRITE)
		broken.store_string("")
		broken.close()
	Profiles.load_profiles()
	check(Profiles.profiles.is_empty() and not Profiles.migration_pending,"empty corrupt pair safe fallback")
	check(Profiles.create_profile("Recovered").is_empty() and SaveData.coins==0,"recovery does not mint legacy coins again")
	check(FileAccess.file_exists(storage+".unreadable"),"keeps corrupted primary")
	var original: Dictionary=Profiles.profiles.duplicate(true)
	for pair in [["coins",-1],["coins","bad"],["maps",{"bad":true}],["characters",{"pip":1}],["selected","missing"],["times",{"village_crossing":-5}],["times",{"unknown":20}],["sound",1]]:
		Profiles.profiles=original.duplicate(true)
		Profiles.profiles.recovered[pair[0]]=pair[1]
		check(not Profiles._write(),"reject invalid save field "+pair[0])
	Profiles.profiles=original
	game.queue_free()
	await frames()
	print("MAP CAMPAIGN RESULTS: %d passed, %d failed"%[passed,failed])
	get_tree().quit(1 if failed else 0)
