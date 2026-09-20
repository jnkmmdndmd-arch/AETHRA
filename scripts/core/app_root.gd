extends Node3D

var menu: Control
var settings_menu: Control
var world: Node3D
var player
var creatures: Node3D
var hud
var console: Control
var time_system
var auth
var menu_visible := true
var autosave_timer := 30.0
var remote_players_root: Node3D
var remote_player_nodes: Dictionary = {}

func _ready() -> void:
    randomize()
    DisplayServer.window_set_title("AETHRA: Wildbound — عبدالله لازم")
    get_window().min_size = Vector2i(1120, 680)
    _restore_window_state()
    _build_lighting()
    _build_auth()
    _build_menu()
    _build_remote_players_root()
    _wire_network_presence()
    _ensure_bootstrap_controls()

func _ensure_bootstrap_controls() -> void:
    Settings.apply_input_map()
    AudioManager.apply_settings()

func _restore_window_state() -> void:
    var width := int(Settings.get_value("window_width", 1366))
    var height := int(Settings.get_value("window_height", 768))
    get_window().size = Vector2i(clampi(width, 1120, 3840), clampi(height, 680, 2160))
    var mode := int(Settings.get_value("window_mode", 0))
    match mode:
        1: get_window().mode = Window.MODE_MAXIMIZED
        2: get_window().mode = Window.MODE_FULLSCREEN
        _: get_window().mode = Window.MODE_WINDOWED

func _save_window_state() -> void:
    var size := get_window().size
    Settings.values["window_width"] = size.x
    Settings.values["window_height"] = size.y
    match get_window().mode:
        Window.MODE_MAXIMIZED: Settings.values["window_mode"] = 1
        Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN: Settings.values["window_mode"] = 2
        _: Settings.values["window_mode"] = 0
    Settings.save_settings()

func _build_lighting() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := PhysicalSkyMaterial.new()
    sky_material.rayleigh_coefficient = 1.7
    sky_material.mie_coefficient = 0.004
    sky_material.sun_disk_scale = 1.2
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#7aa7d9")
    environment.ambient_light_energy = 0.85
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = environment
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-35,0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)
    time_system = load("res://scripts/world/world_time.gd").new()
    time_system.name = "WorldTime"
    add_child(time_system)
    time_system.setup(sun, environment)

func _build_remote_players_root() -> void:
    remote_players_root = Node3D.new()
    remote_players_root.name = "RemotePlayers"
    add_child(remote_players_root)

func _wire_network_presence() -> void:
    if not NetworkManager.player_state_changed.is_connected(_on_remote_player_states):
        NetworkManager.player_state_changed.connect(_on_remote_player_states)
    if not NetworkManager.player_presence_changed.is_connected(_on_remote_presence):
        NetworkManager.player_presence_changed.connect(_on_remote_presence)
    if not NetworkManager.inventory_snapshot_received.is_connected(_on_inventory_snapshot):
        NetworkManager.inventory_snapshot_received.connect(_on_inventory_snapshot)

func _on_remote_presence(players: Dictionary) -> void:
    for id in remote_player_nodes.keys():
        if not players.has(id) and int(id) != multiplayer.get_unique_id():
            var node = remote_player_nodes[id]
            if is_instance_valid(node):
                node.queue_free()
            remote_player_nodes.erase(id)

func _on_remote_player_states(players: Dictionary) -> void:
    for key in players:
        var id := int(key)
        if id == multiplayer.get_unique_id():
            continue
        var row: Dictionary = players[key]
        var node = remote_player_nodes.get(id)
        if node == null or not is_instance_valid(node):
            node = load("res://scripts/network/remote_player_avatar.gd").new()
            remote_players_root.add_child(node)
            node.setup(id, str(row.get("name", "Player")), str(row.get("character", "ranger")))
            remote_player_nodes[id] = node
        node.apply_state(row.get("position", Vector3.ZERO), float(row.get("yaw", 0.0)))

