class_name LanSession
extends Node
## Exclusive transport owner. Only directions are accepted as gameplay input.
signal local_hurt(cause: String, at: Vector2)
var feedback_epoch:=""
var feedback_sequence:=0
signal changed
signal notice(text: String, priority: bool)
signal prepare_match(map_id: String, roster: Dictionary, seed_value: int)
signal snapshot_received(data: Dictionary)
signal command_received(peer_id: int, direction: Vector2i)
signal hazards_received(data: Dictionary)
signal results_received(rows: Array, receipt: String)
signal closed(reason: String)
var settings: LanConfig=preload("res://resources/network/lan.tres")
var peer: ENetMultiplayerPeer
var discovery:=LanDiscovery.new()
var members: Dictionary={}
var phase:="offline"
var map_id:="village_crossing"
var revision:=0
var seed_value:=42
var match_id:=""
var start_at:=0.0
var offset:=0.0
var target_offset:=0.0
var best_rtt:=INF
var clock_ready:=false
var last_received:=0.0
var last_ping:=0.0
var pending: Dictionary={}
var kicks: Dictionary={}
var sequences: Dictionary={}
var last_commands: Dictionary={}
var input_sequence:=0
var command_generation:=-1
var local_identity: Dictionary={}
var pending_ready:=-1
var result_rows: Array=[]
var snapshot_sequence:=0
var last_snapshot:=-1
var max_packet_bytes:=0
var selected_match_time:=120
var selected_ranking_mode:="time"
var results_at:=0.0
var result_awards: Array=[]
var match_participants: Array[int]=[]
func remaining() -> float:return maxf(0.0,selected_match_time-maxf(0.0,server_now()-start_at))
func expired() -> bool:return server_now()>=start_at+selected_match_time
func select_rules(duration: int, mode: String) -> void:
	if not is_host() or phase!="lobby" or duration not in LanMatchRules.DURATIONS or mode not in LanMatchRules.MODES:return
	selected_match_time=duration;selected_ranking_mode=mode
	_send_state() # Settings do not reload the map or invalidate readiness.
func time_up() -> void:
	if not is_host() or phase!="racing":return
	phase="time_up";results_at=now()+1.25;_send_state()
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	# Clients communicate only with the host; roster changes use authoritative RPCs.
	(multiplayer as SceneMultiplayer).server_relay=false
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func() -> void:leave("Could not connect. Check Wi-Fi, Host IP and firewall."))
	multiplayer.server_disconnected.connect(func() -> void:leave("Host disconnected."))
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
func now() -> float:return Time.get_ticks_msec()/1000.0
func server_now() -> float:return now()+(0.0 if is_host() else offset)
func local_id() -> int:return multiplayer.get_unique_id() if peer!=null else 0
func is_host() -> bool:return peer!=null and multiplayer.is_server()
func host(identity: Dictionary) -> Error:
	leave();local_identity=identity.duplicate()
	peer=ENetMultiplayerPeer.new()
	var error:=peer.create_server(settings.game_port,8,3)
	if error!=OK:peer=null;return error
	multiplayer.multiplayer_peer=peer
	members[1]=_member(identity)
	phase="lobby";clock_ready=true;map_id="village_crossing"
	discovery.start(settings,true)
	refresh_lobby()
	return OK
func join(ip: String, identity: Dictionary) -> Error:
	leave()
	if not ip.is_valid_ip_address() or ip.contains(":"):return ERR_INVALID_PARAMETER
	local_identity=identity.duplicate()
	peer=ENetMultiplayerPeer.new()
	var error:=peer.create_client(ip,settings.game_port,3)
	if error!=OK:peer=null;return error
	multiplayer.multiplayer_peer=peer
	phase="connecting";last_received=now();last_ping=0
	changed.emit()
	return OK
func scan() -> void:
	leave();phase="discovering";discovery.start(settings,false)
func leave(reason: String="") -> void:
	discovery.stop()
	if peer!=null:peer.close()
	peer=null
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	match_participants.clear();members.clear();pending.clear();kicks.clear();sequences.clear();last_commands.clear();result_rows.clear()
	phase="offline";revision=0;match_id="";start_at=0;offset=0;target_offset=0;best_rtt=INF
	selected_match_time=120;selected_ranking_mode="time";results_at=0;result_awards.clear()
	clock_ready=false;pending_ready=-1;last_snapshot=-1;input_sequence=0
	closed.emit(reason)
