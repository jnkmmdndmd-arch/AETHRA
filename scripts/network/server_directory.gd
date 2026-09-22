extends Node

signal servers_changed(servers)
const DISCOVERY_PORT := 31002
const PACKET_PREFIX := "AETHRA_DISCOVERY_V1"
var favorites:Array[Dictionary]=[]
var discovered:Dictionary={}
var udp:=PacketPeerUDP.new()
var broadcast_enabled:=false
var timer:=0.0
var global_url: String = ""
var request: HTTPRequest

func _ready()->void:
    global_url=OS.get_environment("AETHRA_SERVER_DIRECTORY_URL").strip_edges().trim_suffix("/")
    request=HTTPRequest.new(); add_child(request); request.timeout=5.0
    load_favorites(); udp.set_broadcast_enabled(true)
    request.request_completed.connect(_on_request_completed)
    broadcast_enabled=udp.bind(DISCOVERY_PORT,"0.0.0.0")==OK

func _process(delta:float)->void:
    timer-=delta
    if timer<=0.0:
        timer=2.5
        if broadcast_enabled: _broadcast_query()
        _refresh_global()
    if not broadcast_enabled: return
    while udp.get_available_packet_count()>0:
        var packet:=udp.get_packet().get_string_from_utf8()
        if not packet.begins_with(PACKET_PREFIX+"|"): continue
        var payload=JSON.parse_string(packet.substr((PACKET_PREFIX+"|").length()))
        if not (payload is Dictionary): continue
        var ip:=udp.get_packet_ip()
        if bool(payload.get("query",false)):
            if AppState.is_server:
                var response={"name":str(AppState.current_world_name),"port":NetworkManager.DEFAULT_PORT,"players":NetworkManager.remote_players.size(),"max_players":NetworkManager.MAX_PEERS,"mode":AppState.game_mode,"seed":AppState.world_seed}
                udp.set_dest_address(ip,DISCOVERY_PORT); udp.put_packet((PACKET_PREFIX+"|"+JSON.stringify(response)).to_utf8_buffer())
            continue
        payload["address"]="%s:%d" % [ip,int(payload.get("port",31001))]
        payload["last_seen"]=Time.get_ticks_msec()
        discovered[str(payload["address"])]=payload
        servers_changed.emit(all_servers())

func _refresh_global()->void:
    if global_url.is_empty() or request==null or request.get_http_client_status()!=HTTPClient.STATUS_DISCONNECTED: return
    request.request(global_url+"/v1/servers",PackedStringArray(["Accept: application/json"]),HTTPClient.METHOD_GET)

func _broadcast_query()->void:
    udp.set_dest_address("255.255.255.255",DISCOVERY_PORT)
    udp.put_packet((PACKET_PREFIX+"|"+JSON.stringify({"query":true})).to_utf8_buffer())

func _on_request_completed(result:int,response_code:int,_headers:PackedStringArray,body:PackedByteArray)->void:
    if result!=HTTPRequest.RESULT_SUCCESS or response_code<200 or response_code>=300: return
    var data=JSON.parse_string(body.get_string_from_utf8())
    if not (data is Array): return
    for row in data:
        if row is Dictionary and str(row.get("address", ""))!="":
            var normalized: Dictionary = row.duplicate(true)
            normalized["source"]="global"
            discovered[str(row.get("address"))]=normalized
    servers_changed.emit(all_servers())

func all_servers()->Array[Dictionary]:
    var out:Array[Dictionary]=[]; out.append_array(favorites)
    for key in discovered: out.append(discovered[key].duplicate(true))
    return out

func load_favorites()->void:
    if FileAccess.file_exists("user://server_favorites.json"):
        var f:=FileAccess.open("user://server_favorites.json",FileAccess.READ)
        var data=JSON.parse_string(f.get_as_text()); f.close()
        if data is Array: favorites.assign(data)
    servers_changed.emit(all_servers())
func add_favorite(address:String,name:String="Favorite")->void:
    for server in favorites:
        if server.get("address","")==address: return
    favorites.append({"name":name,"address":address,"last_seen":Time.get_datetime_string_from_system(true)}); _save()
func remove_favorite(address:String)->void:
    favorites=favorites.filter(func(s):return s.get("address","")!=address); _save()
func recent()->Array[Dictionary]: return all_servers()
func _save()->void:
    var f:=FileAccess.open("user://server_favorites.json",FileAccess.WRITE)
    if f: f.store_string(JSON.stringify(favorites)); f.flush(); f.close()
    servers_changed.emit(all_servers())