func _build_auth() -> void:
    auth = load("res://scripts/auth/auth_client.gd").new()
    add_child(auth)
    auth.configure(str(Settings.get_value("auth_server_url", "http://127.0.0.1:8090")))
    auth.success.connect(_on_auth_success)
    auth.failure.connect(_on_auth_failure)
    auth.session_invalid.connect(_on_saved_session_invalid)
    var saved_session := AppState.load_saved_session()
    var saved_token := str(saved_session.get("token", ""))
    if not saved_token.is_empty():
        AppState.character_id = str(saved_session.get("character", AppState.character_id))
        auth.restore_session(saved_token)

func _build_menu() -> void:
    menu = load("res://scripts/ui/main_menu.gd").new()
    add_child(menu)
    menu.build(self)
    menu.play_singleplayer.connect(_start_singleplayer)
    menu.host_multiplayer.connect(_host)
    menu.join_multiplayer.connect(_join)
    menu.open_settings.connect(_open_settings)

func _on_auth_success(profile: Dictionary) -> void:
    var token := str(profile.get("token", ""))
    AppState.set_session(str(profile.get("username", "Guest")), token)
    AppState.character_id = str(profile.get("character", AppState.character_id))
    if not token.is_empty():
        AppState.save_session()
    if menu and menu.has_method("refresh_profile"):
        menu.refresh_profile()

func _on_auth_failure(message: String) -> void:
    if menu and menu.has_method("notify_auth_failure"):
        menu.notify_auth_failure(message)

func _on_saved_session_invalid() -> void:
    AppState.set_session("Guest", "")
    AppState.clear_saved_session()

func _start_singleplayer() -> void:
    var config := AppState.pending_world_config.duplicate(true)
    if config.is_empty():
        config = {"name":"Aurora Valley", "seed":randi() % 2147480000, "mode":"survival"}
    _hide_menu()
    _start_world(int(config.get("seed", 7777)), str(config.get("name", "World")), str(config.get("mode", "survival")))

func _host() -> void:
    _hide_menu()
    var err := NetworkManager.host()
    if err != OK:
        _show_menu()
        return
    _start_world(randi() % 2147480000, "Host World", "survival")

func _join(address: String) -> void:
    _hide_menu()
    var normalized := address.strip_edges()
    var parts := normalized.split(":")
    var host := parts[0]
    var port := int(parts[1]) if parts.size() > 1 and parts[1].is_valid_int() else NetworkManager.DEFAULT_PORT
    var err := NetworkManager.join(host, port)
    if err != OK:
        _show_menu()
        return
    if not NetworkManager.connected.is_connected(_start_remote_after_connect):
        NetworkManager.connected.connect(_start_remote_after_connect, CONNECT_ONE_SHOT)
    NetworkManager.connection_error.connect(_on_remote_connection_error, CONNECT_ONE_SHOT)
    if not NetworkManager.world_state_received.is_connected(_on_remote_world_state):
        NetworkManager.world_state_received.connect(_on_remote_world_state, CONNECT_ONE_SHOT)

func _start_remote_after_connect() -> void:
    # The server sends authoritative world metadata immediately after request_join succeeds.
    if menu and menu.has_method("set_connection_status"):
        menu.set_connection_status("متصل — بانتظار بيانات العالم من الخادم")

func _on_remote_world_state(data: Dictionary) -> void:
    if not data.has("seed"):
        _show_menu()
        return
    if int(data.get("world_version", AppState.WORLD_VERSION)) != AppState.WORLD_VERSION or int(data.get("protocol_version", AppState.PROTOCOL_VERSION)) != AppState.PROTOCOL_VERSION:
        _on_remote_connection_error("إصدار العميل/السيرفر غير متوافق.")
        return
    AppState.pending_world_config = {
        "name": str(data.get("name", "Remote World")),
        "seed": int(data.get("seed", 7777)),
        "mode": str(data.get("mode", "survival")),
        "difficulty": str(data.get("difficulty", "normal")),
        "privacy": str(data.get("privacy", "private")),
        "structures": bool(data.get("structures", true)),
        "creatures": bool(data.get("creatures", true)),
        "weather": bool(data.get("weather", true)),
        "remote": true,
        "world_id": str(data.get("world_id", "")),
        "server_delta": data.get("delta", {}),
        "world_time": data.get("world_time", {}),
        "spawn": data.get("spawn", Vector3(8.5, 45.0, 8.5)),
    }
    _start_world(int(data.get("seed", 7777)), str(data.get("name", "Remote World")), str(data.get("mode", "survival")))

