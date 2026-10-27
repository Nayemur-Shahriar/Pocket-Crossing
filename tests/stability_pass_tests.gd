extends Node
var passed:=0
var failed:=0
var heard: Array[String]=[]
func check(ok: bool, label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:run.call_deferred()
func run() -> void:
	Profiles.storage_path="user://stability_pass.cfg"
	var game: ModeGame=load("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Stability_Tester");SaveData.coins=5000
	Audio.cue_played.connect(func(cue: String):heard.append(cue))
	var tracks: Dictionary={}
	for index in range(4):
		var map: MapConfig=game.CAMPAIGN.levels[index];Profiles.purchase(map)
		game.select_level(index);game.set_physics_process(false);game.world.set_active(false)
		var actor:=game.world.player
		check(map.dog!=null,"dog configured "+map.level_id)
		check(map.environment.music_track!=null,"map music "+map.level_id)
		tracks[map.environment.music_track.resource_path]=true
		Audio._process(3);Audio._process(3)
		check(Audio.current_track==map.environment.music_track,"map selects its track")
		var pos:=Audio.music.get_playback_position();var stream:=Audio.music.stream
		Audio.request_music(map.environment.music_track);Audio._process(.01)
		check(Audio.music.stream==stream and Audio.music.get_playback_position()>=pos,"same track never restarts")
		for section in game.world.layout.sections:
			check(map.dog.allows(section)==(int(section.kind)==LevelSectionConfig.Kind.SAFE_SECTION),"only explicit dry safe sections")
			if not map.dog.allows(section):continue
			actor.visible=true;actor.enabled=false;actor.moving=false;actor.invulnerable_left=0
			actor.cell=Vector2i(8,section.first_row);actor.position=game.world.config.cell_position(actor.cell)
			var dog:=DogEncounter.new();dog.tick(.01,actor,section,map.dog,true)
			for i in range(29):dog.tick(.1,actor,section,map.dog,true)
			check(dog.phase=="idle","full grace period")
			for i in range(2):dog.tick(.1,actor,section,map.dog,true)
			check(dog.phase=="warning","warning before attack")
			heard.clear();game.dog_view.clear();game.dog_view.display(dog.snapshot(),.01);game.dog_view.display(dog.snapshot(),.01)
			check(heard==["dog_bark"],"one synchronized warning bark")
			for i in range(12):dog.tick(.1,actor,section,map.dog,true)
			check(dog.phase=="running","committed attack")
			actor.position.x+=9
			dog.tick(.05,actor,section,map.dog,true)
			check(dog.phase=="running","slight motion does not erase dog")
			var hit:=false
			for i in range(100):
				if dog.tick(.05,actor,section,map.dog,true)=="hit":hit=true;break
			check(hit,"dog reaches stationary target")
			dog.reset();dog.tick(.01,actor,section,map.dog,true)
			for i in range(32):dog.tick(.1,actor,section,map.dog,true)
			actor.moving=true;dog.tick(.01,actor,section,map.dog,true)
			check(dog.phase=="idle","warning escape")
			actor.moving=false;dog.phase="running";dog.at=Vector2(-48,actor.position.y);dog.direction=1
			actor.position.y+=64;dog.tick(.1,actor,{},map.dog,true)
			check(dog.phase=="running","escaped committed dog exits naturally")
			for i in range(60):dog.tick(.1,actor,{},map.dog,true)
			check(dog.phase=="idle","dog exit cleanup")
			dog.phase="running";dog.tick(.1,actor,section,map.dog,false)
			check(dog.phase=="idle","death/reset cleanup")
	check(tracks.size()==4,"four distinct tracks")
	RunRecords.set_option("music",false);SaveData.sound_enabled=true;Audio._process(3)
	check(Audio.music.stream_paused,"music off")
	heard.clear();Audio.play_cue("water_entry");check(heard==["water_entry"],"splash independent")
	RunRecords.set_option("music",true);SaveData.sound_enabled=false;Audio._process(3)
	check(not Audio.music.stream_paused,"music independent of SFX")
	SaveData.sound_enabled=true
	var session:=game.session
	session.match_participants.assign([1,2,3]);session.members={1:{"connected":true},2:{"connected":true},3:{"connected":true}}
	var rows: Array=[{"peer":1,"status":"finished"},{"peer":2,"status":"finished"},{"peer":3,"status":"active"}]
	check(not session.can_finalize(rows),"two finished one active must wait")
	rows[2].status="respawning";check(not session.can_finalize(rows),"respawn must wait")
	rows[2].status="finishing";check(not session.can_finalize(rows),"pending finish must resolve")
	check(not session.can_finalize(rows.slice(0,2)),"missing participant rejects")
	for status in ["finished","out","disconnected"]:
		rows[2].status=status;check(session.can_finalize(rows),"terminal "+status)
	session.start_at=session.now();rows[2].status="time_up";check(not session.can_finalize(rows),"no premature timeout")
	session.start_at=session.now()-200;check(session.can_finalize(rows),"actual timeout terminal")
	session.offset=0;session.target_offset=.2
	session._process(1.0/60)
	check(session.offset>0 and session.offset<=.001,"clock refinement is gradual")
	session.offset=0;session.target_offset=0
	# Replica creation is tested immediately, BEFORE a physics frame.
	session.members.clear();session.phase="racing";session.start_at=session.now()-1
	var h:=game.race.replica.hazards
	var serial:=100
	for type in ["rickshaw","cng","car","bus","truck"]:
		for direction in [-1,1]:
			serial+=1
			var x: float=-144 if direction==1 else 1424
			var sample:=maxf(0,session.server_now()-session.start_at)-.12
			var item: Array=[serial,0,type,x,180.0,direction,Color.WHITE]
			var data: Dictionary={"at":sample,"full":false,"roads":[item],"removed":[],"trains":[],"water":[]}
			h.receive(data)
			var v: TrafficVehicle=h.vehicles[serial]
			check(absf(v.position.x-(x+direction*180*.12))<2,"correct pre-tree transform "+type)
			check(not v.is_physics_processing() and not v.monitoring,"one transform owner")
			h.receive(data);check(h.vehicles.size()==serial-100,"duplicate spawn ignored")
			var before:=v.position.x;h._physics_process(1.0/60)
			check(absf(v.position.x-before)<4,"first tick no snap")
			item[3]=float(item[3])+10;h.receive(data);before=v.position.x;h._physics_process(1.0/60)
			check(absf(v.position.x-before)<4,"small repair smooth")
	h.clear();session.phase="offline";game.queue_free();await get_tree().process_frame
	Audio.music.stop()
	for voice in Audio.voices:voice.stop();voice.stream=null
	await get_tree().create_timer(.3).timeout
	print("STABILITY PASS: %d passed, %d failed"%[passed,failed]);get_tree().quit(failed)
