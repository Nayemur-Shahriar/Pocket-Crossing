extends Node
func _ready() -> void:
	var config:=LanConfig.new();config.discovery_port=42425
	var host:=LanDiscovery.new();var client:=LanDiscovery.new();var passed:=0
	if host.start(config,true)==OK and client.start(config,false)==OK:passed+=1
	host.info={"tag":config.protocol,"name":"Host_User","players":1,"map":"village_crossing","phase":"lobby"}
	client.next_query=100;client.socket.set_dest_address("127.0.0.1",42425);client.socket.put_packet("POCKET_CROSSING_DISCOVER_1".to_utf8_buffer())
	for i in range(20):
		host.tick(0.01);client.tick(0.01);await get_tree().process_frame
	if client.found.has("127.0.0.1") and client.found["127.0.0.1"].name=="Host_User":passed+=1
	host.stop();client.stop()
	if host.socket==null and client.socket==null:passed+=1
	print("RESULT ",passed," passed / ",3-passed," failed");get_tree().quit(3-passed)
