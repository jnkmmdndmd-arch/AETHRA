extends Node

signal connected
signal disconnected
signal player_presence_changed(players)
signal chat_received(sender, text)
signal world_state_received(data)
signal block_update_received(pos, id)
signal connection_error(text)
signal player_state_changed(players)
signal inventory_snapshot_received(snapshot)

const DEFAULT_PORT := 31001
const MAX_PEERS := 32
var peer: ENetMultiplayerPeer
var server_started := false
var remote_players: Dictionary = {}
var player_snapshot_timer := 0.0
var player_state_accumulator := 0.0
var bound_world: Node = null
var accepted_peers: Dictionary = {}
var auth_secret := ""
var server_inventories: Dictionary = {}
var connection_state := "offline"
var server_max_peers := MAX_PEERS

func host(port: int = DEFAULT_PORT, max_peers: int = MAX_PEERS) -> Error:
    peer = ENetMultiplayerPeer.new()
    server_max_peers = clampi(max_peers, 1, MAX_PEERS)
    var error := peer.create_server(port, server_max_peers)
    if error != OK:
        connection_error.emit("Server creation failed: %s" % error)
        return error
    multiplayer.multiplayer_peer = peer
    server_started = true
    connection_state = "hosting"
    _wire_signals()
    return OK

func join(address: String, port: int = DEFAULT_PORT) -> Error:
    peer = ENetMultiplayerPeer.new()
    var error := peer.create_client(address.strip_edges(), port)
    if error != OK:
        connection_error.emit("Connection failed: %s" % error)
        return error
    multiplayer.multiplayer_peer = peer
    server_started = false
    connection_state = "connecting"
    _wire_signals()
    return OK

func bind_world(voxel_world: Node) -> void:
    bound_world = voxel_world
    auth_secret = OS.get_environment("AETHRA_AUTH_SECRET").strip_edges()

func _wire_signals() -> void:
    if not multiplayer.connected_to_server.is_connected(_on_connected):
        multiplayer.connected_to_server.connect(_on_connected)
    if not multiplayer.connection_failed.is_connected(_on_connection_failed):
        multiplayer.connection_failed.connect(_on_connection_failed)
    if not multiplayer.server_disconnected.is_connected(_on_disconnected):
        multiplayer.server_disconnected.connect(_on_disconnected)
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)
    if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _process(delta: float) -> void:
    player_snapshot_timer -= delta
    if player_snapshot_timer <= 0.0 and multiplayer.multiplayer_peer != null:
        player_snapshot_timer = 0.1
    player_state_accumulator = maxf(0.0, player_state_accumulator - delta)

@rpc("any_peer", "reliable")
func request_join(profile: Dictionary) -> void:
    if not multiplayer.is_server():
        return
    var id := multiplayer.get_remote_sender_id()
    var token := str(profile.get("token", ""))
    if token.is_empty():
        return
    if auth_secret.is_empty():
        return
    var token_identity := _decode_token(token)
    if token_identity.is_empty():
        return
    var player_name := str(token_identity.get("username", profile.get("name", "Player")))
    var character := str(token_identity.get("character", profile.get("character", "ranger")))
    if character not in ["ranger", "engineer", "shadow", "grove"]:
        character = "ranger"
    profile = {"name": player_name, "character": character}
    remote_players[id] = profile.duplicate(true)
    remote_players[id]["position"] = bound_world.spawn_position if bound_world != null else Vector3(8.5, 45.0, 8.5)
    remote_players[id]["yaw"] = 0.0
    accepted_peers[id] = true
    var inv = preload("res://scripts/gameplay/inventory.gd").new()
    inv.add_item(BlockRegistry.SOIL, 64)
    inv.add_item(BlockRegistry.STONE, 32)
    inv.add_item(BlockRegistry.LOG, 16)
    inv.add_item(ItemRegistry.WOOD_PICK, 1)
    server_inventories[id] = inv
    _broadcast_presence()
    var world_time := {}
    var time_node = get_tree().root.find_child("WorldTime", true, false)
    if time_node != null and time_node.has_method("serialize"):
        world_time = time_node.serialize()
    var world_settings := AppState.world_settings.duplicate(true)
    rpc_id(id, "receive_world_state", {
        "world_id": AppState.current_world_id,
        "name": AppState.current_world_name,
        "seed": AppState.world_seed,
        "mode": AppState.game_mode,
        "world_version": AppState.WORLD_VERSION,
        "protocol_version": AppState.PROTOCOL_VERSION,
        "delta": bound_world.save_delta() if bound_world != null and bound_world.has_method("save_delta") else {},
        "world_time": world_time,
        "difficulty": world_settings.get("difficulty", "normal"),
        "privacy": world_settings.get("privacy", "public"),
        "structures": world_settings.get("structures", true),
        "creatures": world_settings.get("creatures", true),
        "weather": world_settings.get("weather", true),
        "spawn": remote_players[id]["position"],
    })
    rpc_id(id, "receive_inventory_snapshot", inv.serialize())