func _member(identity: Dictionary) -> Dictionary:
	var skin:=String(identity.get("skin","pip"))
	if CharacterCatalog.find_skin(skin).is_empty():skin="pip"
	return {"id":identity.get("id",""),"name":String(identity.get("name","")).strip_edges(),"skin":skin,"ready":false,"seen":now(),"connected":true}
func _connected() -> void:
	last_received=now()
	_hello.rpc_id(1,settings.content_version(),local_identity)
	_ping.rpc_id(1,now())
func _peer_connected(id: int) -> void:
	if is_host():pending[id]=now()
func _peer_disconnected(id: int) -> void:
	pending.erase(id);kicks.erase(id)
	if not is_host() or not members.has(id) or not members[id].connected:return
	if phase=="lobby":members.erase(id);refresh_lobby()
	else:
		members[id].connected=false
		if phase!="results":broadcast_event(String(members[id].name)+" DISCONNECTED",true)
		changed.emit()
		if phase=="loading":_schedule_if_ready()
func rejection(version: String, identity: Dictionary) -> String:
	if version!=settings.content_version():return "Game versions do not match."
	if phase!="lobby":return "Match already in progress."
	if members.size()>=settings.max_players:return "Lobby is full (4 players maximum)."
	if identity.size()>4:return "Invalid player identity."
	if not identity.get("name") is String or not Profiles.username_error(identity.name).is_empty():return "Invalid username."
	if not identity.get("id") is String or identity.id.length()!=32 or not identity.id.is_valid_hex_number():return "Invalid player identity."
	for member: Dictionary in members.values():
		if String(member.name).to_lower()==String(identity.name).strip_edges().to_lower():return "That username is already in this lobby. Rename your account in Settings and try again."
		if member.id==identity.id:return "This account is already connected."
	return ""
@rpc("any_peer","call_remote","reliable",0)
func _hello(version: String, identity: Dictionary) -> void:
	if not is_host():return
	var id:=multiplayer.get_remote_sender_id()
	if not pending.has(id) or members.has(id):return
	var reason:=rejection(version,identity)
	if not reason.is_empty():_rejected.rpc_id(id,reason);kicks[id]=now()+0.25;return
	members[id]=_member(identity);pending.erase(id);refresh_lobby()
@rpc("authority","call_remote","reliable",0)
func _rejected(reason: String) -> void:leave(reason)
func refresh_lobby() -> void:
	if not is_host():return
	revision+=1;seed_value=int(Time.get_ticks_msec())
	for id in members:members[id].ready=not members[id].connected
	prepare_match.emit(map_id,members.duplicate(true),seed_value)
	members[1].ready=true
	_send_state()
func _send_state() -> void:
	_lobby.rpc({"members":members,"map":map_id,"revision":revision,"seed":seed_value,"phase":phase,"start":start_at,"match":match_id,"duration":selected_match_time,"mode":selected_ranking_mode,"results_at":results_at})
	changed.emit()
@rpc("authority","call_remote","reliable",0)
func _lobby(data: Dictionary) -> void:
	last_received=now()
	var reload_map:=revision!=int(data.revision)
	if match_id!=String(data.match):input_sequence=0
	members=data.members;map_id=data.map;revision=data.revision;seed_value=data.seed;phase=data.phase;start_at=data.start;match_id=data.match
	selected_match_time=int(data.duration);selected_ranking_mode=String(data.mode);results_at=float(data.results_at)
	if reload_map:
		last_snapshot=-1
		prepare_match.emit(map_id,members.duplicate(true),seed_value)
		pending_ready=revision
		if clock_ready:_ack.rpc_id(1,revision);pending_ready=-1
	changed.emit()
func select_map(id: String) -> void:
	if not is_host() or phase!="lobby" or id not in Profiles.MAP_IDS or not Profiles.is_unlocked(id):return
	var config: MapConfig=load("res://resources/maps/"+id+".tres")
	if not config.map_errors().is_empty():return
	map_id=id;refresh_lobby()
