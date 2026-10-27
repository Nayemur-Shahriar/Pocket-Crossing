class_name ModeGame
extends MapGame
var last_countdown_cue := ""
var friends:=false
var session: LanSession
var race: LanRace
var feed:=RaceFeed.new()
var menu_open:=false
var leaving:=false
var scan_left:=0.0
var screen:=""
var race_screen:=false
var ui: ModeHUD
var auto_replay:=false
var last_lan_lives:=-1
var navigation: ModeNavigation
var last_match_second:=-1
var friends_record_token:=""
func _ready() -> void:
	ui=$HUD;navigation=ModeNavigation.new(self);super._ready()
	get_tree().auto_accept_quit=false
	session=LanSession.new();session.name="LanSession";add_child(session)
	race=LanRace.new();add_child(race);race.setup(world,session)
	session.local_hurt.connect(_local_hurt)
	session.changed.connect(_session_changed);session.closed.connect(_closed)
	session.notice.connect(feed.push);session.results_received.connect(_results);ui.action.connect(_action)
func show_profiles() -> void:
	if ui==null:ui=$HUD
	_set_state(State.MENU)
	if Account.adopt_loaded():ui.mode_menu()
	else:ui.welcome("Could not save account. Check storage." if not Profiles.profiles.is_empty() else Profiles.recovery_notice)
func _create_profile(value: String) -> void:
	var error:=Account.create(value)
	if error.is_empty():ui.mode_menu()
	else:ui.welcome(error,value)
func _action(kind: String,value: String) -> void:
	if not friends and _transition_busy():return
	match kind:
		"ambience","music":RunRecords.set_option(kind,not RunRecords.option(kind));ui.refresh_settings();return
		"vibration":SaveData.vibration_enabled=not SaveData.vibration_enabled;Profiles.save_active();ui.refresh_settings();return
		"challenges":leave_friends();ui.show_challenges(CAMPAIGN);return
		"challenge_map":ui.show_challenges(CAMPAIGN,value);return
		"challenge_play":
			var parts:=value.split("|")
			if parts.size()==2:_covered_change(func():select_challenge(int(parts[0]),parts[1]))
			return
		"back":navigation.back();return
		"exit":navigation.confirm("exit");return
		"cancel_confirm":navigation.cancel();return
		"accept_confirm":navigation.accept();return
		"map_choose":
			if session.is_host() and session.phase=="lobby":session.select_map(value);ui.lobby(session)
			return
		"local_resume":resume_local();return
		"local_retry":_covered_change(func():start_run());return
		"local_maps":show_menu();return
	match kind:
		"create":_create_profile(ui.entry.text)
		"modes":leave_friends();ui.mode_menu()
		"local":leave_friends();show_menu()
		"settings":ui.settings_screen()
		"rename":
			var error:=Account.rename_account(ui.entry.text)
			ui.settings_screen(error if not error.is_empty() else "Name saved. Your progress is unchanged.")
		"sound":toggle_sound()
		"friends":leave_friends();friends=true;screen="friends";ui.friends_menu()
		"host":
			friends=true
			if session.host(Account.identity())!=OK:ui.friends_menu("Could not host. Is another game using this port?")
		"join":friends=true;session.scan();screen="scan";ui.join_screen()
		"manual":screen="manual";ui.manual_screen()
		"connect_entry":_action("connect",ui.entry.text.strip_edges())
		"connect":
			screen="connecting"
			if session.join(value,Account.identity())!=OK:ui.friends_menu("Enter a valid Host IPv4 address.")
			else:ui.friends_menu("Connecting…");ui.page="connecting"
		"map_next":
			if session.is_host() and session.phase=="lobby":ui.map_picker(session)
		"match_time":session.select_rules(int(value),session.selected_ranking_mode)
		"ranking_mode":session.select_rules(session.selected_match_time,value)
		"start":session.request_start()
		"leave":navigation.confirm("leave_lobby" if session.phase=="lobby" else "leave_match")
		"resume":menu_open=false;ui.hide_screen();ui.page="race";controls.set_enabled(session.phase=="racing")
		"end_prompt":ui.race_pause(true,true)
		"end_confirm":session.return_lobby()
		"replay":auto_replay=true;session.return_lobby()
		"lobby":
			if session.is_host():session.return_lobby()
			else:ui.race_results(session.result_rows,false,"Waiting for host. Leave to return to your own menu.",session.selected_ranking_mode,session.result_awards,session.local_id())
