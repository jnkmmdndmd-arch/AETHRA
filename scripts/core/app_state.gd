extends Node

signal session_changed
signal world_changed

const GAME_VERSION := "0.2.3"
const WORLD_VERSION := 1
const PROTOCOL_VERSION := 1
const SESSION_PATH := "user://aethra_session.json"

var player_name := "Guest"
var auth_token := ""
var is_authenticated := false
var character_id := "ranger"
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
    session_changed.emit()

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
        "character": character_id
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
