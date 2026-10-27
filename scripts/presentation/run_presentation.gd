class_name RunPresentation
extends Node2D
## One bounded drawing node and one quiet ambience voice per game, never per section.
const LIMIT:=20
var game: Node
var bursts: Array[Dictionary]=[]
var ambient: AudioStreamPlayer
var clock:=0.0
var shake_left:=0.0
var shake_strength:=0.0
var warnings: Dictionary={}
var last_lives:=-1
var last_safe:=0
var last_coins:=0
var last_position:=Vector2.ZERO
var running:=false
var ending:=false
var ambient_stream: AudioStream
func setup(owner_game: Node) -> void:
	game=owner_game;z_index=4
	ambient=AudioStreamPlayer.new();ambient.volume_db=-29;ambient.max_polyphony=1;add_child(ambient)
	game.world.player.step_completed.connect(_land)
func begin(map: MapConfig) -> void:
	clear();running=true;ending=false;ambient_stream=map.ambience
	if ambient_stream is AudioStreamWAV:
		ambient_stream=ambient_stream.duplicate()
		ambient_stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		ambient_stream.loop_end=int(ambient_stream.get_length()*ambient_stream.mix_rate)
	ambient.stream=ambient_stream
	if ambient.stream!=null and SaveData.sound_enabled and RunRecords.option("ambience"):ambient.play()
func clear() -> void:
	running=false;ending=false;bursts.clear();warnings.clear();last_lives=-1;last_safe=0;last_coins=0;shake_left=0
	if is_instance_valid(ambient):ambient.stop()
	if game!=null:game.world.camera.offset=Vector2.ZERO
	queue_redraw()
func end_run() -> void:
	ending=true
	ambient.stop()
static func haptic(milliseconds: int) -> void:
	if OS.has_feature("android") and SaveData.vibration_enabled:Input.vibrate_handheld(milliseconds)
func emit_effect(kind: String, at: Vector2) -> void:
	if bursts.size()>=LIMIT:bursts.pop_front()
	bursts.append({"kind":kind,"at":at,"age":0.0,"life":0.48 if kind=="splash" else 0.3})
	if kind in ["impact","train"]:shake_left=0.16;shake_strength=2.5 if kind=="train" else 1.5
	queue_redraw()
func death(kind: int, at: Vector2) -> void:
	var water:=kind==LevelSectionConfig.Kind.WATER_SECTION
	var train:=kind==LevelSectionConfig.Kind.RAILWAY_SECTION
	emit_effect("splash" if water else ("train" if train else "impact"),at)
	haptic(65 if train else 40)
func success(at: Vector2, fifth: bool) -> void:
	emit_effect("finish" if fifth else "success",at);haptic(30 if fifth else 15)
func _land(cell: Vector2i) -> void:
	if not running:return
	var kind:=int(game.world.layout.section_at(cell.y).get("kind",0))
	if kind not in [LevelSectionConfig.Kind.WATER_SECTION,LevelSectionConfig.Kind.DESTINATION_SECTION]:emit_effect("dust",game.world.player.position+Vector2(0,12))
func _process(delta: float) -> void:
	if game==null or not running:return
	var friends: bool=game.get("friends")==true
	var active: bool=game.session.phase in ["countdown","racing"] if friends else game.state in [game.State.PLAYING,game.State.RESPAWNING]
	active=active and not ending
	var audible:=active and SaveData.sound_enabled and RunRecords.option("ambience")
	ambient.stream_paused=not audible
	if audible and not ambient.playing and ambient.stream!=null:ambient.play()
	if not active:
		game.world.camera.offset=Vector2.ZERO
		if not ending:return
	clock+=delta
	for i in range(bursts.size()-1,-1,-1):
		bursts[i].age+=delta
		if bursts[i].age>=bursts[i].life:bursts.remove_at(i)
	if ending:
		if bursts.is_empty():running=false
		queue_redraw();return
	shake_left=maxf(0,shake_left-delta)
	game.world.camera.offset=Vector2(sin(clock*90),cos(clock*75))*shake_strength*shake_left/0.16 if shake_left>0 else Vector2.ZERO
	for section in game.world.railways:
		for track in section.tracks:
			var id: int=track.get_instance_id()
			if warnings.get(id,-1)!=track.state:
				warnings[id]=track.state
				if track.state==RailwayTrack.State.WARNING and absf(track.position.y-game.world.camera.position.y-360)<400:Audio.play_cue("rail_warning")
	if friends and game.race.racers.has(game.session.local_id()):
		var row: Dictionary=game.race.racers[game.session.local_id()]
		var safe: int=row.occupied.size()
		if safe>last_safe:success(last_position,safe==5);Audio.play_cue("complete" if safe==5 else "dock")
		if row.coins>last_coins:emit_effect("coin",game.world.player.position)
		last_lives=row.lives;last_safe=safe;last_coins=row.coins
	last_position=game.world.player.position
	queue_redraw()
func _draw() -> void:
	for burst in bursts:
		var t: float=burst.age/burst.life
		var color:=Color("91d9ee") if burst.kind=="splash" else (Color("f8cf72") if burst.kind=="coin" else (Color("f59f80") if burst.kind in ["impact","train"] else Color("d6ecc1")))
		color.a=(1-t)*(0.35 if burst.kind=="dust" else 0.8)
		var radius: float=8+t*(38 if burst.kind in ["train","finish"] else 23)
		for i in range(8):
			var angle:=i*TAU/8
			var at: Vector2=burst.at+Vector2(cos(angle)*radius,sin(angle)*radius*(0.35 if burst.kind in ["dust","splash"] else 1))
			draw_circle(at,2.5*(1-t)+0.5,color)
		if burst.kind!="dust":draw_arc(burst.at,radius,0,TAU,24,color,1.5,true)