func data_has_time(data: Dictionary) -> bool:
    return data.has("world_time") and data.get("world_time") is Dictionary and not data.get("world_time").is_empty()

func _on_remote_connection_error(_message: String) -> void:
    _show_menu()

func _start_world(seed_value: int, world_name: String, mode: String) -> void:
    if world != null:
        world.queue_free()
    var configured_world_id := str(AppState.pending_world_config.get("world_id", ""))
    var world_id := configured_world_id if not configured_world_id.is_empty() else "world-%d" % seed_value
    AppState.set_world(world_id, world_name, seed_value, mode)
    world = load("res://scripts/world/voxel_world.gd").new()
    add_child(world)
    world.initialize(seed_value)
    var config := AppState.pending_world_config.duplicate(true)
    AppState.world_settings = config.duplicate(true)
    if world.has_method("configure"):
        world.configure(config)
    if time_system:
        time_system.weather_enabled = bool(config.get("weather", true))
    var resume_id := str(AppState.pending_world_config.get("resume_id", ""))
    var remote_world := bool(AppState.pending_world_config.get("remote", false))
    if remote_world:
        var remote_delta: Dictionary = AppState.pending_world_config.get("server_delta", {})
        if remote_delta is Dictionary:
            world.load_delta(remote_delta)
        if time_system and data_has_time(AppState.pending_world_config):
            time_system.deserialize(AppState.pending_world_config.get("world_time", {}))
    elif not resume_id.is_empty():
        var saved := SaveDB.load_world(resume_id)
        if not saved.is_empty():
            world.load_delta(saved.get("blocks", {}))
            var saved_meta: Dictionary = saved.get("metadata", {})
            var saved_settings = saved_meta.get("settings", {})
            if saved_settings is Dictionary:
                AppState.world_settings = saved_settings.duplicate(true)
                if world.has_method("configure"):
                    world.configure(saved_settings)
                if time_system:
                    time_system.weather_enabled = bool(saved_settings.get("weather", true))
            if time_system and saved_meta.has("time"):
                time_system.deserialize(saved_meta["time"])
    NetworkManager.bind_world(world)
    var spawn: Vector3 = world.spawn_position
    player = load("res://scripts/player/player_avatar.gd").new()
    add_child(player)
    var authoritative_spawn: Variant = config.get("spawn", spawn)
    player.position = authoritative_spawn if authoritative_spawn is Vector3 else spawn
    player.add_to_group("players")
    player.setup(world, true, multiplayer.get_unique_id())
    if not remote_world and not resume_id.is_empty():
        var saved_player: Dictionary = SaveDB.load_world(resume_id).get("player", {})
        if saved_player is Dictionary:
            player.position = saved_player.get("position", spawn)
            player.survival.health = float(saved_player.get("health", player.survival.health))
            player.survival.hunger = float(saved_player.get("hunger", player.survival.hunger))
            player.survival.xp = int(saved_player.get("xp", player.survival.xp))
            var inv_data: Array = saved_player.get("inventory", [])
            if inv_data is Array:
                player.inventory.deserialize(inv_data)
    if not remote_world and resume_id.is_empty():
        player.inventory.add_item(BlockRegistry.SOIL, 64)
        player.inventory.add_item(BlockRegistry.STONE, 32)
        player.inventory.add_item(BlockRegistry.LOG, 16)
        player.inventory.add_item(ItemRegistry.WOOD_PICK, 1)
        var starting_inventory: Dictionary = config.get("starting_inventory", {})
        if starting_inventory is Dictionary:
            for item_id in starting_inventory:
                player.inventory.add_item(int(item_id), int(starting_inventory[item_id]))
    if not remote_world:
        creatures = load("res://scripts/entities/spawn_manager.gd").new()
        add_child(creatures)
        creatures.setup(world, bool(config.get("creatures", true)))
    _build_hud()
    _build_console()
    if not remote_world:
        SaveDB.save_world(AppState.current_world_id, {"name": world_name, "seed": seed_value, "mode": mode, "time": time_system.serialize() if time_system else {}, "settings": config.duplicate(true)}, world.save_delta(), _player_save())
    AppState.pending_world_config.clear()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_hud() -> void:
    hud = load("res://scripts/ui/hud.gd").new()
    add_child(hud)
    hud.build()
    if not NetworkManager.player_presence_changed.is_connected(hud.set_players):
        NetworkManager.player_presence_changed.connect(hud.set_players)
    hud.set_inventory(player.inventory)
    if not player.survival.health_changed.is_connected(_on_player_health):
        player.survival.health_changed.connect(_on_player_health)
    _update_hud()