func leave_friends() -> void:
	if session==null:return
	run_presentation.clear();dog_view.clear();friends_record_token=""
	clear_challenge()
	leaving=true;auto_replay=false;session.leave();race.clear()
	world.player.set_physics_process(true);world.activation.set_physics_process(true)
	ui.stop_race_ui();ui.close_confirmation();navigation.modal="";feed.clear();friends=false;menu_open=false;race_screen=false
	controls.set_enabled(false);_set_state(State.MENU);leaving=false
func _closed(reason: String) -> void:
	if leaving or reason.is_empty():return
	leave_friends();friends=true;ui.friends_menu(reason)
func _session_changed() -> void:
	if session.phase in ["lobby","loading"]:
		dog_view.clear()
		race_screen=false;menu_open=false;controls.set_enabled(false);ui.stop_race_ui()
		if ui.page!="lan_maps" or session.phase!="lobby":ui.lobby(session)
		if auto_replay and session.can_start():auto_replay=false;session.request_start()
	elif session.phase in ["countdown","racing"]:
		if not race_screen:
			dog_view.clear();run_presentation.begin(race.config)
			race_screen=true;last_match_second=-1;last_lan_lives=-1;menu_open=false;feed.clear();ui.set_level(world.config,false)
			ui.level_label.text="FRIENDS · "+LanMatchRules.mode_name(session.selected_ranking_mode);ui.start_race_ui()
		controls.set_enabled(session.phase=="racing" and not menu_open)
	elif session.phase=="time_up":
		dog_view.clear();controls.set_enabled(false);race.freeze();menu_open=false
		ui.close_confirmation();navigation.modal="";ui.hide_screen();ui.page="race"
		if is_instance_valid(ui.countdown):
			ui.countdown.text="TIME UP!";ui.countdown.add_theme_font_size_override("font_size",46);ui.countdown.visible=true
		ui.time_label.text="00:00";Audio.play_cue("time_up")
func _results(rows: Array,receipt: String) -> void:
	run_presentation.end_run();dog_view.clear()
	controls.set_enabled(false);race.freeze();menu_open=false
	ui.close_confirmation();navigation.modal=""
	var notice:="Local Best Time and map unlocks are unchanged."
	for row: Dictionary in rows:
		if int(row.peer)==session.local_id():
			RunRecords.apply("friends",session.map_id,receipt,row)
			if not Account.award_match(receipt,session.map_id,int(row.get("reward_coins",row.coins)),float(row.time)):notice="Could not save earned coins. Check storage."
	ui.race_results(rows,session.is_host(),notice,session.selected_ranking_mode,session.result_awards,session.local_id())
func _on_direction(direction: Vector2i) -> void:
	if friends:
		if not menu_open and session!=null:race.request_local(direction)
	else:super._on_direction(direction)
func _on_step_completed(cell: Vector2i) -> void:
	if not friends:super._on_step_completed(cell)
func _on_collision(actor: CrossingPlayer) -> void:
	if not friends:super._on_collision(actor)
func _on_water_hazard(actor: CrossingPlayer) -> void:
	if not friends:super._on_water_hazard(actor)
func _physics_process(delta: float) -> void:
	if not friends:super._physics_process(delta)
func _request_restart() -> void:
	if not friends and not _transition_busy():
		if state!=State.MENU:_covered_change(func():start_run())
func _on_primary() -> void:
	if not friends and not _transition_busy():
		if state==State.PAUSED:toggle_pause()
		elif state!=State.MENU:_covered_change(func():start_run())
func _on_secondary() -> void:
	if not friends:super._on_secondary()
func toggle_pause() -> void:
	if friends:
		if session.phase not in ["countdown","racing"]:navigation.back();return
		menu_open=not menu_open;controls.set_enabled(not menu_open and session.phase=="racing")
		if menu_open:ui.race_pause(session.is_host())
		else:ui.hide_screen();ui.page="race"
	else:
		if state==State.PAUSED:resume_local()
		elif state in [State.PLAYING,State.RESPAWNING]:pause_local()
		else:navigation.back()
func pause_local() -> void:
	_resume_state=state;_set_state(State.PAUSED);ui.local_pause()
func resume_local() -> void:
	ui.hide_screen();ui.page="local_game";_set_state(_resume_state)
func start_run(seed_value: int=0) -> void:
	super.start_run(seed_value)
	if ui!=null:
		ui.page="local_game"
		if _transition_busy():
			controls.set_enabled(false)
			_watch_transition()
func _input(event: InputEvent) -> void:
	if navigation!=null and event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		if not event.is_echo():navigation.back()
