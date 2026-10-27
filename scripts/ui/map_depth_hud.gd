class_name MapDepthHUD
extends RefCounted
static func challenges(ui: ModeHUD, catalog: LevelCatalog, map_id: String) -> void:
	var index:=0
	for i in range(catalog.levels.size()):
		var map:=catalog.levels[i] as MapConfig
		if map.level_id==map_id:index=i
		var item:=ui.button(map.display_name,Rect2(55+i*305,110,290,65),"challenge_map",map.level_id,map.level_id==map_id)
		item.add_theme_font_size_override("font_size",20)
	var selected:=catalog.levels[index] as MapConfig
	var unlocked:=Profiles.is_unlocked(selected.level_id)
	var choices:=ChallengeCatalog.for_map(selected.level_id)
	for i in range(choices.size()):
		var c:=choices[i];var record:=MapDepthProgress.record(selected.level_id,c.challenge_id)
		var y:=198+i*76
		ui._panel(ui.overlay,Rect2(55,y,1170,67),Color("25434b"),10)
		ui._label(ui.overlay,c.title,Rect2(75,y+3,240,30),22,ui.YELLOW)
		ui._label(ui.overlay,c.description,Rect2(315,y+3,690,28),18,ui.CREAM)
		ui._label(ui.overlay,("DONE · " if record.completed else "NEW · ")+"Best "+(MapHUD.format_time(record.time) if record.time>0 else "—")+" · Score "+str(record.score),Rect2(75,y+35,900,25),16,ui.MUTED)
		ui.button("PLAY" if unlocked else "LOCKED",Rect2(1030,y+6,180,55),"challenge_play",str(index)+"|"+c.challenge_id,true).disabled=not unlocked
	ui._label(ui.overlay,"Local only · Separate best times · "+("" if unlocked else "Unlock this map in Local Play."),Rect2(55,594,1170,34),18,ui.MUTED)
	ui.button("MAIN MENU",Rect2(440,643,400,58),"modes")
