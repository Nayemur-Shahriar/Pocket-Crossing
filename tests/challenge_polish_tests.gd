extends Node
var passed:=0
var failed:=0
var game: ModeGame
var token:=""
var swaps:=0
var rendered_token:=""
var rendered_swaps:=0
var visual:=false
func check(ok: bool,label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:run.call_deferred()
func watch() -> void:
	if not game._transition_busy():return
	var fade:=game.ui.scene_fade
	if token!=game.record_token:
		token=game.record_token;swaps+=1
		check(fade.veil.visible and fade.veil.modulate.a==1.0,"swap fully covered")
		check(fade.layer>game.ui.layer,"above HUD")
		check(game.world.player.cell==game.world.config.spawn_cell,"spawn ready")
		check(game.world.config.level_id==game.current_map.level_id,"selected layout ready")
		check(game.world.presentation.theme!=null,"theme ready")
	if fade.stage==3:check(fade.veil.modulate.a==1.0,"settling remains opaque")
func settle() -> void:
	for i in range(180):
		await get_tree().process_frame
		watch()
		if not game._transition_busy():return
	check(false,"transition timeout")
func inspect_frame() -> void:
	if not is_instance_valid(game) or rendered_token==game.record_token:return
	rendered_token=game.record_token
	if not game._transition_busy():return
	rendered_swaps+=1
	var frame:=get_viewport().get_texture().get_image()
	var opaque:=true
	for x in [.05,.25,.75,.95]:
		for y in [.1,.3,.7,.9]:
			var c:=frame.get_pixel(int(x*frame.get_width()),int(y*frame.get_height()))
			if absf(c.r-22.0/255)>.025 or absf(c.g-46.0/255)>.025 or absf(c.b-56.0/255)>.025:opaque=false
	check(opaque,"actual rendered swap frame opaque")
	if rendered_swaps<=8:frame.save_png("res://docs/challenge_polish/covered_%02d.png"%rendered_swaps)
func run() -> void:
	visual="visual" in OS.get_cmdline_user_args()
	if visual:
		DirAccess.make_dir_recursive_absolute("res://docs/challenge_polish")
		RenderingServer.frame_post_draw.connect(inspect_frame)
	Profiles.storage_path="user://challenge_polish.cfg"
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Challenge_QA");SaveData.coins=5000
	for map: MapConfig in game.CAMPAIGN.levels:Profiles.purchase(map)
	var music_id:=Audio.music.get_instance_id()
	game._action("challenges","")
	check(game.ui.overlay.modulate.a==1.0,"menu opaque immediately")
	for cycle in range(3):
		for index in range(4):
			var map: MapConfig=game.CAMPAIGN.levels[index]
			game._action("challenge_map",map.level_id);await settle()
			check(game.ui.overlay.modulate.a==1.0,"tab opaque")
			var c:=ChallengeCatalog.for_map(map.level_id)[0]
			var old:=swaps
			game._action("challenge_play",str(index)+"|"+c.challenge_id)
			game._action("challenge_play",str((index+1)%4)+"|one_life")
			await settle()
			check(swaps==old+1,"one selection one load")
			check(game.current_map.level_id==map.level_id and game.challenge.challenge_id==c.challenge_id,"correct challenge")
			check(game.controls.enabled,"controls restored")
			Audio._process(1);Audio._process(1)
			check(Audio.current_track==game.current_map.environment.challenge_music_track,"challenge mix")
			var stream:=Audio.music.stream
			var loop:=stream as AudioStreamWAV
			check(loop.loop_mode==AudioStreamWAV.LOOP_FORWARD and loop.loop_end>0,"loop enabled")
			var old_token:=game.record_token
			game._action("local_retry","");await settle()
			check(game.record_token!=old_token,"retry resets run")
			check(Audio.music.stream==stream,"retry preserves music position")
			if visual and cycle==0:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://docs/challenge_polish/"+map.level_id+".png")
			game.show_menu()
			check(game.ui.page=="challenges" and game.ui.overlay.modulate.a==1.0,"return opaque")
	check(swaps==24,"24 start/retry changes")
	if visual:check(rendered_swaps==24,"all swaps verified after draw");print("RENDERED SWAPS: ",rendered_swaps)
	check(Audio.music.get_instance_id()==music_id and Audio.get_child_count()==5,"one music plus four effects")
	check(Audio.loop_cache.size()<=9,"bounded cache")
	game._action("challenge_play","0|one_life");game.navigation.back()
	check(not game._transition_busy(),"cancel before swap")
	for i in range(4):
		game.select_level(i);Audio._process(1);Audio._process(1)
		check(Audio.current_track==game.current_map.environment.music_track,"normal mix restored")
	RunRecords.set_option("music",false);SaveData.sound_enabled=true;Audio._process(.01)
	check(Audio.music.stream_paused,"music off immediate")
	Audio.play_cue("coin");check(Audio.voices.any(func(v):return v.playing),"SFX independently on")
	RunRecords.set_option("music",true);SaveData.sound_enabled=false;Audio._process(1)
	check(not Audio.music.stream_paused,"music independently on")
	Profiles.save_active();Profiles.load_profiles()
	check(RunRecords.option("music") and not SaveData.sound_enabled,"settings persist")
	game.queue_free();await get_tree().process_frame
	print("CHALLENGE POLISH: ",passed," passed, ",failed," failed")
	get_tree().quit(failed)
