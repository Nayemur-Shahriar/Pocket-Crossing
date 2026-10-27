class_name CompetitiveResults
extends RefCounted
## Friends-only presentation. Local results retain their existing workflow.
static func draw(ui: ModeHUD, rows: Array, mode: String, awards: Array, local_peer: int) -> void:
	if not rows.is_empty() and rows[0].peer==local_peer and rows[0].score>0:
		ui.map_celebration=ResultCelebration.new()
		ui.map_celebration.sound=ui.celebration_sound
		ui.overlay.add_child(ui.map_celebration)
		ui.overlay.move_child(ui.map_celebration,1)
	var heading:=ui._panel(ui.overlay,Rect2(43,22,510,96),ui.INK,8)
	ui.overlay.move_child(heading,2 if ui.map_celebration!=null else 1)
	ui._label(ui.overlay,LanMatchRules.mode_name(mode),Rect2(60,90,1100,32),22,ui.YELLOW)
	ui._panel(ui.overlay,Rect2(150,128,1020,43),ui.INK,8)
	var columns: Array=[["RANK",170],["PLAYER",280],["TIME",765],["SCORE",990]]
	for column: Array in columns:ui._label(ui.overlay,column[0],Rect2(column[1],137,220,32),20,ui.YELLOW)
	for i in range(rows.size()):
		var row: Dictionary=rows[i]
		var y:=180+i*69
		ui._panel(ui.overlay,Rect2(150,y,1020,61),Color("25434b"),10)
		ui._label(ui.overlay,str(row.rank),Rect2(170,y+11,80,35),25,ui.YELLOW)
		ui._label(ui.overlay,row.name,Rect2(280,y+1,455,31),24,ui.CREAM)
		ui._label(ui.overlay,"%d/5 SAFE · %d COINS · %d DEATHS"%[row.get("safe",0),row.coins,row.get("deaths",0)],Rect2(280,y+33,475,25),15,ui.MUTED)
		var time_text:=MapHUD.format_time(row.time) if row.get("safe",0)==5 else ("TIME UP" if row.get("timed_out",false) else ("DISCONNECTED" if row.status=="disconnected" else ("OUT" if row.status=="out" else "TIME UP")))
		ui._label(ui.overlay,time_text,Rect2(765,y+16,210,32),20,ui.CREAM)
		ui._label(ui.overlay,str(row.score),Rect2(990,y+16,178,32),20,ui.CREAM)
	if not awards.is_empty():ui._panel(ui.overlay,Rect2(90,459,1080,101),ui.INK,8)
	var titles:={"time":"FASTEST FINISH","score":"HIGHEST SCORE","coins":"MOST COINS","deaths":"FEWEST DEATHS"}
	for i in range(awards.size()):
		var award: Dictionary=awards[i]
		var x:=100+(i%2)*560
		var y:=464+(i/2)*48
		ui._label(ui.overlay,titles[award.kind],Rect2(x,y,540,22),14,ui.YELLOW)
		ui._label(ui.overlay,String(award.name)+" — "+(MapHUD.format_time(award.value) if award.kind=="time" else str(award.value)),Rect2(x,y+20,540,26),18,ui.CREAM)
