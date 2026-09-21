extends Node

var muted_peers:Dictionary = {}

func _admin_ids() -> Array[String]:
    var raw:=OS.get_environment("AETHRA_ADMIN_USER_IDS").strip_edges()
    var out:Array[String]=[]
    if raw.is_empty(): return out
    for part in raw.split(","):
        var id:=part.strip_edges()
        if not id.is_empty(): out.append(id)
    return out

func is_admin_peer(peer_id:int) -> bool:
    if not multiplayer.is_server(): return false
    var row:Dictionary=NetworkManager.remote_players.get(peer_id,{})
    return str(row.get("user_id","")) in _admin_ids()

func is_muted(peer_id:int)->bool:
    return bool(muted_peers.get(peer_id,false))

func mute(peer_id:int,value:bool)->void:
    if value: muted_peers[peer_id]=true
    else: muted_peers.erase(peer_id)

func clear_peer(peer_id:int)->void:
    muted_peers.erase(peer_id)

func command(peer_id:int,message:String)->bool:
    if not is_admin_peer(peer_id): return false
    var parts:=message.strip_edges().split(" ")
    if parts.is_empty(): return true
    match str(parts[0]).to_lower():
        "/kick":
            if parts.size()>1 and str(parts[1]).is_valid_int(): multiplayer.disconnect_peer(int(parts[1])); return true
        "/mute":
            if parts.size()>1 and str(parts[1]).is_valid_int(): mute(int(parts[1]),true); return true
        "/unmute":
            if parts.size()>1 and str(parts[1]).is_valid_int(): mute(int(parts[1]),false); return true
        "/save":
            if NetworkManager.bound_world != null:
                var root:=get_tree().root.find_child("AETHRA",true,false)
                if root!=null and root.has_method("save_game"): root.call("save_game")
            return true
    return false