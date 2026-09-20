extends Node

signal session_changed
signal world_changed

const GAME_VERSION := "0.2.3"
const WORLD_VERSION := 1
const PROTOCOL_VERSION := 1

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

func set_world(world_id: String, name: String, seed: int, mode: String) -> void:
    current_world_id = world_id
    current_world_name = name
    world_seed = seed
    game_mode = mode
    world_changed.emit()
