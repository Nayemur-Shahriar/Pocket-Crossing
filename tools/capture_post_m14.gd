extends Node2D
## Run Current Scene: rendered developer QA, isolated profile, exits after 2-minute soak.
var game: CrossingGame
var gallery := false
var gallery_time := 0.0
var largest := 0
var effect: ResultCelebration
var frame_count := 0
var frames_during_soak := 0
var max_nodes := 0
func _ready() -> void: run.call_deferred()
func _process(delta: float) -> void:
	frame_count+=1
	if is_instance_valid(effect):
		largest=maxi(largest,effect.bursts.size())
		max_nodes=maxi(max_nodes,get_tree().get_node_count())
	if gallery:
		gallery_time+=delta
		queue_redraw()
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/post_m14_"+name+".png")
func settle() -> void:
	for i in range(5): await get_tree().process_frame
func run() -> void:
	SaveData.storage_path="user://post_m14_render.cfg"
	SaveData.load_profile()
	SaveData.sound_enabled=false
	game=load("res://scenes/legacy_main.tscn").instantiate()
	add_child(game)
	for item in game.CAMPAIGN.levels: SaveData.completed_levels[item.level_id]=true
	SaveData.level_stars[game.CAMPAIGN.levels[0].level_id]=3
	game.show_menu()
	await settle()
	await shot("menu")
	var scroll: LevelListScroll=game.hud.overlay.find_child("LevelScroll",true,false)
	scroll.scroll_vertical=1200
	await settle()
	await shot("menu_bottom")
	for index in [0,1,4,5,6,12]:
		game.select_level(index)
		game.set_physics_process(false)
		game.world.set_active(false)
		var world:=game.world
		world.player.cell=Vector2i(8,world.config.goal_row-1)
		world.player.position=world.config.cell_position(world.player.cell)
		world.camera.snap_to_player()
		world.activation.refresh(true)
		world.terrain.refresh()
		world.decorations.refresh(true)
		await settle()
		await shot("destination_"+world.config.environment.profile_id)
	for direction in [-1,1]:
		game.select_level(6)
		game.set_physics_process(false)
		game.world.set_active(false)
		var lane:=game.world.water_lanes[0]
		var deck:=lane.platforms[0]
		deck.position.x=1260 if direction>0 else 20
		deck.motion_x=0
		game.world.player.cell=Vector2i(17 if direction>0 else 0,lane.row)
		game.world.player.position=Vector2(deck.position.x,game.world.config.cell_position(game.world.player.cell).y)
		game.world.player.invulnerable_left=0
		game.world.water_support.check_landing()
		game.world.camera.snap_to_player()
		game.world.activation.refresh(true)
		game.world.terrain.refresh()
		game.world.decorations.refresh(true)
		await settle()
		await shot("water_edge_"+str(direction))
	# Actual textures at game scale and enlarged, both directions; no gameplay overrides.
	game.world.hide()
	game.world.camera.enabled=false
	game.hud.visible=false
	gallery=true
	queue_redraw()
	await settle()
	await shot("vehicles")
	gallery=false
	game.world.show()
	game.world.camera.enabled=true
	game.hud.visible=true
	game.select_level(0)
	game.world.set_active(false)
	game.set_physics_process(false)
	SaveData.level_scores[game.world.config.level_id]=100
	game.score=2000
	game.finish_game(true,"render fixture genuine previous-best comparison")
	effect=game.hud.result_panel.celebration
	effect.set_process(false)
	effect._process(0.1)
	effect._process(0.68)
	await shot("rockets")
	effect._process(0.95)
	await shot("explosions")
	if OS.get_cmdline_user_args().has("--quick"):
		print("POST M14 QUICK VISUAL: captured menu, six destinations, edges, vehicles and rockets")
		game.queue_free()
		await settle()
		get_tree().quit()
		return
	var start:=Time.get_ticks_msec()
	frames_during_soak=frame_count
	var nodes:=get_tree().get_node_count()
	effect.set_process(true)
	await get_tree().create_timer(120.0).timeout
	print("POST M14 RENDER SOAK seconds=",(Time.get_ticks_msec()-start)/1000.0," frames=",frame_count-frames_during_soak," max_rockets=",largest," nodes_start=",nodes," max_nodes=",max_nodes," waves=",effect.waves," explosions=",effect.emitted)
	var ok:=largest<=3 and nodes==get_tree().get_node_count() and effect.waves>25
	game.hud.result_panel.select_button.pressed.emit()
	ok=ok and effect.finished and effect.bursts.is_empty()
	await settle()
	await shot("clean_menu")
	print("POST M14 RENDER RESULT: ","PASS" if ok else "FAIL")
	game.queue_free()
	await settle()
	get_tree().quit(0 if ok else 1)
func _draw() -> void:
	if not gallery: return
	draw_rect(Rect2(0,0,1280,720),Color("18343f"))
	draw_string(ThemeDB.fallback_font,Vector2(80,65),"ORIGINAL VEHICLE ART / GAME SCALE + DETAIL",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("f2dfad"))
	for i in range(2):
		var name: String=["rickshaw","cng"][i]
		var texture: Texture2D=load("res://assets/vehicles/"+name+".svg")
		var y:=150.0+i*280
		draw_string(ThemeDB.fallback_font,Vector2(80,y),name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("f2dfad"))
		for direction in [-1,1]:
			var x:=300.0 if direction>0 else 160.0
			draw_set_transform(Vector2(x,y+60),0,Vector2(direction,1))
			draw_texture_rect(texture,Rect2(-58,-29,116,58),false)
			draw_set_transform(Vector2.ZERO)
		draw_texture_rect(texture,Rect2(580,y-5,464,232),false)
		var visual: VehicleVisualConfig=load("res://resources/vehicles/"+name+".tres")
		var points:=visual.collision_outline.duplicate()
		for j in range(points.size()): points[j]=Vector2(812,y+111)+points[j]*4
		points.append(points[0])
		draw_polyline(points,Color(1,0.8,0.3,0.7),1,true)