func publish_local_player_state(position: Vector3, yaw: float, character: String) -> void:
    if multiplayer.multiplayer_peer == null or player_state_accumulator > 0.0:
        return
    player_state_accumulator = 0.1
    if multiplayer.is_server():
        remote_players[1] = {
            "name": AppState.player_name,
            "character": AppState.character_id,
            "position": position,
            "yaw": yaw
        }
        _broadcast_player_states()
    else:
        request_player_state.rpc_id(1, position, yaw, character)

@rpc("any_peer", "unreliable")
func request_player_state(position: Vector3, yaw: float, character: String) -> void:
    if not multiplayer.is_server():
        return
    var sender := multiplayer.get_remote_sender_id()
    if not accepted_peers.get(sender, false):
        return
    if is_nan(position.x) or is_inf(position.x) or is_nan(position.y) or is_inf(position.y) or is_nan(position.z) or is_inf(position.z):
        return
    if position.y < -32.0 or position.y > 512.0:
        return
    var previous: Dictionary = remote_players.get(sender, {})
    var previous_pos: Vector3 = previous.get("position", position)
    if is_nan(yaw) or is_inf(yaw) or previous_pos.distance_to(position) > 3.0:
        return
    remote_players[sender]["position"] = position
    remote_players[sender]["yaw"] = fmod(yaw, TAU)
    remote_players[sender]["character"] = remote_players[sender].get("character", "ranger")
    _broadcast_player_states()

func _broadcast_player_states() -> void:
    var snapshot := {}
    for id in remote_players:
        var row: Dictionary = remote_players[id]
        if row.has("position"):
            snapshot[id] = {
                "name": row.get("name", "Player"),
                "character": row.get("character", "ranger"),
                "position": row.get("position", Vector3.ZERO),
                "yaw": float(row.get("yaw", 0.0))
            }
    rpc("receive_player_states", snapshot)

@rpc("authority", "unreliable")
func receive_player_states(players: Dictionary) -> void:
    player_state_changed.emit(players.duplicate(true))

@rpc("any_peer", "reliable")
func request_block_change(pos: Vector3i, new_id: int, held_item_id: int = ItemRegistry.EMPTY) -> void:
    if not multiplayer.is_server():
        return
    var sender := multiplayer.get_remote_sender_id()
    if not accepted_peers.get(sender, false):
        return
    if not _validate_block_change(sender, pos, new_id, held_item_id):
        return
    var inventory: Variant = server_inventories.get(sender)
    if inventory == null or bound_world == null:
        return
    var current: int = int(bound_world.get_block(pos))
    if new_id == BlockRegistry.AIR:
        var drop := BlockRegistry.get_drop(current)
        if not inventory.can_add_item(drop, 1):
            return
        if bound_world.set_block(pos, BlockRegistry.AIR):
            inventory.add_item(drop, 1)
            rpc("receive_block_change", pos, BlockRegistry.AIR)
            rpc_id(sender, "receive_inventory_snapshot", inventory.serialize())
    else:
        if inventory.count_item(held_item_id) <= 0:
            return
        if not bound_world.set_block(pos, new_id):
            return
        inventory.remove_item(held_item_id, 1)
        rpc("receive_block_change", pos, new_id)
        rpc_id(sender, "receive_inventory_snapshot", inventory.serialize())


func apply_host_block_change(pos: Vector3i, new_id: int) -> void:
    if not multiplayer.is_server() or multiplayer.multiplayer_peer == null:
        return
    rpc("receive_block_change", pos, new_id)

@rpc("authority", "reliable")
func receive_block_change(pos: Vector3i, new_id: int) -> void:
    if bound_world != null and bound_world.has_method("set_block"):
        bound_world.set_block(pos, new_id)
    block_update_received.emit(pos, new_id)


@rpc("authority", "reliable")
func receive_inventory_snapshot(snapshot: Array) -> void:
    inventory_snapshot_received.emit(snapshot.duplicate(true))

@rpc("authority", "reliable")
func receive_world_state(data: Dictionary) -> void:
    world_state_received.emit(data.duplicate(true))

@rpc("any_peer", "reliable")
func send_chat(text: String) -> void:
    if not multiplayer.is_server():
        return
    var sender := multiplayer.get_remote_sender_id()
    if not accepted_peers.get(sender, false):
        return
    var message := text.strip_edges().substr(0, 240)
    if message.is_empty():
        return
    var name := str(remote_players.get(sender, {}).get("name", "Player"))
    rpc("receive_chat", name, message)

@rpc("authority", "reliable")
func receive_chat(sender: String, text: String) -> void:
    chat_received.emit(sender, text)

func _broadcast_presence() -> void:
    rpc("receive_presence", remote_players)

@rpc("authority", "reliable")
func receive_presence(players: Dictionary) -> void:
    remote_players = players.duplicate(true)
    player_presence_changed.emit(remote_players)

