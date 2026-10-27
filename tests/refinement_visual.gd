extends Node
var game: ModeGame
func shot(label: String) -> void:
	for i in range(5):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/refinement_screenshots")
	get_viewport().get_texture().get_image().save_png("res://docs/refinement_screenshots/"+label+".png")
func _ready() -> void:
	Profiles.storage_path="user://refinement_visual.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	game=load("res://scenes/main.tscn").instantiate();add_child(game)
	Account.create("Crossing_Tester");SaveData.coins=1000;SaveData.sound_enabled=false
	for map in game.CAMPAIGN.levels:Profiles.purchase(map)
	game.ui.mode_menu();await shot("home")
	game.ui.settings_screen();await shot("settings")
	game.show_menu();await shot("maps")
	game.ui.show_characters();await shot("character_selection_top")
	for scroll in game.ui.overlay.find_children("*","ScrollContainer",true,false):scroll.scroll_vertical=1000
	await shot("character_selection_bottom")
	game.ui._page("CHARACTER ART · IDENTICAL GAMEPLAY")
	for i in range(CharacterCatalog.SKINS.size()):
		var skin: Dictionary=CharacterCatalog.SKINS[i]
		var x:=65+i*195
		game.ui._panel(game.ui.overlay,Rect2(x,170,180,380),Color("29454d"),12)
		var art:=TextureRect.new();game.ui.overlay.add_child(art);art.texture=load(skin.texture);art.position=Vector2(x+38,225);art.size=Vector2(104,120)
		game.ui._label(game.ui.overlay,String(skin.name).replace(" / ","\n"),Rect2(x+10,390,160,90),21,Color("ffdc89")).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	await shot("six_characters")
	game.select_level(0);game.start_run(42);game.set_physics_process(false);game.world.set_active(false)
	var row:=0
	for section in game.world.layout.sections:
		if section.kind==LevelSectionConfig.Kind.SAFE_SECTION:row=section.first_row;break
	var player:=game.world.player
	player.cell=Vector2i(8,row);player.position=game.world.config.cell_position(player.cell);player.invulnerable_left=0;game.world.camera.snap_to_player()
	game.dog_view.display({"phase":"warning","origin":player.position,"warning_id":1},0,false)
	await shot("dog_warning")
	game.dog_view.display({"phase":"running","at":player.position+Vector2(-130,0),"direction":1},0.2,false)
	await shot("dog_running")
	get_window().size=Vector2i(640,360);game.ui.settings_screen();await shot("settings_phone")
	game.ui.show_characters();await shot("characters_phone")
	game.select_level(3);game.start_run(42)
	await get_tree().create_timer(1).timeout
	await shot("night_character")
	game.leave_friends();game.queue_free();await get_tree().process_frame
	print("REFINEMENT VISUAL RESULTS: capture and cleanup complete");get_tree().quit()
