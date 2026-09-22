extends Node3D

var menu: Control
var menu_layer: CanvasLayer
var settings_menu: Control
var world: Node3D
var player
var creatures: Node3D
var hud
var time_system
var auth
var menu_visible := true
var autosave_timer := 30.0
var remote_players_root: Node3D
var remote_player_nodes: Dictionary = {}
var world_environment: Environment
var sun_light: DirectionalLight3D
var performance_scale := 1.0
var performance_sample_time := 0.0
var performance_frame_sum := 0.0
var performance_frame_count := 0
var performance_low_time := 0.0
var performance_high_time := 0.0
var java_engine_bridge
var java_backend_info: Dictionary = {}
const BOOT_LOG_PATH := "user://boot_log.txt"
var boot_started_at := 0
var boot_complete := false
var boot_watchdog_reported := false
var world_boot_elapsed := 0.0
var world_boot_reported := false
var boot_failure_message := ""

func _ready() -> void:
    boot_started_at = Time.get_ticks_msec()
    var boot_file := FileAccess.open(BOOT_LOG_PATH, FileAccess.WRITE)
    if boot_file != null:
        boot_file.store_line("AETHRA boot log")
        boot_file.close()
    _boot_log("boot_start")
    print("[BOOT] AETHRA: starting app root")
    randomize()
    var args := OS.get_cmdline_user_args()
    if DisplayServer.get_name() == "headless" or "--server" in args:
        var dedicated_script := load("res://server/main_server.gd") as GDScript
        if dedicated_script != null:
            var dedicated: Node = dedicated_script.new()
            dedicated.name = "DedicatedServer"
            add_child(dedicated)
        return
    DisplayServer.window_set_title("AETHRA: Wildbound — عبدالله لازم")
    get_window().min_size = Vector2i(960, 540)
    _restore_window_state()
    _boot_log("window_restored")
    _build_lighting()
    _boot_log("lighting_built")
    print("[BOOT] WorldEnvironment + sunlight initialized")
    _apply_graphics_profile()
    _boot_log("graphics_applied")
    if not Settings.settings_changed.is_connected(_apply_graphics_profile):
        Settings.settings_changed.connect(_apply_graphics_profile)
    _initialize_java_backend()
    _boot_log("java_backend_checked")
    _build_auth()
    _boot_log("auth_initialized")
    print("[BOOT] Auth service initialized (non-blocking)")
    _build_menu()
    _boot_log("main_menu_built")
    print("[BOOT] Main menu constructed and visible")
    _build_remote_players_root()
    _wire_network_presence()
    _boot_log("network_presence_ready")
    _ensure_bootstrap_controls()
    boot_complete = true
    _boot_log("boot_complete")

func _ensure_bootstrap_controls() -> void:
    Settings.apply_input_map()
    AudioManager.apply_settings()

func _boot_log(stage: String) -> void:
    var elapsed := 0
    if boot_started_at > 0:
        elapsed = Time.get_ticks_msec() - boot_started_at
    var line := "%dms %s" % [elapsed, stage]
    print("[BOOTLOG] ", line)
    var file := FileAccess.open(BOOT_LOG_PATH, FileAccess.READ_WRITE)
    if file == null:
        file = FileAccess.open(BOOT_LOG_PATH, FileAccess.WRITE)
    if file == null:
        push_error("[BOOTLOG] Unable to open " + BOOT_LOG_PATH)
        return
    file.seek_end()
    file.store_line(line)
    file.close()

func _restore_window_state() -> void:
    var width := int(Settings.get_value("window_width", 1280))
    var height := int(Settings.get_value("window_height", 720))
    get_window().size = Vector2i(clampi(width, 960, 3840), clampi(height, 540, 2160))
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
    print("[BOOT] Building WorldEnvironment")
    var env := WorldEnvironment.new()
    world_environment = Environment.new()
    var environment: Environment = world_environment
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("#1e4d78")
    sky_material.sky_horizon_color = Color("#8fc7e8")
    sky_material.ground_bottom_color = Color("#101820")
    sky_material.ground_horizon_color = Color("#668a9d")
    sky_material.sun_angle_max = 12.0
    sky_material.sun_curve = 0.08
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#7aa7d9")
    environment.ambient_light_energy = 0.85
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = environment
    add_child(env)
    if env.environment == null:
        push_error("[BOOT] FATAL: WorldEnvironment has no Environment resource.")
    else:
        print("[BOOT] WorldEnvironment ready background_mode=", env.environment.background_mode)
    sun_light = DirectionalLight3D.new()
    sun_light.rotation_degrees = Vector3(-55,-35,0)
    sun_light.light_energy = 1.15
    sun_light.shadow_enabled = false
    add_child(sun_light)
    time_system = load("res://scripts/world/world_time.gd").new()
    time_system.name = "WorldTime"
    add_child(time_system)
    time_system.setup(sun_light, environment)