func can_start() -> bool:
	if not is_host() or phase!="lobby" or members.size()<2:return false
	for member: Dictionary in members.values():
		if not member.ready:return false
	return true
func request_start() -> void:
	if not can_start():return
	phase="loading";match_id=Crypto.new().generate_random_bytes(16).hex_encode()
	sequences.clear();last_commands.clear();snapshot_sequence=0;input_sequence=0
	refresh_lobby();_schedule_if_ready()
@rpc("any_peer","call_remote","reliable",0)
func _ack(value: int) -> void:
	var id:=multiplayer.get_remote_sender_id()
	if not is_host() or not members.has(id) or value!=revision or phase not in ["lobby","loading"]:return
	if members[id].ready:return
	members[id].ready=true;_send_state();_schedule_if_ready()
func _schedule_if_ready() -> void:
	if phase!="loading":return
	for member: Dictionary in members.values():
		if member.connected and not member.ready:return
	start_at=now()+5.2;phase="countdown";_send_state()
func send_direction(direction: Vector2i, generation: int=-1) -> int:
	if phase!="racing" or expired():return 0
	input_sequence+=1
	if is_host():validate_command(1,match_id,input_sequence,direction,generation)
	else:_input_command.rpc_id(1,match_id,input_sequence,direction,generation)
	return input_sequence
@rpc("any_peer","call_remote","reliable",1)
func _input_command(epoch: String, sequence: int, direction: Vector2i, generation: int) -> void:
	if is_host():validate_command(multiplayer.get_remote_sender_id(),epoch,sequence,direction,generation)
func validate_command(id: int, epoch: String, sequence: int, direction: Vector2i, generation: int=-1) -> void:
	if phase!="racing" or expired() or epoch!=match_id or not members.has(id) or not members[id].connected or absi(direction.x)+absi(direction.y)!=1:return
	if sequence<=int(sequences.get(id,0)) or sequence>int(sequences.get(id,0))+10000:return
	sequences[id]=sequence;last_commands[id]=now();command_generation=generation;command_received.emit(id,direction)
func send_snapshot(data: Dictionary, recipient: int=0) -> void:
	if not is_host():return
	snapshot_sequence+=1
	var payload:=var_to_bytes(data).compress(FileAccess.COMPRESSION_DEFLATE)
	max_packet_bytes=maxi(max_packet_bytes,payload.size())
	if recipient>1:_snapshot.rpc_id(recipient,match_id,snapshot_sequence,payload)
	else:_snapshot.rpc(match_id,snapshot_sequence,payload)
@rpc("authority","call_remote","unreliable_ordered",2)
func _snapshot(epoch: String, sequence: int, payload: PackedByteArray) -> void:
	if epoch!=match_id or sequence<=last_snapshot or phase not in ["countdown","racing"] or payload.size()>32768:return
	var raw:=payload.decompress_dynamic(65536,FileAccess.COMPRESSION_DEFLATE)
	if raw.size()<4:return
	var data: Variant=bytes_to_var(raw)
	if not data is Dictionary:return
	last_received=now();last_snapshot=sequence;snapshot_received.emit(data)
func broadcast_event(text: String, important: bool=false) -> void:
	if not is_host():return
	notice.emit(text,important);_event.rpc(text,important)
@rpc("authority","call_remote","reliable",0)
func _event(text: String, important: bool) -> void:notice.emit(text,important)
func can_finalize(rows: Array) -> bool:
	if rows.is_empty():return false
	var seen: Dictionary={}
	for row: Dictionary in rows:
		var id:=int(row.get("peer",-1))
		if seen.has(id) or String(row.get("status","")) not in ["finished","out","disconnected","time_up"]:return false
		if row.get("status","")=="time_up" and not expired():return false
		seen[id]=true
	for id in match_participants:
		if not seen.has(id):return false
	for id in members:
		if members[id].get("connected",false) and not seen.has(id):return false
	return true
func finish(rows: Array) -> void:
	if not is_host() or phase not in ["racing","time_up"]:return
	if not can_finalize(rows):return
	result_awards=LanMatchRules.awards(rows)
	phase="results";result_rows=rows.duplicate(true)
	_results.rpc(match_id,result_rows,result_awards);results_received.emit(result_rows,match_id);changed.emit()
