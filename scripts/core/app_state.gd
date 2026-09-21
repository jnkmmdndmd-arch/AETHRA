extends Node

signal session_changed
signal world_changed
signal profile_changed

const GAME_VERSION := "0.2.3"
const WORLD_VERSION := 1
const PROTOCOL_VERSION := 1
const SESSION_PATH := "user://aethra_session.json"
const PROFILE_PATH := "user://aethra_profile.json"
const MAX_AVATARS := 30

var player_name := "Guest"
var auth_token := ""
var is_authenticated := false
var character_id := "ranger"
var avatar_id := 0
var profile_name := "Guest"
var game_mode := "survival"
var current_world_id := ""
var current_world_name := ""
var world_seed: int = 0
var online_players: Dictionary = {}
var is_server := false
var pending_world_config: Dictionary = {}
var world_settings: Dictionary = {}

func set_session(name: String, token: String) -> void:
    player_name = name
    auth_token = token
    is_authenticated = not token.is_empty()
    if is_authenticated:
        profile_name = player_name
    session_changed.emit()
    profile_changed.emit()

func save_session() -> void:
    if auth_token.is_empty():
        clear_saved_session()
        return
    var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({
        "username": player_name,
        "token": auth_token,
        "character": character_id,
        "avatar_id": avatar_id
    }))
    file.close()

func load_saved_session() -> Dictionary:
    if not FileAccess.file_exists(SESSION_PATH):
        return {}
    var file := FileAccess.open(SESSION_PATH, FileAccess.READ)
    if file == null:
        return {}
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    return data if data is Dictionary else {}

func clear_saved_session() -> void:
    if FileAccess.file_exists(SESSION_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))

func set_world(world_id: String, name: String, seed: int, mode: String) -> void:
    current_world_id = world_id
    current_world_name = name
    world_seed = seed
    game_mode = mode
    world_changed.emit()

func save_profile(name: String, selected_avatar: int) -> void:
    var safe_name := name.strip_edges()
    if safe_name.is_empty():
        safe_name = get_display_name()
    avatar_id = clampi(selected_avatar, 0, MAX_AVATARS - 1)
    profile_name = safe_name
    if not is_authenticated:
        player_name = safe_name
    var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify({"name": profile_name, "avatar_id": avatar_id}))
        file.close()
    profile_changed.emit()
    session_changed.emit()

func load_profile() -> void:
    if not FileAccess.file_exists(PROFILE_PATH):
        return
    var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    if data is Dictionary:
        avatar_id = clampi(int(data.get("avatar_id", 0)), 0, MAX_AVATARS - 1)
        profile_name = str(data.get("name", "Guest"))
        if not is_authenticated and not profile_name.strip_edges().is_empty():
            player_name = profile_name

func get_display_name() -> String:
    return player_name if is_authenticated else (profile_name if not profile_name.strip_edges().is_empty() else "Guest")

func _ready() -> void:
    load_profile()
