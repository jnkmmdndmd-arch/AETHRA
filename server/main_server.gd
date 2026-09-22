extends Node

var world
var time_system
var autosave_timer := 0.0
var server_name := "Dedicated World"
var server_mode := "survival"
var server_difficulty := "normal"
var server_pvp := true
var server_port := 31001
var max_players := 32
var world_seed := 1234567

func _ready() -> void:
    if DisplayServer.get_name() != "headless" and "--server" not in OS.get_cmdline_user_args():
        queue_free()
        return
    AppState.is_server = true
    var config := _load_config()
    var args := OS.get_cmdline_user_args()
    if "--seed" in args:
        var i := args.find("--seed")
        if i + 1 < args.size():
            world_seed = int(args[i + 1])
    var saved: Dictionary = SaveDB.load_world("dedicated-world")
    if not saved.is_empty():
        var metadata: Dictionary = saved.get("metadata", {})
        world_seed = int(metadata.get("seed", world_seed))
        server_name = str(metadata.get("name", server_name))
        server_mode = str(metadata.get("mode", server_mode))
        server_difficulty = str(metadata.get("difficulty", server_difficulty))
        server_pvp = bool(metadata.get("pvp", server_pvp))
    var cli_port := _arg_int(args, "--port", -1)
    if cli_port > 0:
        server_port = cli_port
    world = load("res://scripts/world/voxel_world.gd").new()
    add_child(world)
    var settings := {
        "difficulty": server_difficulty,
        "privacy": "public",
        "structures": true,
        "creatures": true,
        "weather": true,
        "pvp": server_pvp,
        "world_height": 500,
        "world_radius": 32768,
    }
    if not saved.is_empty():
        var saved_settings = saved.get("metadata", {}).get("settings", {})
        if saved_settings is Dictionary:
            settings.merge(saved_settings, true)
    AppState.world_settings = settings.duplicate(true)
    server_difficulty = str(settings.get("difficulty", server_difficulty))
    server_pvp = bool(settings.get("pvp", server_pvp))
    if world.has_method("configure"):
        world.configure(settings)
    world.initialize(world_seed)
    if not saved.is_empty():
        world.load_delta(saved.get("blocks", {}))
    time_system = load("res://scripts/world/world_time.gd").new()
    time_system.name = "WorldTime"
    add_child(time_system)
    time_system.setup(null, null, bool(settings.get("weather", true)))
    if not saved.is_empty():
        var saved_time: Dictionary = saved.get("metadata", {}).get("time", {})
        if saved_time is Dictionary:
            time_system.deserialize(saved_time)
    AppState.set_world("dedicated-world", server_name, world_seed, server_mode)
    NetworkManager.bind_world(world)
    if NetworkManager.host(server_port, max_players) != OK:
        get_tree().quit(1)
        return
    print("AETHRA dedicated server online: port=%d seed=%d name=%s" % [server_port, world_seed, server_name])

func _process(delta: float) -> void:
    autosave_timer -= delta
    if autosave_timer <= 0.0:
        autosave_timer = 30.0
        if world:
            SaveDB.save_world("dedicated-world", {
                "name": server_name,
                "seed": world.world_seed,
                "mode": server_mode,
                "difficulty": server_difficulty,
                "pvp": server_pvp,
                "time": time_system.serialize() if time_system else {},
                "settings": AppState.world_settings.duplicate(true),
            }, world.save_delta(), {})

func _load_config() -> Dictionary:
    var path := OS.get_environment("AETHRA_SERVER_CONFIG").strip_edges()
    if path.is_empty():
        path = "res://server/server_config.example.json"
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary:
        server_port = int(parsed.get("game_port", server_port))
        max_players = clampi(int(parsed.get("max_players", max_players)), 1, NetworkManager.MAX_PEERS)
        world_seed = int(parsed.get("world_seed", world_seed))
        server_difficulty = str(parsed.get("difficulty", server_difficulty))
        server_pvp = bool(parsed.get("pvp", server_pvp))
        server_name = str(parsed.get("server_name", server_name))
        return parsed
    return {}

func _arg_int(args: Array, key: String, fallback: int) -> int:
    if key in args:
        var i := args.find(key)
        if i + 1 < args.size() and str(args[i + 1]).is_valid_int():
            return int(args[i + 1])
    return fallback