@rpc("authority","call_remote","reliable",0)
func _results(receipt: String, rows: Array, awards: Array=[]) -> void:
	if receipt!=match_id or phase=="results":return
	phase="results";result_rows=rows;result_awards=awards;results_received.emit(rows,receipt);changed.emit()
func return_lobby() -> void:
	if not is_host() or phase not in ["results","racing","countdown"]:return
	phase="lobby"
	for id in members.keys():
		if not members[id].connected:members.erase(id)
	refresh_lobby()
@rpc("any_peer","call_remote","unreliable",0)
func _ping(client_time: float) -> void:
	if not is_host() or not is_finite(client_time):return
	var id:=multiplayer.get_remote_sender_id()
	if not members.has(id):return
	members[id].seen=now();_pong.rpc_id(id,client_time,now())
@rpc("authority","call_remote","unreliable",0)
func _pong(sent: float, server_time: float) -> void:
	last_received=now()
	var rtt:=now()-sent
	if rtt<best_rtt:
		best_rtt=rtt;target_offset=server_time-(sent+now())*0.5
		if not clock_ready or phase not in ["countdown","racing"]:offset=target_offset
	clock_ready=true
	if pending_ready==revision and phase in ["lobby","loading"]:_ack.rpc_id(1,revision);pending_ready=-1
func _process(delta: float) -> void:
	# Refine synchronization without teleporting every timestamp-driven hazard.
	if not is_host():offset=move_toward(offset,target_offset,delta*0.025)
	discovery.info={"tag":settings.protocol,"name":local_identity.get("name","Host"),"players":members.size(),"map":map_id,"phase":phase}
	discovery.tick(delta)
	if peer==null:return
	if is_host():
		for id in kicks.keys():
			if now()>float(kicks[id]):peer.disconnect_peer(id);kicks.erase(id)
		for id in pending.keys():
			if now()-float(pending[id])>settings.timeout_seconds:peer.disconnect_peer(id);pending.erase(id)
		for id in members.keys():
			if id!=1 and members[id].connected and now()-float(members[id].seen)>settings.timeout_seconds:peer.disconnect_peer(id);_peer_disconnected(id)
		if phase=="countdown" and now()>=start_at:phase="racing";_send_state()
	else:
		if now()-last_received>settings.timeout_seconds:leave("Host disconnected or connection timed out.");return
		if now()-last_ping>1 and peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED:last_ping=now();_ping.rpc_id(1,now())

func send_hazards(data: Dictionary, reliable: bool) -> void:
	if not is_host():return
	var payload:=var_to_bytes(data).compress(FileAccess.COMPRESSION_DEFLATE)
	max_packet_bytes=maxi(max_packet_bytes,payload.size())
	if reliable:_hazard_event.rpc(match_id,payload)
	else:_hazard_frame.rpc(match_id,payload)
@rpc("authority","call_remote","reliable",2)
func _hazard_event(epoch: String, payload: PackedByteArray) -> void:_read_hazards(epoch,payload)
@rpc("authority","call_remote","unreliable_ordered",2)
func _hazard_frame(epoch: String, payload: PackedByteArray) -> void:_read_hazards(epoch,payload)
func _read_hazards(epoch: String, payload: PackedByteArray) -> void:
	if epoch!=match_id or phase not in ["countdown","racing"] or payload.size()>32768:return
	var data: Variant=bytes_to_var(payload.decompress_dynamic(65536,FileAccess.COMPRESSION_DEFLATE))
	if data is Dictionary:hazards_received.emit(data)

func send_hurt(peer: int, sequence: int, cause: String, at: Vector2) -> void:
	if not is_host():return
	if peer==local_id():_owner_hurt(match_id,sequence,cause,at)
	else:_owner_hurt.rpc_id(peer,match_id,sequence,cause,at)
@rpc("authority","call_remote","reliable",0)
func _owner_hurt(epoch: String, sequence: int, cause: String, at: Vector2) -> void:
	if epoch!=match_id or not HazardAudio.CATEGORIES.has(cause):return
	if feedback_epoch!=epoch:feedback_epoch=epoch;feedback_sequence=0
	if sequence<=feedback_sequence:return
	feedback_sequence=sequence;local_hurt.emit(cause,at)