func _apply_graphics_profile() -> void:
    if world_environment == null or sun_light == null:
        return
    var quality := str(Settings.get_value("graphics_quality", "low"))
    var base_scale := 0.75
    match quality:
        "medium":
            base_scale = 0.85
        "high", "ultra":
            base_scale = 1.0
        _:
            base_scale = 0.75

    performance_scale = base_scale
    Engine.max_fps = int({"low": 60, "medium": 90, "high": 120, "ultra": 144}.get(quality, 60))
    performance_sample_time = 0.0
    performance_frame_sum = 0.0
    performance_frame_count = 0
    performance_low_time = 0.0
    performance_high_time = 0.0

    var viewport := get_viewport()
    viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
    viewport.scaling_3d_scale = performance_scale
    sun_light.shadow_enabled = quality in ["high", "ultra"]
    world_environment.background_mode = Environment.BG_COLOR if quality == "low" else Environment.BG_SKY
    world_environment.background_color = Color("#17314b")
    world_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    world_environment.fog_enabled = quality != "low"

func _adaptive_resolution(delta: float) -> void:
    if world == null:
        return
    var quality := str(Settings.get_value("graphics_quality", "low"))
    if quality not in ["low", "medium"]:
        return

    performance_sample_time += delta
    performance_frame_sum += 1.0 / maxf(delta, 0.001)
    performance_frame_count += 1
    if performance_sample_time < 0.75 or performance_frame_count < 8:
        return

    var average_fps := performance_frame_sum / performance_frame_count
    var min_scale := 0.60 if quality == "low" else 0.70
    var max_scale := 0.85 if quality == "low" else 0.95

    if average_fps < 48.0:
        performance_low_time += performance_sample_time
        performance_high_time = 0.0
    elif average_fps > 60.0:
        performance_high_time += performance_sample_time
        performance_low_time = 0.0
    else:
        performance_low_time = maxf(0.0, performance_low_time - 0.25)
        performance_high_time = maxf(0.0, performance_high_time - 0.25)

    if performance_low_time >= 1.5:
        performance_scale = maxf(min_scale, performance_scale - 0.05)
        get_viewport().scaling_3d_scale = performance_scale
        performance_low_time = 0.0
    elif performance_high_time >= 2.0:
        performance_scale = minf(max_scale, performance_scale + 0.05)
        get_viewport().scaling_3d_scale = performance_scale
        performance_high_time = 0.0

    performance_sample_time = 0.0
    performance_frame_sum = 0.0
    performance_frame_count = 0

func _initialize_java_backend() -> void:
    var bridge_script := load("res://scripts/integration/java_engine_bridge.gd") as GDScript
    if bridge_script == null:
        push_warning("Java engine bridge script is unavailable; continuing with native AETHRA gameplay backend.")
        return
    java_engine_bridge = bridge_script.new()
    var source_path := str(Settings.get_value("java_source_project_path", "")).strip_edges()
    if not source_path.is_empty():
        java_backend_info = java_engine_bridge.inspect(ProjectSettings.globalize_path(source_path))
    else:
        var runtime_path := str(Settings.get_value("minecraft_runtime_path", "")).strip_edges()
        if runtime_path.is_empty():
            java_backend_info = {
                "kind": java_engine_bridge.BackendKind.UNAVAILABLE,
                "kind_name": "unavailable",
                "message": "No external Java backend configured."
            }
        else:
            java_backend_info = java_engine_bridge.inspect(ProjectSettings.globalize_path(runtime_path))
    if int(java_backend_info.get("kind", java_engine_bridge.BackendKind.UNAVAILABLE)) == java_engine_bridge.BackendKind.JAVA_SOURCE_PROJECT:
        print("Java gameplay backend source detected: ", java_backend_info.get("root", ""))
    elif int(java_backend_info.get("kind", java_engine_bridge.BackendKind.UNAVAILABLE)) == java_engine_bridge.BackendKind.MINECRAFT_RUNTIME_PACKAGE:
        print("Minecraft Java runtime detected as external content/runtime; AETHRA native gameplay remains authoritative.")

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
    auth.configure(str(Settings.get_value("auth_server_url", "")))
    auth.success.connect(_on_auth_success)
    auth.failure.connect(_on_auth_failure)
    auth.session_invalid.connect(_on_saved_session_invalid)
    var saved_session := AppState.load_saved_session()
    var saved_token := str(saved_session.get("token", ""))
    if not saved_token.is_empty():
        AppState.character_id = str(saved_session.get("character", AppState.character_id))
        AppState.avatar_id = clampi(int(saved_session.get("avatar_id", AppState.avatar_id)), 0, AppState.MAX_AVATARS - 1)
        auth.restore_session(saved_token)

