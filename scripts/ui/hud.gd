extends CanvasLayer

var stats: Label
var players_panel: PanelContainer
var players: Label
var hotbar: HBoxContainer
var selected := 0
var inventory_ref
var slot_labels: Array[Label] = []

func build() -> void:
    add_to_group("aethra_hud")
    stats = Label.new()
    stats.layout_direction = Control.LAYOUT_DIRECTION_RTL
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    stats.position = Vector2(24,24)
    stats.add_theme_font_size_override("font_size", 15)
    add_child(stats)
    players_panel = PanelContainer.new()
    players_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    players_panel.position = Vector2(-286, 24)
    players_panel.size = Vector2(270, 138)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.02, 0.04, 0.08, 0.88)
    panel_style.corner_radius_top_left = 16
    panel_style.corner_radius_top_right = 16
    panel_style.corner_radius_bottom_left = 16
    panel_style.corner_radius_bottom_right = 16
    panel_style.border_width_left = 1
    panel_style.border_width_right = 1
    panel_style.border_width_top = 1
    panel_style.border_width_bottom = 1
    panel_style.border_color = Color(0.25, 0.75, 1.0, 0.28)
    players_panel.add_theme_stylebox_override("panel", panel_style)
    add_child(players_panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_bottom", 10)
    players_panel.add_child(margin)
    var player_box := VBoxContainer.new()
    player_box.add_theme_constant_override("separation", 5)
    margin.add_child(player_box)
    var heading := HBoxContainer.new()
    heading.layout_direction = Control.LAYOUT_DIRECTION_RTL
    heading.add_theme_constant_override("separation", 7)
    player_box.add_child(heading)
    var heading_icon = load("res://scripts/ui/vector_icon.gd").new()
    heading_icon.icon_name = "players"
    heading_icon.icon_color = Color("#78ddff")
    heading_icon.custom_minimum_size = Vector2(22, 22)
    heading.add_child(heading_icon)
    var heading_label := Label.new()
    heading_label.text = "اللاعبون المتصلون"
    heading_label.layout_direction = Control.LAYOUT_DIRECTION_RTL
    heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading_label.add_theme_font_size_override("font_size", 14)
    heading.add_child(heading_label)
    players = Label.new()
    players.layout_direction = Control.LAYOUT_DIRECTION_RTL
    players.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    players.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    players.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    players.add_theme_font_size_override("font_size", 12)
    players.size_flags_vertical = Control.SIZE_EXPAND_FILL
    player_box.add_child(players)
    hotbar = HBoxContainer.new()
    hotbar.layout_direction = Control.LAYOUT_DIRECTION_LTR
    hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    hotbar.position = Vector2(-240, -72)
    hotbar.size = Vector2(480, 60)
    add_child(hotbar)
    for i in 9:
        var box := Label.new()
        box.name = "Slot%d" % i
        box.text = "%d\nفارغ" % (i+1)
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
    var slots: Array[Dictionary] = inventory_ref.get_hotbar()
    for i in mini(slot_labels.size(), slots.size()):
        var slot: Dictionary = slots[i]
        var item_id := int(slot.get("item", ItemRegistry.EMPTY))
        var count := int(slot.get("count", 0))
        var item := ItemRegistry.get_item(item_id)
        var name := str(item.get("name", "فارغ"))
        if item_id > BlockRegistry.AIR and item_id <= BlockRegistry.SNOW and (str(item.get("category", "none")) == "none"):
            name = str(BlockRegistry.get_block(item_id).get("name", name))
        slot_labels[i].text = "%d\n%s x%d" % [i+1, name, count]

func set_player_stats(health: float, hunger: float, stamina: float, fps: float) -> void:
    stats.text = "AETHRA // بقاء\nالصحة %.1f  الجوع %.1f  التحمل %.1f\nالإطارات %.0f" % [health,hunger,stamina,fps]

func set_selected(index: int) -> void:
    selected = clampi(index, 0, max(0, slot_labels.size() - 1))
    for i in slot_labels.size():
        var label: Label = slot_labels[i]
        label.add_theme_color_override("font_color", Color("#78ddff") if i == selected else Color("#eaf6ff"))
        label.add_theme_font_size_override("font_size", 13 if i == selected else 12)

func set_players(data: Dictionary) -> void:
    var names: Array[String] = []
    for value in data.values():
        if value is Dictionary:
            names.append(str(value.get("name", "Player")))
    players.text = "\n".join(names) if not names.is_empty() else "لا يوجد لاعبون متصلون حاليًا."
