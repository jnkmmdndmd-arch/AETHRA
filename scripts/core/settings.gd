extends Node

signal settings_changed

const PATH := "user://aethra_settings.json"
const DEFAULTS := {
    "graphics_quality": "low",
    "fov": 75.0,
    "mouse_sensitivity": 0.15,
    "invert_y": false,
    "master_volume": 0.8,
    "music_volume": 0.5,
    "sfx_volume": 0.85,
    "render_distance": 4,
    "simulation_distance": 3,
    "first_person": true,
    "window_width": 1280,
    "window_height": 720,
    "window_mode": 0,
    "auth_server_url": "",
    "java_source_project_path": "",
    "minecraft_runtime_path": "",
}
const DEFAULT_CONTROLS := {
    "move_forward": "W",
    "move_back": "S",
    "move_left": "A",
    "move_right": "D",
    "sprint": "SHIFT",
    "jump": "SPACE",
    "crouch": "CTRL",
    "mine": "MOUSE1",
    "place": "MOUSE2",
    "attack": "F",
    "inventory": "E",
    "pause": "ESC",
}

var values: Dictionary = {}
var controls: Dictionary = {}

func _ready() -> void:
    values = DEFAULTS.duplicate(true)
    controls = DEFAULT_CONTROLS.duplicate(true)
    load_settings()
    apply_input_map()

func load_settings() -> void:
    if not FileAccess.file_exists(PATH):
        save_settings()
        return
    var file := FileAccess.open(PATH, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    if data is Dictionary:
        var saved_values = data.get("values", {})
        for key in DEFAULTS:
            if saved_values is Dictionary and saved_values.has(key):
                values[key] = saved_values[key]
        if data.get("controls") is Dictionary:
            for key in DEFAULT_CONTROLS:
                if data["controls"].has(key):
                    controls[key] = str(data["controls"][key])
    if str(values.get("auth_server_url", "")).strip_edges() == "http://127.0.0.1:8090":
        values["auth_server_url"] = ""

func save_settings() -> void:
    var file := FileAccess.open(PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({"values": values, "controls": controls}))
    file.close()

func get_value(key: String, fallback = null):
    return values.get(key, fallback)

func set_value(key: String, value) -> void:
    values[key] = value
    save_settings()
    settings_changed.emit()

func set_control(action: String, binding: String) -> void:
    controls[action] = binding
    apply_input_map()
    save_settings()
    settings_changed.emit()

func apply_input_map() -> void:
    var actions := ["move_forward","move_back","move_left","move_right","sprint","jump","crouch","inventory","pause","mine","place","attack"]
    for action in actions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        InputMap.action_erase_events(action)
        var binding := str(controls.get(action, DEFAULT_CONTROLS.get(action, "")))
        var event := _event_from_binding(binding)
        if event != null:
            InputMap.action_add_event(action, event)

func _event_from_binding(binding: String) -> InputEvent:
    var v := binding.strip_edges().to_upper()
    if v.begins_with("MOUSE"):
        var button := int(v.trim_prefix("MOUSE"))
        if button in [1, 2, 3, 4, 5]:
            var mouse_event := InputEventMouseButton.new()
            mouse_event.button_index = button
            return mouse_event
        return null
    var keycode := _key_from_name(v)
    if keycode == 0:
        return null
    var key_event := InputEventKey.new()
    key_event.physical_keycode = keycode
    return key_event

func _key_from_name(value: String) -> Key:
    var v := value.strip_edges().to_upper()
    if v == "SPACE": return KEY_SPACE
    if v == "SHIFT": return KEY_SHIFT
    if v == "CTRL" or v == "CONTROL": return KEY_CTRL
    if v == "ESC" or v == "ESCAPE": return KEY_ESCAPE
    if v.length() == 1:
        return OS.find_keycode_from_string(v)
    return OS.find_keycode_from_string(v)
