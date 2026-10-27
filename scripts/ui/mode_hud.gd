class_name ModeHUD
extends MapHUD
signal action(kind: String, value: String)
var setting_buttons: Dictionary = {}
var page:="home"
var confirmation_layer: Control
var entry: LineEdit
var countdown: Label
var available: Control
func button(text: String, rect: Rect2, kind: String, value: String="", primary: bool=false) -> Button:
	var node:=_button(overlay,text,rect,primary)
	node.focus_mode=Control.FOCUS_ALL
	var panel := overlay
	node.pressed.connect(func() -> void:
		# A replaced panel cannot dispatch a queued second navigation.
		if is_instance_valid(panel) and panel == overlay and node.is_inside_tree():
			action.emit(kind,value))
	return node
func note(text: String) -> void:
	_label(overlay,text,Rect2(120,630,1040,54),19,YELLOW).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func _entry(rect: Rect2, placeholder: String, value: String="") -> LineEdit:
	var node:=LineEdit.new();node.position=rect.position;node.size=rect.size
	node.placeholder_text=placeholder;node.text=value;node.virtual_keyboard_enabled=true
	node.add_theme_font_size_override("font_size",26);overlay.add_child(node)
	return node
func mode_menu(notice: String="") -> void:
	page="home"
	_page("POCKET CROSSING")
	_label(overlay,"Welcome, "+String(Account.identity().get("name","Player")),Rect2(60,100,1000,40),24,YELLOW)
	button("LOCAL PLAY",Rect2(370,180,540,74),"local","",true)
	button("FRIENDS PLAY",Rect2(370,268,540,72),"friends")
	button("CHALLENGES",Rect2(370,356,540,72),"challenges")
	button("SETTINGS",Rect2(370,444,540,72),"settings")
	button("EXIT GAME",Rect2(370,532,540,72),"exit");note(notice)
func welcome(notice: String="",value: String="") -> void:
	page="welcome"
	_page("WELCOME TO POCKET CROSSING")
	_label(overlay,"Choose your username",Rect2(370,190,550,40),25,CREAM)
	entry=_entry(Rect2(370,260,540,70),"Your username",value);entry.max_length=16
	button("CREATE ACCOUNT",Rect2(370,365,540,80),"create","",true)
	_label(overlay,"3–16 letters, numbers or underscore. Stored on this device.",Rect2(280,482,850,36),19,MUTED);note(notice)
func settings_screen(notice: String="") -> void:
	page="settings";_page("SETTINGS");setting_buttons.clear()
	_label(overlay,"Rename your account · progress stays with you",Rect2(260,125,900,35),23,CREAM)
	entry=_entry(Rect2(260,177,530,65),"Username",String(Account.identity().get("name","")));entry.max_length=16
	button("SAVE NAME",Rect2(810,177,230,65),"rename","",true)
	setting_buttons["sound"] = button("SOUND "+("ON" if SaveData.sound_enabled else "OFF"),Rect2(260,282,370,65),"sound")
	setting_buttons["ambience"] = button("AMBIENCE "+("ON" if RunRecords.option("ambience") else "OFF"),Rect2(660,282,380,65),"ambience")
	setting_buttons["music"] = button("MUSIC "+("ON" if RunRecords.option("music") else "OFF"),Rect2(660,372,380,65),"music")
	setting_buttons["vibration"] = button("VIBRATION "+("ON" if SaveData.vibration_enabled else "OFF"),Rect2(260,372,370,65),"vibration")
	button("BACK",Rect2(470,510,340,70),"modes");note(notice)
func show_maps(catalog: LevelCatalog,notice: String="") -> void:
	page="maps"
	super.show_maps(catalog,notice)
	for node in overlay.find_children("*","Button",true,false):
		if node.text=="PLAYERS":node.text="MAIN MENU"
func friends_menu(notice: String="") -> void:
	page="friends"
	_page("FRIENDS PLAY")
	_label(overlay,"Race together on the same Wi-Fi or phone hotspot",Rect2(200,120,950,40),24,MUTED)
	button("HOST GAME",Rect2(320,242,640,86),"host","",true)
	button("JOIN GAME",Rect2(320,354,640,86),"join")
	button("BACK",Rect2(470,474,340,70),"modes");note(notice)
func join_screen() -> void:
	page="scan"
	_page("AVAILABLE GAMES")
	_label(overlay,"Same Wi-Fi or hotspot · searching nearby…",Rect2(60,100,1100,40),22,MUTED)
	available=Control.new();overlay.add_child(available)
	button("ENTER HOST IP",Rect2(300,525,325,74),"manual")
	button("BACK",Rect2(655,525,325,74),"friends")
