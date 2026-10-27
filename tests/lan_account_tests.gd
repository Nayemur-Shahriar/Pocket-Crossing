extends Node
var passed:=0
var failed:=0
func check(value: bool,label: String) -> void:
	if value:passed+=1
	else:failed+=1;push_error("FAIL "+label)
func _ready() -> void:
	Profiles.storage_path="user://lan_account_test.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	Profiles.load_profiles();SaveData.coins=0
	check(Account.create(" First_User ").is_empty(),"create")
	var id: String=Account.identity().id
	check(id.length()==32 and id.is_valid_hex_number(),"random identity")
	check(Account.identity().name=="First_User","trim")
	check(not Account.create("Other_User").is_empty(),"one account")
	SaveData.coins=123;Profiles.profiles[Profiles.active_key].maps.city_rush=true;Profiles.profiles[Profiles.active_key].times.city_rush=83.5;Profiles.save_active()
	check(Account.rename_account("New_Name").is_empty(),"rename")
	Profiles.load_profiles();Account.adopt_loaded()
	check(Account.identity().id==id and Account.identity().name=="New_Name","restart identity")
	check(SaveData.coins==123 and Profiles.best_time("city_rush")==83.5 and Profiles.is_unlocked("city_rush"),"progress retained")
	check(Profiles.profiles.size()==1,"rename not new account")
	check(not Account.rename_account("x!").is_empty(),"invalid name")
	Profiles.storage_path="user://missing_folder/cannot.cfg"
	check(not Account.rename_account("Lost_Name").is_empty() and Account.identity().name=="New_Name","failed write rollback")
	Profiles.storage_path="user://lan_account_test.cfg"
	var receipt:="a".repeat(32)
	check(Account.award_match(receipt,"river_delta",12,80),"reward")
	check(Account.award_match(receipt,"river_delta",12,80) and SaveData.coins==135,"once only")
	check(Account.best_time("river_delta")==80 and Profiles.best_time("river_delta")==0 and not Profiles.is_unlocked("river_delta"),"separate friends progress")
	Profiles.load_profiles();Account.adopt_loaded()
	check(SaveData.coins==135 and Account.identity().id==id,"reward persisted")
	var feed:=RaceFeed.new()
	for i in range(20):feed.push(str(i))
	feed.push("winner",true);feed.tick(0)
	check(feed.current=="winner" and feed.queue.size()<=8,"bounded priority feed")
	for i in range(50):feed.tick(3)
	check(feed.current.is_empty() and feed.queue.is_empty(),"feed drains")
	var link:=LanSession.new();link.phase="lobby";link.members[1]={"name":"Rahim","id":"a".repeat(32)}
	var identity:={"name":"Karim","id":"b".repeat(32),"skin":"unknown"}
	check(link.rejection(link.settings.content_version(),identity).is_empty(),"valid identity")
	identity.name=" rAhIm "
	check(link.rejection(link.settings.content_version(),identity).contains("username"),"duplicate normalized")
	identity.name="Karim"
	check(link.rejection("wrong",identity).contains("versions"),"version")
	link.phase="racing"
	check(link.rejection(link.settings.content_version(),identity).contains("progress"),"midmatch")
	link.phase="lobby";link.members[2]={};link.members[3]={};link.members[4]={}
	check(link.rejection(link.settings.content_version(),identity).contains("full"),"capacity")
	link.free()
	var platform:=FloatingPlatform.new();platform.set_rider(1,true);platform.set_rider(2,true);platform.set_rider(1,false)
	check(platform.carrying_player,"multi rider retention")
	platform.set_rider(2,false);check(not platform.carrying_player,"last rider release");platform.free()
	check(not Account.award_match("bad","river_delta",9999,1),"invalid reward rejected")
	Profiles.storage_path="user://lan_legacy_test.cfg"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(Profiles.storage_path+suffix)
	Profiles.load_profiles();Profiles.create_profile("Archived");Profiles.create_profile("Last_Active")
	check(Account.adopt_loaded() and Account.identity().name=="Last_Active","migrate active legacy account")
	check(Profiles.profiles.size()==2 and Profiles.profiles.has("archived"),"keep archived progression")
	var race:=LanRace.new()
	race.racers={1:{"id":"a","name":"First","rank":1,"state":"finished","finish":10.0,"score":10,"coins":0},2:{"id":"b","name":"Second","rank":2,"state":"finished","finish":11.0,"score":1000,"coins":0},3:{"id":"c","name":"Out","rank":0,"state":"out","finish":0.0,"score":99999,"coins":0},4:{"id":"d","name":"Left","rank":0,"state":"disconnected","finish":0.0,"score":12,"coins":0}}
	race.session=LanSession.new();race.config=MapConfig.new()
	for r: Dictionary in race.racers.values():
		r.occupied={0:true,1:true,2:true,3:true,4:true} if r.state=="finished" else {}
		r.deaths=0;r.remaining=0.0
	var rows:=race.rows()
	check(rows[0].name=="First" and rows[1].name=="Second","score cannot reorder finish rank")
	check(rows[2].status=="out" and rows[3].status=="disconnected","DNF below finishers")
	check(rows[1].time==11.0 and rows[1].score==1000,"result statistics retained")
	race.session.free();race.free()
	print("RESULT ",passed," passed / ",failed," failed");get_tree().quit(failed)
