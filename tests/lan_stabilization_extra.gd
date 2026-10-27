extends Node
class Link extends LanSession:
	func send_direction(_direction: Vector2i,_generation: int=-1) -> int:
		input_sequence+=1;return input_sequence
var game: ModeGame
var passed:=0
var failed:=0
func check(value: bool,label: String) -> void:
	if value:passed+=1;print("PASS ",label)
	else:failed+=1;push_error("FAIL "+label)
func click(text: String) -> void:
	await get_tree().process_frame
	var button: Button
	for node in game.ui.root.find_children("*","Button",true,false):
		if node.text==text and node.is_visible_in_tree():button=node;break
	if button==null:check(false,"button missing "+text);return
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.position=button.get_global_transform_with_canvas()*(button.size/2);event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		get_viewport().push_input(event,true);await get_tree().process_frame
func back() -> void:
	game.navigation.last_back=-1000
	for down in [true,false]:
		var event:=InputEventKey.new();event.physical_keycode=KEY_ESCAPE;event.keycode=KEY_ESCAPE;event.pressed=down
		get_viewport().push_input(event,true);await get_tree().process_frame
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/m1461_screenshots")
	get_viewport().get_texture().get_image().save_png("res://docs/m1461_screenshots/"+label+".png")
func owner(actor: CrossingPlayer, ack: int=0, generation: int=0) -> Dictionary:
	return {"p":actor.position,"cell":actor.cell,"moving":false,"visible":true,"active":true,"ack":ack,"generation":generation,"protection":0.0}
func _ready() -> void:
	get_tree().create_timer(30).timeout.connect(func():get_tree().quit(1))
	Profiles.storage_path="user://stabilization_extra.cfg"
	game=preload("res://scenes/main.tscn").instantiate();add_child(game);Account.create("Extra_Tester");SaveData.sound_enabled=false
	game._action("modes","");await shot("home");await click("EXIT GAME")
	check(game.navigation.modal=="exit","Exit button pointer hit");await shot("exit_confirmation");await click("CANCEL")
	check(game.navigation.modal.is_empty(),"Cancel button pointer hit")
	await click("FRIENDS PLAY");await click("JOIN GAME");await click("ENTER HOST IP");await back()
	check(game.ui.page=="scan","manual IP Back hierarchy");await back();check(game.ui.page=="friends" and game.session.peer==null,"discovery cleanup")
	await click("HOST GAME");await click("SELECT MAP");check(game.ui.page=="lan_maps","Select Map pointer hit");await shot("locked_maps");await back()
	for id in Profiles.MAP_IDS:Profiles.profiles[Profiles.active_key].maps[id]=true
	for id in Profiles.MAP_IDS:
		await click("SELECT MAP");var button:=game.ui.overlay.get_node("MapChoice_"+id) as Button;await click(button.text)
		check(game.session.map_id==id and game.ui.page=="lobby","pointer selects "+id)
	await click("SELECT MAP");await shot("unlocked_maps");await back();await back()
	check(game.navigation.modal=="leave_lobby","single Escape confirmation");await back();check(game.session.peer!=null and game.navigation.modal.is_empty(),"Escape cancels confirmation")
	game.session.phase="racing";game.ui.page="race";game.ui.hide_screen();await back();await shot("host_leave_confirmation")
	check(game.navigation.modal=="leave_match","match leave confirmation");await click("END MATCH")
	check(game.session.peer==null and game.race.racers.is_empty(),"host cleanup")
	game._action("local","");game.select_level(0);await get_tree().physics_frame;await back();check(game.state==game.State.PAUSED,"Escape pauses once");await back();check(game.state==game.State.PLAYING,"Escape resumes once")
	game.world.set_active(false);var actor:=game.world.player;actor.reset_to_spawn();actor.set_physics_process(false)
	var link:=Link.new();var prediction:=LanPrediction.new();prediction.setup(actor,game.world.water_support,link);prediction.receive(owner(actor))
	var origin:=actor.position;prediction.request(Vector2i.RIGHT);actor._physics_process(0.016);check(actor.position.x>origin.x,"prediction without host reply")
	prediction.request(Vector2i.LEFT);prediction.request(Vector2i.LEFT);check(link.input_sequence==1,"one buffered direction")
	actor._physics_process(1);prediction.tick();check(link.input_sequence==2 and actor.moving,"buffer begins at hop boundary");actor._physics_process(1)
	prediction.receive(owner(actor,2));prediction.tick();check(prediction.pending.is_empty(),"ack clears pending")
	for i in range(8):prediction.request(Vector2i.RIGHT if i%2==0 else Vector2i.LEFT);actor._physics_process(1)
	prediction.request(Vector2i.RIGHT);check(prediction.pending.size()==8 and not actor.moving,"bounded stalled queue")
	var state:=owner(actor,link.input_sequence);actor.position.x+=60;prediction.receive(state);prediction.tick();check(actor.position==state.p,"authority correction at boundary")
	prediction.request(Vector2i.RIGHT);state.ack=link.input_sequence;prediction.receive(state);prediction.tick();check(actor.moving,"no mid-hop correction")
	state.generation=1;state.visible=false;state.active=false;prediction.receive(state);check(not actor.enabled and not actor.visible and prediction.pending.is_empty(),"death resets prediction")
	state.generation=2;state.visible=true;state.active=true;prediction.receive(state);check(actor.enabled and actor.visible,"respawn restores actor")
	link.free();game._action("modes","");await click("EXIT GAME")
	print("EXTRA RESULT: ",passed," passed, ",failed," failed");quit_by_button.call_deferred()
func quit_by_button() -> void:
	if failed:get_tree().quit(failed);return
	for node in game.ui.confirmation_layer.find_children("*","Button",true,false):
		if node.text!="EXIT":continue
		for down in [true,false]:
			var event:=InputEventMouseButton.new();event.position=node.get_global_transform_with_canvas()*(node.size/2);event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;get_viewport().push_input(event,true)
		return
