extends Control

var output: RichTextLabel
var input: LineEdit
var enabled := false
var game_root: Node = null

func build(parent: Node) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    visible = false
    game_root = parent
    output = RichTextLabel.new()
    output.position = Vector2(24, 24)
    output.size = Vector2(820, 420)
    output.bbcode_enabled = true
    output.text = "[color=#8dd9ff]AETHRA Developer Console[/color]\nType /help"
    output.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(output)
    input = LineEdit.new()
    input.position = Vector2(24, 458)
    input.size = Vector2(820, 44)
    input.placeholder_text = "Command..."
    input.visible = true
    input.text_submitted.connect(_run)
    add_child(input)

func toggle() -> void:
    enabled = not enabled
    visible = enabled
    if enabled and input:
        input.grab_focus()

func _run(command: String) -> void:
    var cmd := command.strip_edges()
    var parts := cmd.split(" ", false)
    if cmd == "/help":
        _log("/help /pos /time [seconds] /weather [clear|rain|fog] /give <item_id> <amount> /tp <x> <y> <z>")
    elif cmd == "/pos":
        var player = get_tree().get_first_node_in_group("players")
        _log("Player position: %s" % (str(player.position) if player else "unavailable"))
    elif parts.size() >= 2 and parts[0] == "/time":
        var node = get_tree().root.find_child("WorldTime", true, false)
        if node and str(parts[1]).is_valid_float():
            node.world_time = fmod(float(parts[1]), maxf(1.0, node.day_length_seconds))
            _log("World time set to %.2f" % node.world_time)
        else:
            _log("Usage: /time <seconds>")
    elif parts.size() >= 2 and parts[0] == "/weather":
        var node = get_tree().root.find_child("WorldTime", true, false)
        var weather := str(parts[1]).to_lower()
        if node and weather in ["clear", "rain", "fog"]:
            node.weather = weather
            node.weather_changed.emit(weather)
            _log("Weather set to %s" % weather)
        else:
            _log("Usage: /weather <clear|rain|fog>")
    elif parts.size() >= 3 and parts[0] == "/give" and str(parts[1]).is_valid_int() and str(parts[2]).is_valid_int():
        var player = get_tree().get_first_node_in_group("players")
        var item_id: int = int(parts[1])
        var amount: int = maxi(1, int(parts[2]))
        var info: Dictionary = ItemRegistry.get_item(item_id)
        var valid_item := int(info.get("id", ItemRegistry.EMPTY)) == item_id or (item_id > BlockRegistry.AIR and item_id <= BlockRegistry.SNOW)
        if player == null:
            _log("Player unavailable")
        elif not valid_item:
            _log("Invalid item")
        else:
            var remainder: int = int(player.inventory.add_item(item_id, amount))
            _log("Give item=%d amount=%d remainder=%d" % [item_id, amount, remainder])
    elif parts.size() >= 4 and parts[0] == "/tp" and str(parts[1]).is_valid_float() and str(parts[2]).is_valid_float() and str(parts[3]).is_valid_float():
        var player = get_tree().get_first_node_in_group("players")
        if player:
            player.position = Vector3(float(parts[1]), float(parts[2]), float(parts[3]))
            _log("Teleported to %s" % str(player.position))
        else:
            _log("Player unavailable")
    else:
        _log("Unknown or unavailable command: " + cmd)
    input.clear()

func _log(text: String) -> void:
    if output:
        output.append_text("\n" + text)
