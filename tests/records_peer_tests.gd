extends "res://tests/competitive_peer_tests.gd"
func result_received(rows: Array,receipt: String) -> void:
	var record:=RunRecords.read("friends",game.session.map_id)
	check(record.plays==rounds+1,"Friends play counted once")
	check(record.completions==rounds,"Friends completions counted once")
	check(RunRecords.read("local",game.session.map_id).plays==0,"Friends does not write Local records")
	check(game.get("ghost")==null,"no LAN ghost recording or playback")
	var before:=record.duplicate(true)
	for row: Dictionary in rows:
		if int(row.peer)==game.session.local_id():RunRecords.apply("friends",game.session.map_id,receipt,row)
	check(RunRecords.read("friends",game.session.map_id)==before,"repeated LAN receipt cannot add a play or podium")
	super.result_received(rows,receipt)