func update_available(found: Dictionary) -> void:
	if not is_instance_valid(available):return
	for child in available.get_children():available.remove_child(child);child.queue_free()
	var i:=0
	for ip: String in found:
		if i>=3:break
		var item: Dictionary=found[ip]
		var node:=_button(available,"%s'S GAME   ·   %d / 4   ·   JOIN"%[item.name,int(item.players)],Rect2(180,180+i*100,920,80),true)
		node.disabled=item.get("phase","")!="lobby"
		node.pressed.connect(func() -> void:action.emit("connect",ip));i+=1
func manual_screen() -> void:
	page="manual"
	_page("ENTER HOST IP")
	_label(overlay,"Ask your friend for the Host IP shown in their lobby.",Rect2(220,180,950,48),24,CREAM)
	entry=_entry(Rect2(320,265,640,72),"192.168.43.1")
	button("CONNECT",Rect2(320,375,305,80),"connect_entry","",true)
	button("BACK",Rect2(655,375,305,80),"join")
func lobby(link: LanSession) -> void:
	page="lobby"
	_page("FRIENDS LOBBY")
	var addresses:=" / ".join(LanDiscovery.addresses())
	_label(overlay,("HOST IP  "+(addresses if not addresses.is_empty() else "Connect to Wi-Fi / hotspot")) if link.is_host() else "Connected to your friend's game",Rect2(60,97,1150,40),20,MUTED)
	var i:=0
	for id in link.members:
		var member: Dictionary=link.members[id]
		_panel(overlay,Rect2(60,170+i*88,570,72),Color("25434b"),12)
		_label(overlay,String(member.name),Rect2(80,184+i*88,340,40),24,CREAM)
		_label(overlay,("HOST · " if id==1 else "")+("READY" if member.ready else "LOADING"),Rect2(410,190+i*88,208,36),17,YELLOW);i+=1
	var config: MapConfig=load("res://resources/maps/"+link.map_id+".tres")
	_label(overlay,config.display_name,Rect2(690,146,500,38),25,YELLOW)
	var art:=TextureRect.new();art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay.add_child(art);art.texture=config.preview_art;art.position=Vector2(700,188);art.size=Vector2(170,90)
	if link.is_host():button("SELECT MAP",Rect2(890,200,280,60),"map_next")
	_label(overlay,"MATCH TIME",Rect2(690,297,500,30),19,MUTED)
	for j in range(LanMatchRules.DURATIONS.size()):
		var seconds: int=LanMatchRules.DURATIONS[j]
		var selected:=seconds==link.selected_match_time
		var choice:=button(("● " if selected else "")+"%d:%02d"%[seconds/60,seconds%60],Rect2(690+j*125,337,116,57),"match_time",str(seconds),selected)
		choice.disabled=not link.is_host() or link.phase!="lobby"
	_label(overlay,"MODE: "+LanMatchRules.mode_name(link.selected_ranking_mode),Rect2(690,412,520,32),19,MUTED)
	for j in range(2):
		var mode: String=LanMatchRules.MODES[j]
		var selected:=mode==link.selected_ranking_mode
		var choice:=button(("● " if selected else "")+LanMatchRules.mode_name(mode),Rect2(690+j*250,453,240,61),"ranking_mode",mode,selected)
		choice.add_theme_font_size_override("font_size",18)
		choice.disabled=not link.is_host() or link.phase!="lobby"
	_label(overlay,"YOUR FRIENDS BEST  "+(format_time(Account.best_time(link.map_id)) if Account.best_time(link.map_id)>0 else "—"),Rect2(690,535,500,25),16,MUTED)
	if link.is_host():button("START RACE",Rect2(690,577,490,74),"start","",true).disabled=not link.can_start()
	else:_label(overlay,"Waiting for the host to start",Rect2(690,588,500,60),23,MUTED)
	button("LEAVE",Rect2(60,577,360,74),"leave")

func start_race_ui() -> void:
	if is_instance_valid(scene_fade):scene_fade.cancel()
	page="race"
	hide_screen();pause_button.disabled=false
	if is_instance_valid(countdown):countdown.queue_free()
	countdown=_label(root,"5",Rect2(500,252,280,120),80,YELLOW)
	countdown.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	countdown.add_theme_color_override("font_outline_color",INK);countdown.add_theme_constant_override("outline_size",8)
func stop_race_ui() -> void:
	if is_instance_valid(countdown):countdown.queue_free()
	countdown=null;message_label.modulate.a=1
func race_pause(host: bool,confirm: bool=false) -> void:
	page="race_pause"
	_page("RACE MENU")
	_label(overlay,"The race continues while this menu is open.",Rect2(280,180,850,45),25,CREAM)
	button("RESUME",Rect2(390,277,500,78),"resume","",true)
	button("LEAVE RACE",Rect2(390,383,500,78),"leave")
	if host:button("CONFIRM END MATCH" if confirm else "END MATCH…",Rect2(390,489,500,78),"end_confirm" if confirm else "end_prompt")
