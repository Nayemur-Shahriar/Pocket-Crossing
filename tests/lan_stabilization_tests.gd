extends Node
var game: ModeGame
var passed:=0
var failed:=0
func check(value: bool, label: String) -> void:
	if value:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func back() -> void:game.navigation.last_back=-1000;game.navigation.back()
func _ready() -> void:
	Profiles.storage_path="user://stabilization_tests.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=preload("res://scenes/main.tscn").instantiate();game.name="PocketCrossing";add_child(game)
	Account.create("Nav_Tester");game._action("modes","")
	check(game.ui.page=="home","home")
	check(not get_tree().quit_on_go_back and not get_tree().auto_accept_quit,"central OS back/close ownership")
	back();check(game.navigation.modal=="exit","home exit confirmation")
	game.navigation.back();check(game.navigation.modal=="exit","duplicate back consumed once")
	back();check(game.navigation.modal.is_empty() and game.ui.page=="home","cancel top modal")
	game._action("settings","");back();check(game.ui.page=="home","settings back")
	game._action("local","");check(game.ui.page=="maps","map select")
	game.ui.show_characters();back();check(game.ui.page=="maps","characters back")
	back();check(game.ui.page=="home","map select back")
	game._action("friends","");game._action("join","");back();check(game.ui.page=="friends" and game.session.peer==null and game.session.discovery.socket==null,"discovery back closes socket")
	back();check(game.ui.page=="home","friends back")
	game._action("friends","");game._action("host","")
	check(game.ui.page=="lobby","host lobby")
	game._action("map_next","");check(game.ui.page=="lan_maps","explicit map list")
	for id in Profiles.MAP_IDS:
		var button:=game.ui.overlay.get_node("MapChoice_"+id) as Button
		check(button.disabled==(id!="village_crossing"),"locked map clearly disabled")
	for id in Profiles.MAP_IDS:Profiles.profiles[Profiles.active_key].maps[id]=true
	game.ui.map_picker(game.session)
	for id in Profiles.MAP_IDS:
		game.ui.map_picker(game.session)
		var button:=game.ui.overlay.get_node("MapChoice_"+id) as Button
		button.pressed.emit()
		check(game.session.map_id==id and game.race.config.level_id==id,"map button loads "+id)
	back();check(game.navigation.modal=="leave_lobby","lobby back confirmation")
	game.navigation.cancel();check(game.session.peer!=null,"cancel preserves lobby")
	back();game.navigation.accept();check(game.ui.page=="friends" and game.session.peer==null,"leave lobby cleanup")
	game._action("local","");game.select_level(0);await get_tree().physics_frame
	back();check(game.state==game.State.PAUSED and game.ui.page=="local_pause","local game back pauses")
	back();check(game.state==game.State.PLAYING,"local resume")
	game._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	# Debounce the immediately previous simulated key; then one new system press.
	game.navigation.last_back=-1000;game._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.state==game.State.PAUSED,"Android notification route")
	game._action("local_maps","");check(game.ui.page=="maps" and game.session.peer==null,"local map navigation after LAN")
	game.leave_friends();print("STABILIZATION RESULT: ",passed," passed, ",failed," failed");get_tree().quit(failed)