func _build_menu() -> void:
    menu_layer = CanvasLayer.new()
    menu_layer.name = "MainMenuLayer"
    menu_layer.layer = 100
    add_child(menu_layer)
    var menu_script := load("res://scripts/ui/main_menu.gd") as GDScript
    if menu_script == null or not menu_script.can_instantiate():
        push_error("[BOOT] FATAL: main_menu.gd could not be loaded/instantiated.")
        return
    menu = menu_script.new()
    menu_layer.add_child(menu)
    menu.build(self)
    print("[BOOT] main_menu.gd -> build() complete")
    menu.play_singleplayer.connect(_start_singleplayer)
    menu.host_multiplayer.connect(_host)
    menu.join_multiplayer.connect(_join)
    menu.open_settings.connect(_open_settings)

func _on_auth_success(profile: Dictionary) -> void:
    var token := str(profile.get("token", ""))
    AppState.set_session(str(profile.get("username", "Guest")), token)
    AppState.character_id = str(profile.get("character", AppState.character_id))
    AppState.avatar_id = clampi(int(profile.get("avatar_id", AppState.avatar_id)), 0, AppState.MAX_AVATARS - 1)
    AppState.save_profile(AppState.get_display_name(), AppState.avatar_id)
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
    print("[BOOT] PLAY: singleplayer requested from main menu")
    var config := AppState.pending_world_config.duplicate(true)
    if config.is_empty():
        config = {"name":"Aurora Valley", "seed":randi() % 2147480000, "mode":"survival"}
    _hide_menu()
    await _start_world(int(config.get("seed", 7777)), str(config.get("name", "World")), str(config.get("mode", "survival")))

func _host() -> void:
    print("[BOOT] PLAY: multiplayer host requested from main menu")
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
    _boot_log("world_start")
    print("[WORLD] start requested name=", world_name, " seed=", seed_value, " mode=", mode)
    world_boot_elapsed = 0.0
    world_boot_reported = false
    boot_failure_message = ""
    if world != null:
        world.queue_free()
    var configured_world_id := str(AppState.pending_world_config.get("world_id", ""))
    var world_id := configured_world_id if not configured_world_id.is_empty() else "world-%d" % seed_value
    AppState.set_world(world_id, world_name, seed_value, mode)
    var config := AppState.pending_world_config.duplicate(true)
    if not config.has("world_height"):
        var quality := str(Settings.get_value("graphics_quality", "low"))
        config["world_height"] = {"low": 96, "medium": 128, "high": 192, "ultra": 256}.get(quality, 96)
    AppState.world_settings = config.duplicate(true)
    var world_script := load("res://scripts/world/voxel_world.gd") as GDScript
    if world_script == null or not world_script.can_instantiate():
        push_error("[WORLD] FATAL: voxel_world.gd failed to load/instantiate.")
        _show_menu()
        return
    world = world_script.new()
    add_child(world)
    print("[WORLD] voxel_world node created")
    if world.has_method("configure"):
        world.configure(config)
    print("[WORLD] configuring generator/world height=", config.get("world_height", 96))
    world.initialize(seed_value)
    print("[WORLD] initialize() returned; spawn=", world.spawn_position, " ready=", world.is_ready_for_spawn() if world.has_method("is_ready_for_spawn") else false)
    _boot_log("world_initialized")
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
    print("[WORLD] NetworkManager bound (no network wait)")
    var spawn: Vector3 = world.spawn_position
    var player_script := load("res://scripts/player/player_avatar.gd") as GDScript
    if player_script == null or not player_script.can_instantiate():
        push_error("[WORLD] FATAL: player_avatar.gd failed to load/instantiate.")
        _abort_world_boot("Player script could not be loaded.")
        return
    player = player_script.new()
    add_child(player)
    var authoritative_spawn: Variant = config.get("spawn", spawn)
    player.position = authoritative_spawn if authoritative_spawn is Vector3 else spawn
    player.add_to_group("players")
    player.setup(world, true, multiplayer.get_unique_id())
    if player.camera == null:
        push_error("[WORLD] FATAL: player camera was not created.")
        _abort_world_boot("Camera creation failed.")
        return
    player.camera.current = true
    print("[WORLD] player + Camera3D ready current=", player.camera.current, " position=", player.position)
    _boot_log("player_camera_ready")
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
    print("[WORLD] HUD built; world boot completed from app perspective")
    _boot_log("world_boot_complete")
    if not remote_world:
        SaveDB.save_world(AppState.current_world_id, {"name": world_name, "seed": seed_value, "mode": mode, "time": time_system.serialize() if time_system else {}, "settings": config.duplicate(true)}, world.save_delta(), _player_save())
    AppState.pending_world_config.clear()
    # Start with the Windows pointer visible; the HUD captures it on the first click.
    # This prevents the cursor from seemingly disappearing when a new world opens.
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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
    print("[BOOT] Main menu hidden -> explicit gameplay transition")
    if menu:
        menu.hide()
    if menu_layer:
        menu_layer.hide()
    menu_visible = false

