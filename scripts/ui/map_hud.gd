class_name MapHUD
extends GameHUD
signal profile_create_requested(username: String)
signal profile_selected(key: String)
signal profile_screen_requested
signal map_purchase_requested(index: int)
var map_result: Control
var map_celebration: ResultCelebration
var profile_name: LineEdit
var map_time := 0.0
var safe_count := 0
static func format_time(seconds: float) -> String:
	var centiseconds:=maxi(0,int(round(seconds*100)))
	return "%02d:%02d.%02d"%[centiseconds/6000,(centiseconds/100)%60,centiseconds%100]
func _ready() -> void:
	super._ready()
	for node in root.get_children():
		if node is Label:
			if node.text=="SCORE":node.text="COINS"
			if node.text=="TIME LEFT":node.text="TIME"
	time_label.add_theme_font_size_override("font_size",26)
func hide_screen() -> void:
	if is_instance_valid(map_celebration):map_celebration.stop()
	map_celebration=null
	map_result=null
	super.hide_screen()
func _page(title: String) -> void:
	hide_screen()
	overlay=Control.new()
	# Panels are replaced synchronously; never reveal the world between pages.
	overlay.modulate.a=1.0
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	_panel(overlay,Rect2(0,0,1280,720),INK)
	_label(overlay,title,Rect2(60,30,740,54),32,CREAM)
	pause_button.disabled=true
func show_profiles(notice: String = "", typed_name: String = "") -> void:
	_page("POCKET CROSSING")
	_label(overlay,"Choose your player",Rect2(60,88,750,38),23,MUTED)
	_panel(overlay,Rect2(60,155,490,432),Color("25434b"),20)
	_label(overlay,"NEW PLAYER",Rect2(88,181,424,34),24,YELLOW)
	_label(overlay,"Username · 3–16 letters, numbers or _",Rect2(88,229,424,34),19,CREAM)
	profile_name=LineEdit.new()
	profile_name.name="Username"
	profile_name.position=Vector2(88,278)
	profile_name.size=Vector2(434,66)
	profile_name.placeholder_text="Your name"
	profile_name.text=typed_name
	profile_name.max_length=16
	profile_name.virtual_keyboard_enabled=true
	profile_name.add_theme_font_size_override("font_size",26)
	overlay.add_child(profile_name)
	var create:=_button(overlay,"CREATE PLAYER",Rect2(88,369,434,68),true)
	create.name="CreatePlayer"
	create.focus_mode=Control.FOCUS_ALL
	create.pressed.connect(func() -> void:profile_create_requested.emit(profile_name.text))
	profile_name.text_submitted.connect(func(value: String) -> void:profile_create_requested.emit(value))
	var info:=notice if not notice.is_empty() else ("Your first player keeps your existing coins and skins." if Profiles.migration_pending else "Usernames are unique only on this device.")
	var message:=_label(overlay,info,Rect2(88,458,434,104),19,Color("f4cd8a"))
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_label(overlay,"CONTINUE AS",Rect2(610,155,580,35),23,YELLOW)
	var scroll:=LevelListScroll.new()
	scroll.name="ProfileList"
	scroll.position=Vector2(610,207)
	scroll.size=Vector2(610,400)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	var list:=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",12)
	scroll.add_child(list)
	for key: String in Profiles.profiles:
		var data: Dictionary=Profiles.profiles[key]
		var button:=_button(list,"%s     ·     %d coins"%[data.username,data.coins],Rect2(),key==Profiles.active_key)
		button.name="Profile_"+key
		button.custom_minimum_size=Vector2(0,78)
		button.focus_mode=Control.FOCUS_ALL
		button.pressed.connect(func() -> void:profile_selected.emit(key))
	if Profiles.profiles.is_empty():_label(overlay,"Your crossings start here.",Rect2(610,220,590,38),21,MUTED)
	_label(overlay,"OFFLINE PLAY  /  PROGRESS STAYS ON THIS DEVICE",Rect2(60,651,1120,30),16,MUTED)
