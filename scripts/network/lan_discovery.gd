class_name LanDiscovery
extends RefCounted
const ANDROID_LOCK=preload("res://scripts/network/android_discovery_lock.gd")
var android_lock=ANDROID_LOCK.new()
var socket: PacketPeerUDP
var hosting:=false
var found: Dictionary={}
var next_query:=0.0
var settings: LanConfig
var info: Dictionary={}
func stop() -> void:
	android_lock.release()
	if socket!=null:socket.close()
	socket=null
	found.clear()
func start(config: LanConfig, server: bool) -> Error:
	stop();settings=config;hosting=server;next_query=0
	socket=PacketPeerUDP.new()
	socket.set_broadcast_enabled(true)
	var error:=socket.bind(config.discovery_port if server else 0)
	if error!=OK:stop()
	else:android_lock.acquire()
	return error
func tick(delta: float) -> void:
	if socket==null:return
	next_query-=delta
	if not hosting and next_query<=0:
		next_query=2
		socket.set_dest_address("255.255.255.255",settings.discovery_port)
		socket.put_packet("POCKET_CROSSING_DISCOVER_1".to_utf8_buffer())
	for i in range(mini(16,socket.get_available_packet_count())):
		var bytes:=socket.get_packet()
		var ip:=socket.get_packet_ip()
		var port:=socket.get_packet_port()
		if bytes.size()>2048:continue
		if hosting:
			if bytes.get_string_from_utf8()=="POCKET_CROSSING_DISCOVER_1":
				socket.set_dest_address(ip,port)
				socket.put_packet(JSON.stringify(info).to_utf8_buffer())
		else:
			var data: Variant=JSON.parse_string(bytes.get_string_from_utf8())
			if data is Dictionary and data.get("tag")==settings.protocol and data.get("name") is String and data.name.length()<=16 and data.get("players") is float:
				data.ip=ip;data.seen=Time.get_ticks_msec()
				if found.size()<32 or found.has(ip):found[ip]=data
	for ip: String in found.keys():
		if Time.get_ticks_msec()-int(found[ip].seen)>6000:found.erase(ip)
static func addresses() -> PackedStringArray:
	var result:=PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.is_valid_ip_address() and not ip.contains(":") and not ip.begins_with("127.") and not ip.begins_with("169.254.") and ip!="0.0.0.0":result.append(ip)
	return result