func _notification(what: int) -> void:
	if not is_node_ready() or navigation==null:return
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:navigation.back()
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:navigation.shutdown()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		if friends:
			if session.phase in ["countdown","racing"] and not menu_open:toggle_pause()
		elif state in [State.PLAYING,State.RESPAWNING]:pause_local()
func _process(delta: float) -> void:
	if session==null or not friends:return
	if screen=="scan" and session.phase=="discovering":
		scan_left-=delta
		if scan_left<=0:scan_left=1;ui.update_available(session.discovery.found)
	if session.phase not in ["countdown","racing"]:return
	if session.phase=="racing" and friends_record_token!=session.match_id:
		friends_record_token=session.match_id
		RunRecords.apply("friends",session.map_id,friends_record_token)
	var seconds:=session.server_now()-session.start_at
	if is_instance_valid(ui.countdown):
		ui.countdown.visible=seconds<0.7 and not menu_open
		ui.countdown.text=str(clampi(ceili(-seconds),1,5)) if seconds<0 else "GO!"
		if ui.countdown.visible and ui.countdown.text != last_countdown_cue:
			last_countdown_cue = ui.countdown.text
			Audio.play_cue("countdown" if seconds<0 else "go")
	feed.tick(delta)
	if race.racers.has(session.local_id()):
		var local: Dictionary=race.racers[session.local_id()]
		dog_view.display(local.get("dog_state",{}),delta)
		var enable_input: bool=session.phase=="racing" and not menu_open and navigation.modal.is_empty() and local.state=="active" and not session.expired()
		if controls.enabled!=enable_input:controls.set_enabled(enable_input)
		if last_lan_lives>=0 and int(local.lives)<last_lan_lives:
			ui.hit_flash(ui.root.get_global_transform_with_canvas().affine_inverse()*world.player.get_global_transform_with_canvas().origin)
		last_lan_lives=int(local.lives)
		ui.update_map_status(maxf(0,seconds),local.coins,local.lives,local.occupied.size())
		var left:=ceili(session.remaining())
		ui.time_label.text="%02d:%02d"%[left/60,left%60]
		ui.time_label.modulate=Color("ff927f") if left<=10 else Color.WHITE
		if session.phase=="racing" and left!=last_match_second:
			if left>=1 and left<=5:Audio.play_cue("countdown")
			last_match_second=left
		var parts:=PackedStringArray()
		for r: Dictionary in race.racers.values():parts.append("%s %s"%[String(r.name).left(6)+("…" if String(r.name).length()>6 else ""),"#%d"%r.rank if r.rank>0 else ("%d/5"%r.occupied.size() if r.state in ["active","respawning"] else "DNF")])
		ui.best_label.text="SCORE %d · COINS +%d  |  "%[local.score,local.coins]+" · ".join(parts)
		var caption: String=local.powers.caption() if session.is_host() else String(local.get("caption",""))
		ui.message_label.text=feed.current if not feed.current.is_empty() else ("FINISHED · WAITING FOR OTHER PLAYERS…" if local.rank>0 else (caption if not caption.is_empty() else "Five safe crossings. The race continues for everyone."))
		if session.phase=="racing" and session.remaining()<=10:ui.message_label.text="TIME RUNNING OUT!  ·  "+str(local.score)+" points"
		ui.message_label.modulate.a=minf(1,feed.left*2) if not feed.current.is_empty() else 1.0

func _local_hurt(cause: String, at: Vector2) -> void:
	HazardAudio.play(cause)
	var kind:=LevelSectionConfig.Kind.WATER_SECTION if cause=="water" else (LevelSectionConfig.Kind.RAILWAY_SECTION if cause=="train" else LevelSectionConfig.Kind.ROAD_SECTION)
	run_presentation.death(kind,at)

# Presentation guard only; no Challenge rules or authoritative LAN timing.
func _transition_busy() -> bool:
	return ui!=null and is_instance_valid(ui.scene_fade) and ui.scene_fade.busy
func _watch_transition() -> void:
	if not ui.scene_fade.finished.is_connected(_transition_finished):
		ui.scene_fade.finished.connect(_transition_finished)
func _transition_finished() -> void:
	if not friends:controls.set_enabled(state==State.PLAYING)
func _covered_change(callback: Callable) -> void:
	if _transition_busy():return
	controls.set_enabled(false)
	ui.navigate(callback)
	_watch_transition()

func toggle_sound() -> void:
	super.toggle_sound()
	if ui != null: ui.refresh_settings()