func show_maps(catalog: LevelCatalog, notice: String = "") -> void:
	_page("CHOOSE YOUR CROSSING")
	var name: String=Profiles.profiles[Profiles.active_key].username
	_label(overlay,"%s   ·   %d coins"%[name,SaveData.coins],Rect2(60,91,700,37),23,YELLOW)
	var skins:=_button(overlay,"CHARACTERS",Rect2(820,35,190,72),false)
	skins.focus_mode=Control.FOCUS_ALL
	skins.pressed.connect(func() -> void:characters_pressed.emit())
	var players:=_button(overlay,"PLAYERS",Rect2(1026,35,194,72),false)
	players.focus_mode=Control.FOCUS_ALL
	players.pressed.connect(func() -> void:profile_screen_requested.emit())
	for i in range(catalog.levels.size()):
		var map:=catalog.levels[i] as MapConfig
		var at:=Vector2(60+(i%2)*590,155+(i/2)*246)
		_panel(overlay,Rect2(at,Vector2(570,226)),Color("25434b"),18)
		var picture:=TextureRect.new()
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
		overlay.add_child(picture)
		picture.texture=map.preview_art
		picture.position=at+Vector2(14,14)
		picture.size=Vector2(194,198)
		_label(overlay,"%02d  %s"%[i+1,map.display_name.to_upper()],Rect2(at+Vector2(226,20),Vector2(330,30)),22,CREAM)
		_label(overlay,map.atmosphere_label,Rect2(at+Vector2(226,57),Vector2(320,27)),18,MUTED)
		var unlocked:=Profiles.is_unlocked(map.level_id)
		picture.modulate = Color.WHITE if unlocked else Color(0.65,0.72,0.74,1)
		var best:=Profiles.best_time(map.level_id)
		var detail: String=("Best  "+format_time(best) if best>0 else "Five crossings. One best time.") if unlocked else "LOCKED  ·  %d coins"%map.unlock_cost
		_label(overlay,detail,Rect2(at+Vector2(226,96),Vector2(330,30)),18,YELLOW)
		var action:=_button(overlay,"PLAY" if unlocked else "UNLOCK · %d"%map.unlock_cost,Rect2(at+Vector2(226,147),Vector2(322,64)),unlocked)
		action.name="Map_%d"%(i+1)
		action.focus_mode=Control.FOCUS_ALL
		if unlocked:action.pressed.connect(func() -> void:navigate(func() -> void:level_selected.emit(i)))
		else:action.pressed.connect(func() -> void:map_purchase_requested.emit(i))
	var label:=_label(overlay,notice,Rect2(60,660,1160,38),20,YELLOW)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func update_map_status(seconds: float, coins: int, lives: int, safe: int) -> void:
	map_time=seconds
	safe_count=safe
	score_label.text="+%d"%coins
	time_label.text=format_time(seconds)
	time_label.modulate=Color.WHITE
	lives_label.text="♥  ".repeat(maxi(0,lives)).strip_edges()
	bays_label.text="%d / 5 SAFE"%safe
	bays_label.position=Vector2(850,684)
	bays_label.modulate=Color.WHITE
	destination_label.visible=false
	time_bar.size.x=1280.0*safe/5.0
func show_map_result(completed: bool, seconds: float, best: float, coins: int, safe: int, record: bool, notice: String = "") -> void:
	_page(" ")
	map_result=overlay
	if record and completed:
		map_celebration=ResultCelebration.new()
		map_celebration.sound=celebration_sound
		overlay.add_child(map_celebration)
		var effect:=map_celebration
		var panel:=overlay
		overlay.visibility_changed.connect(func() -> void:
			if not panel.is_visible_in_tree() and is_instance_valid(effect):effect.stop())
	_panel(overlay,Rect2(278,100,724,520),CREAM,24)
	_label(overlay,level_config.display_name.to_upper(),Rect2(316,128,648,30),20,Color("597365"))
	_label(overlay,"MAP COMPLETE" if completed else "TRY AGAIN",Rect2(316,174,648,55),38,INK)
	_label(overlay,"%d / 5 SAFE"%safe,Rect2(316,239,648,36),24,Color("50775d"))
	_label(overlay,format_time(seconds),Rect2(316,290,648,68),51,INK)
	_label(overlay,"BEST  "+(format_time(best) if best>0 else "—"),Rect2(316,366,648,34),23,Color("597365"))
	_label(overlay,"NEW BEST TIME!" if record else "",Rect2(316,408,648,30),22,Color("50775d"))
	_label(overlay,"COINS  +%d"%coins,Rect2(316,449,648,32),23,INK)
	var retry:=_button(overlay,"PLAY AGAIN" if completed else "TRY AGAIN",Rect2(308,508,324,74),true)
	retry.name="MapRetry"
	retry.focus_mode=Control.FOCUS_ALL
	retry.pressed.connect(func() -> void:navigate(func() -> void:retry_pressed.emit()))
	var menu:=_button(overlay,"MAP SELECT",Rect2(644,508,324,74),false)
	menu.name="MapSelect"
	menu.focus_mode=Control.FOCUS_ALL
	menu.pressed.connect(func() -> void:menu_pressed.emit())
	_label(overlay,notice,Rect2(300,632,800,45),18,YELLOW)
	_focus_if_current.call_deferred(retry)
func show_characters(notice: String = "Cosmetic skins only. Same speed, lives and collision shape.") -> void:
	super.show_characters(notice)
	for button in overlay.find_children("*","Button",true,false):
		if button.text=="RETURN TO LEVEL SELECT":button.text="RETURN TO MAP SELECT"
func show_screen(kind: String, score: int = 0, best: int = 0, detail: String = "") -> void:
	super.show_screen(kind,score,best,detail)
	if kind=="pause":
		for button in overlay.find_children("*","Button",true,false):
			if button.text=="Level Select":button.text="Map Select"
			if button.text=="Restart level":button.text="Restart map"