func _show_menu() -> void:
    print("[BOOT] Main menu shown")
    menu_visible = true
    if menu:
        menu.show()
    if menu_layer:
        menu_layer.show()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.physical_keycode == KEY_ESCAPE:
            if player != null:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        elif event.physical_keycode == KEY_F11:
            var mode := DisplayServer.window_get_mode()
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _process(delta: float) -> void:
    _adaptive_resolution(delta)
    if not boot_watchdog_reported and boot_complete and world == null and menu != null and not menu.visible:
        if Time.get_ticks_msec() - boot_started_at >= 8000:
            boot_watchdog_reported = true
            _boot_log("watchdog_menu_invisible")
            _show_boot_diagnostic()
    if world != null:
        world_boot_elapsed += delta
        if not world_boot_reported and world_boot_elapsed >= 2.5:
            var rendered_chunks := int(world.get_rendered_chunk_count()) if world.has_method("get_rendered_chunk_count") else -1
            if rendered_chunks <= 0:
                world_boot_reported = true
                boot_failure_message = "World exists but no rendered chunk is available after 2.5s."
                push_error("[WORLD] FATAL RENDER: " + boot_failure_message)
                _show_menu()
            else:
                world_boot_reported = true
                print("[WORLD] render watchdog: rendered_chunks=", rendered_chunks)

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

func _show_boot_diagnostic() -> void:
    if menu != null:
        menu.show()
        menu.modulate.a = 1.0
    if menu_layer == null:
        return
    var layer := CanvasLayer.new()
    layer.name = "BootDiagnostics"
    layer.layer = 1000
    add_child(layer)
    var panel := ColorRect.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.color = Color(0.015, 0.02, 0.035, 0.96)
    layer.add_child(panel)
    var label := Label.new()
    label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    label.offset_left = -360
    label.offset_top = -120
    label.offset_right = 360
    label.offset_bottom = 120
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 22)
    label.text = "AETHRA boot diagnostic\n\nالقائمة الرئيسية لم تصبح مرئية خلال 8 ثوانٍ.\nتحقق من user://boot_log.txt وملف Output."
    layer.add_child(label)

func _abort_world_boot(reason: String) -> void:
    boot_failure_message = reason
    push_error("[WORLD] BOOT ABORTED: " + reason)
    if hud != null and is_instance_valid(hud):
        hud.queue_free()
        hud = null
    if creatures != null and is_instance_valid(creatures):
        creatures.queue_free()
        creatures = null
    if player != null and is_instance_valid(player):
        player.queue_free()
        player = null
    if world != null and is_instance_valid(world):
        world.queue_free()
        world = null
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _show_menu()

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