func _verify_token(token: String) -> bool:
    var parts := token.split(".")
    if parts.size() != 2:
        return false
    var encoded := parts[0].replace("-", "+").replace("_", "/")
    while encoded.length() % 4 != 0:
        encoded += "="
    var body := Marshalls.base64_to_utf8(encoded)
    if body.is_empty():
        return false
    var mac := Crypto.new().hmac_digest(HashingContext.HASH_SHA256, auth_secret.to_utf8_buffer(), body.to_utf8_buffer()).hex_encode()
    if not hash_equals(mac, parts[1]):
        return false
    var fields := body.split("|")
    if fields.size() != 5 or not str(fields[4]).is_valid_int():
        return false
    return Time.get_unix_time_from_system() <= float(fields[4])

func hash_equals(a: String, b: String) -> bool:
    if a.length() != b.length():
        return false
    var same := 0
    for i in a.length():
        same |= a.unicode_at(i) ^ b.unicode_at(i)
    return same == 0

func _validate_block_change(peer_id: int, pos: Vector3i, new_id: int, held_item_id: int) -> bool:
    if pos.y < 0 or pos.y >= 96:
        return false
    if new_id < BlockRegistry.AIR or new_id > BlockRegistry.LAST_BLOCK:
        return false
    if bound_world == null or remote_players.get(peer_id, {}).is_empty():
        return false
    var state: Dictionary = remote_players.get(peer_id, {})
    var player_position: Vector3 = state.get("position", Vector3.ZERO)
    if player_position.distance_to(Vector3(pos) + Vector3.ONE * 0.5) > 8.0:
        return false
    var inventory: Variant = server_inventories.get(peer_id)
    if inventory == null:
        return false
    var current: int = int(bound_world.get_block(pos))
    if new_id == BlockRegistry.AIR:
        if current == BlockRegistry.BEDROCK or current == BlockRegistry.AIR:
            return false
        var block := BlockRegistry.get_block(current)
        var required_tool := str(block.get("tool", ""))
        var effective_item := held_item_id if held_item_id != ItemRegistry.EMPTY else ItemRegistry.HAND
        if not _tool_matches(effective_item, required_tool):
            return false
        if required_tool != "" and inventory.count_item(effective_item) <= 0:
            return false
    else:
        if current != BlockRegistry.AIR:
            return false
        if inventory.count_item(held_item_id) <= 0:
            return false
        if _held_block_id(held_item_id) != new_id:
            return false
    var target := BlockRegistry.get_block(new_id if new_id != BlockRegistry.AIR else current)
    return not target.is_empty() and (new_id != BlockRegistry.AIR or float(target.get("hardness", 0.0)) >= 0.0)

func _held_block_id(item_id: int) -> int:
    if item_id > BlockRegistry.AIR and item_id <= BlockRegistry.LAST_BLOCK:
        if item_id in [BlockRegistry.WATER, BlockRegistry.LAVA, BlockRegistry.BEDROCK]:
            return BlockRegistry.AIR
        return item_id
    return BlockRegistry.AIR

func _tool_matches(item_id: int, required_tool: String) -> bool:
    if required_tool.is_empty():
        return true
    var item := ItemRegistry.get_item(item_id)
    if str(item.get("category", "")) != "tool":
        return false
    var name := str(item.get("name", "")).to_lower()
    return (required_tool == "pickaxe" and "pick" in name) or (required_tool == "axe" and "axe" in name) or (required_tool == "shovel" and "shovel" in name) or required_tool == "shears"

func _decode_token(token: String) -> Dictionary:
    var parts := token.split(".")
    if parts.size() != 2 or not _verify_token(token):
        return {}
    var encoded := parts[0].replace("-", "+").replace("_", "/")
    while encoded.length() % 4 != 0:
        encoded += "="
    var body := Marshalls.base64_to_utf8(encoded)
    var fields := body.split("|")
    if fields.size() != 5:
        return {}
    if not str(fields[4]).is_valid_int():
        return {}
    return {"user_id": fields[0], "username": fields[1], "character": fields[2], "avatar_id": clampi(int(fields[3]), 0, 29), "expires_at": int(fields[4])}

func _on_connected() -> void:
    connection_state = "connected"
    connected.emit()
    request_join.rpc({"name": AppState.player_name, "character": AppState.character_id, "token": AppState.auth_token})

func _on_connection_failed() -> void:
    connection_state = "offline"
    connection_error.emit("Unable to connect to the game server.")
    multiplayer.multiplayer_peer = null

func _on_disconnected() -> void:
    server_started = false
    connection_state = "offline"
    remote_players.clear()
    accepted_peers.clear()
    server_inventories.clear()
    disconnected.emit()

func _on_peer_connected(id: int) -> void:
    if multiplayer.is_server():
        remote_players[id] = {"name": "Player-%d" % id, "character": "ranger", "position": Vector3.ZERO, "yaw": 0.0}
        _broadcast_presence()

func _on_peer_disconnected(id: int) -> void:
    remote_players.erase(id)
    accepted_peers.erase(id)
    server_inventories.erase(id)
    if multiplayer.is_server():
        _broadcast_presence()
    player_presence_changed.emit(remote_players)
