extends CanvasLayer

var stats: Label
var players: Label
var hotbar: HBoxContainer
var selected := 0
var inventory_ref
var slot_labels: Array[Label] = []

func build() -> void:
    stats = Label.new()
    stats.layout_direction = Control.LAYOUT_DIRECTION_RTL
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    stats.position = Vector2(24,24)
    stats.add_theme_font_size_override("font_size", 15)
    add_child(stats)
    players = Label.new()
    players.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    players.position = Vector2(-260, 30)
    players.size = Vector2(236, 120)
    players.layout_direction = Control.LAYOUT_DIRECTION_LTR
    players.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    players.add_theme_font_size_override("font_size", 15)
    add_child(players)
    hotbar = HBoxContainer.new()
    hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    hotbar.position = Vector2(-240, -72)
    hotbar.size = Vector2(480, 60)
    add_child(hotbar)
    for i in 9:
        var box := Label.new()
        box.name = "Slot%d" % i
        box.text = "%d\nEmpty" % (i+1)
        box.custom_minimum_size = Vector2(48,48)
        box.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        hotbar.add_child(box)
        slot_labels.append(box)

func set_inventory(inventory) -> void:
    if inventory_ref != null and inventory_ref.changed.is_connected(_refresh_hotbar):
        inventory_ref.changed.disconnect(_refresh_hotbar)
    inventory_ref = inventory
    if inventory_ref != null and not inventory_ref.changed.is_connected(_refresh_hotbar):
        inventory_ref.changed.connect(_refresh_hotbar)
    _refresh_hotbar()

func _refresh_hotbar() -> void:
    if inventory_ref == null:
        return
    var slots := inventory_ref.get_hotbar()
    for i in mini(slot_labels.size(), slots.size()):
        var slot: Dictionary = slots[i]
        var item_id := int(slot.get("item", ItemRegistry.EMPTY))
        var count := int(slot.get("count", 0))
        var item := ItemRegistry.get_item(item_id)
        var name := str(item.get("name", "Empty"))
        if item_id > BlockRegistry.AIR and item_id <= BlockRegistry.SNOW and (str(item.get("category", "none")) == "none"):
            name = str(BlockRegistry.get_block(item_id).get("name", name))
        slot_labels[i].text = "%d\n%s x%d" % [i+1, name, count]

func set_player_stats(health: float, hunger: float, stamina: float, fps: float) -> void:
    stats.text = "AETHRA // Survival\nHP %.1f  Hunger %.1f  Stamina %.1f\nFPS %.0f" % [health,hunger,stamina,fps]

func set_players(data: Dictionary) -> void:
    var names: Array[String] = []
    for value in data.values():
        if value is Dictionary:
            names.append(str(value.get("name", "Player")))
    players.text = "PLAYERS ONLINE\n" + "\n".join(names)
