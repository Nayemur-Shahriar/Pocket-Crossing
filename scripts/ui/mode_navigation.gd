class_name ModeNavigation
extends RefCounted
## One owner for system Back, Escape, modal cancellation and final shutdown.
var game: Node
var modal:=""
var previous_page:=""
var last_back:=-1000
var quitting:=false
func _init(owner: Node) -> void:game=owner
func back() -> void:
	if is_instance_valid(game.ui.scene_fade) and game.ui.scene_fade.busy:
		if game.ui.scene_fade.stage < 2:game.ui.scene_fade.cancel()
		return
	var now:=Time.get_ticks_msec()
	if now-last_back<160:return
	last_back=now
	if not modal.is_empty():cancel();return
	match game.ui.page:
		"home","welcome":confirm("exit")
		"settings","maps","friends","challenges":game._action("modes","")
		"characters":game.show_menu()
		"scan","connecting":game._action("friends","")
		"manual":game._action("join","")
		"lan_maps":game.ui.lobby(game.session)
		"lobby":confirm("leave_lobby")
		"race","race_pause","race_results":confirm("leave_match")
		"local_pause":game.resume_local()
		"local_result":game.show_menu()
		_:
			if game.friends:confirm("leave_match")
			elif game.state in [game.State.PLAYING,game.State.RESPAWNING]:game.pause_local()
			else:game._action("modes","")
func confirm(kind: String) -> void:
	if quitting:return
	modal=kind;previous_page=game.ui.page
	game.menu_open=true;game.controls.set_enabled(false)
	var title:="EXIT POCKET CROSSING?";var detail:="Your saved progress will be kept.";var accept:="EXIT"
	if kind=="leave_lobby":
		title="CLOSE LOBBY?" if game.session.is_host() else "LEAVE LOBBY?";detail="Closing this lobby disconnects everyone." if game.session.is_host() else "Return to Friends Play.";accept="LEAVE"
	elif kind=="leave_match":
		title="END MATCH?" if game.session.is_host() else "LEAVE MATCH?"
		detail="LEAVING WILL END THE MATCH FOR EVERYONE." if game.session.is_host() else "Leave this race and return to Friends Play?"
		accept="END MATCH" if game.session.is_host() else "LEAVE"
	game.ui.confirmation(title,detail,accept)
func cancel() -> void:
	modal="";game.ui.close_confirmation();game.menu_open=previous_page=="race_pause"
	game.controls.set_enabled(game.session.phase=="racing" and not game.menu_open if game.friends else game.state==game.State.PLAYING)
func accept() -> void:
	var kind:=modal;modal="";game.ui.close_confirmation()
	if kind=="exit":shutdown();return
	game.leave_friends();game.friends=true;game.ui.friends_menu()
func shutdown() -> void:
	if quitting:return
	quitting=true;game.controls.set_enabled(false)
	game.leave_friends();game.world.set_active(false);game.world.decorations.set_running(false,false)
	Profiles.save_active();game.get_tree().quit()