func race_results(rows: Array,host: bool,notice: String="",mode: String="time",awards: Array=[],local_peer: int=0) -> void:
	page="race_results"
	stop_race_ui();_page("RACE RESULTS")
	CompetitiveResults.draw(self,rows,mode,awards,local_peer)
	if host:
		button("PLAY AGAIN",Rect2(100,580,320,74),"replay","",true)
		button("LOBBY / CHANGE MAP",Rect2(440,580,420,74),"lobby")
	else:button("WAIT FOR HOST / LOBBY",Rect2(140,580,670,74),"lobby")
	button("LEAVE",Rect2(880,580,280,74),"leave")
	_label(overlay,notice,Rect2(100,673,1080,30),17,YELLOW)

func map_picker(link: LanSession) -> void:
	page="lan_maps";_page("SELECT FRIENDS MAP")
	_label(overlay,"Host chooses an unlocked map. Guests do not need to own it.",Rect2(90,112,1100,40),22,MUTED)
	for i in range(Profiles.MAP_IDS.size()):
		var id: String=Profiles.MAP_IDS[i];var map: MapConfig=load("res://resources/maps/"+id+".tres")
		var unlocked:=Profiles.is_unlocked(id)
		var text:=map.display_name.to_upper()+ ("  ·  SELECTED" if id==link.map_id else ("" if unlocked else "  ·  LOCKED"))
		var item:=button(text,Rect2(180,180+i*88,920,70),"map_choose",id,id==link.map_id)
		item.disabled=not unlocked or not link.is_host();item.name="MapChoice_"+id
	_label(overlay,"Unlock locked maps with coins in Local Play → Map Select.",Rect2(180,548,990,35),20,YELLOW)
	button("BACK TO LOBBY",Rect2(400,603,480,70),"back")
func confirmation(title: String, detail: String, accept: String) -> void:
	close_confirmation()
	confirmation_layer=Control.new();root.add_child(confirmation_layer)
	confirmation_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirmation_layer.mouse_filter=Control.MOUSE_FILTER_STOP
	_panel(confirmation_layer,Rect2(0,0,1280,720),Color(0.05,0.11,0.14,0.96),0)
	_label(confirmation_layer,title,Rect2(160,195,960,60),36,YELLOW)
	_label(confirmation_layer,detail,Rect2(160,295,1000,95),23,CREAM).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var cancel:=_button(confirmation_layer,"CANCEL",Rect2(260,465,340,80),false)
	cancel.pressed.connect(func() -> void:action.emit("cancel_confirm",""))
	var yes:=_button(confirmation_layer,accept,Rect2(660,465,340,80),true)
	yes.pressed.connect(func() -> void:action.emit("accept_confirm",""))
	cancel.focus_mode=Control.FOCUS_ALL;yes.focus_mode=Control.FOCUS_ALL;cancel.grab_focus()
func close_confirmation() -> void:
	if is_instance_valid(confirmation_layer):root.remove_child(confirmation_layer);confirmation_layer.queue_free()
	confirmation_layer=null
func local_pause() -> void:
	page="local_pause";_page("PAUSED")
	for i in range(4):
		button(["RESUME","RESTART MAP","MAP SELECT","MAIN MENU"][i],Rect2(360,190+i*108,560,80),["local_resume","local_retry","local_maps","modes"][i],"",i==0)
func show_characters(notice: String="Cosmetic skins only. Same speed, lives and collision shape.") -> void:
	page="characters";super.show_characters(notice)
func show_map_result(completed: bool, elapsed: float, best: float, coins: int, safe_count: int, new_best: bool, notice: String="") -> void:
	page="local_result";super.show_map_result(completed,elapsed,best,coins,safe_count,new_best,notice)

func show_challenges(catalog: LevelCatalog, map_id: String="village_crossing") -> void:
	page="challenges";_page("CHALLENGES");MapDepthHUD.challenges(self,catalog,map_id)
	# Never expose the previous world through a freshly rebuilt Challenge menu.
	overlay.modulate.a=1.0

func refresh_settings() -> void:
	if page != "settings": return
	for key: String in setting_buttons:
		var control := setting_buttons[key] as Button
		if not is_instance_valid(control) or not control.is_inside_tree(): continue
		var enabled: bool = SaveData.sound_enabled if key == "sound" else (SaveData.vibration_enabled if key == "vibration" else RunRecords.option(key))
		control.text = key.to_upper() + (" ON" if enabled else " OFF")