func _on_inventory_snapshot(snapshot: Array) -> void:
    if player == null or snapshot.is_empty():
        return
    player.inventory.deserialize(snapshot)

func _on_player_health(_health, _max_health) -> void:
    _update_hud()

func _build_console() -> void:
    console = load("res://scripts/tools/dev_console.gd").new()
    console.build(self)

func toggle_developer_console() -> void:
    if console:
        console.toggle()

func _update_hud() -> void:
    if hud == null or player == null:
        return
    hud.set_player_stats(player.survival.health, player.survival.hunger, player.survival.stamina, Engine.get_frames_per_second())

func _open_settings(_return_page: String = "home") -> void:
    if settings_menu != null and is_instance_valid(settings_menu):
        return
    if menu:
        menu.hide()
    settings_menu = load("res://scripts/ui/settings_menu.gd").new()
    add_child(settings_menu)
    settings_menu.build(self)
    settings_menu.closed.connect(func():
        settings_menu.queue_free()
        settings_menu = null
        if menu:
            menu.show()
    )

func _hide_menu() -> void:
    if menu:
        menu.hide()
    menu_visible = false

func _show_menu() -> void:
    menu_visible = true
    if menu:
        menu.show()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.physical_keycode == KEY_F8 and console:
            console.toggle()
        elif event.physical_keycode == KEY_ESCAPE:
            if player != null:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        elif event.physical_keycode == KEY_F11:
            var mode := DisplayServer.window_get_mode()
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _process(delta: float) -> void:
    if world != null and player != null and world.has_method("set_stream_center"):
        world.set_stream_center(player.global_position)
        NetworkManager.publish_local_player_state(player.global_position, player.rotation.y, AppState.character_id)
        autosave_timer -= delta
        if autosave_timer <= 0.0 and not AppState.current_world_id.is_empty() and not bool(AppState.pending_world_config.get("remote", false)):
            autosave_timer = 30.0
            SaveDB.save_world(
                AppState.current_world_id,
                {"name": AppState.current_world_name, "seed": AppState.world_seed, "mode": AppState.game_mode, "time": time_system.serialize() if time_system else {}, "settings": AppState.world_settings.duplicate(true)},
                world.save_delta(),
                _player_save()
            )

func request_close() -> void:
    if world != null and player != null and not AppState.current_world_id.is_empty():
        SaveDB.save_world(AppState.current_world_id, {"name": AppState.current_world_name, "seed": AppState.world_seed, "mode": AppState.game_mode, "time": time_system.serialize() if time_system else {}, "settings": AppState.world_settings.duplicate(true)}, world.save_delta(), _player_save())
    _save_window_state()
    get_tree().quit()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        request_close()

func _player_save() -> Dictionary:
    if player == null:
        return {}
    return {"position": player.position, "health": player.survival.health, "hunger": player.survival.hunger, "xp": player.survival.xp, "inventory": player.inventory.serialize()}
