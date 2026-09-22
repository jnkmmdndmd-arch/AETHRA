extends CanvasLayer

var ui_root: Control
var stats: Label
var players_panel: PanelContainer
var players: Label
var hotbar: HBoxContainer
var selected := 0
var inventory_ref
var slot_panels: Array[PanelContainer] = []
var slot_labels: Array[Label] = []
var fps_badge: Label
var crosshair: Control
var fps_elapsed := 0.0
var fps_smooth := 0.0

const ACCENT := Color("#78ddff")
const TEXT := Color("#eaf6ff")
const MUTED := Color("#91a9bf")
const PANEL := Color(0.015, 0.035, 0.065, 0.90)

func build() -> void:
    add_to_group("aethra_hud")

    ui_root = Control.new()
    ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(ui_root)

    stats = Label.new()
    stats.position = Vector2(20, 54)
    stats.size = Vector2(330, 74)
    stats.layout_direction = Control.LAYOUT_DIRECTION_RTL
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    stats.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    stats.add_theme_font_size_override("font_size", 14)
    stats.add_theme_color_override("font_color", TEXT)
    stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_root.add_child(stats)

    fps_badge = Label.new()
    fps_badge.position = Vector2(-80, 12)
    fps_badge.set_anchors_preset(Control.PRESET_TOP_WIDE)
    fps_badge.size = Vector2(160, 30)
    fps_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    fps_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    fps_badge.text = "FPS: --"
    fps_badge.add_theme_font_size_override("font_size", 15)
    fps_badge.add_theme_color_override("font_color", ACCENT)
    fps_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_root.add_child(fps_badge)

    players_panel = PanelContainer.new()
    players_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    players_panel.position = Vector2(-286, 20)
    players_panel.size = Vector2(266, 132)
    players_panel.add_theme_stylebox_override("panel", _panel_style())
    players_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_root.add_child(players_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_top", 9)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_bottom", 9)
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
    heading_icon.icon_color = ACCENT
    heading_icon.custom_minimum_size = Vector2(20, 20)
    heading_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
    players.mouse_filter = Control.MOUSE_FILTER_IGNORE
    player_box.add_child(players)

    hotbar = HBoxContainer.new()
    hotbar.layout_direction = Control.LAYOUT_DIRECTION_LTR
    hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    hotbar.position = Vector2(-270, -82)
    hotbar.size = Vector2(540, 62)
    hotbar.add_theme_constant_override("separation", 5)
    hotbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_root.add_child(hotbar)

    for i in 9:
        var panel := PanelContainer.new()
        panel.name = "Slot%d" % i
        panel.custom_minimum_size = Vector2(56, 56)
        panel.add_theme_stylebox_override("panel", _slot_style(false))
        panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        hotbar.add_child(panel)
        slot_panels.append(panel)

        var box := VBoxContainer.new()
        box.alignment = BoxContainer.ALIGNMENT_CENTER
        box.mouse_filter = Control.MOUSE_FILTER_IGNORE
        panel.add_child(box)

        var label := Label.new()
        label.text = "%d\nفارغ" % (i + 1)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.add_theme_font_size_override("font_size", 11)
        label.add_theme_color_override("font_color", TEXT)
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        box.add_child(label)
        slot_labels.append(label)

    crosshair = Control.new()
    crosshair.set_anchors_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-16, -16)
    crosshair.size = Vector2(32, 32)
    crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_root.add_child(crosshair)
    _build_crosshair()
    _set_crosshair_visible(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
    get_viewport().size_changed.connect(_layout_responsive)
    _layout_responsive()

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL
    style.corner_radius_top_left = 16
    style.corner_radius_top_right = 16
    style.corner_radius_bottom_left = 16
    style.corner_radius_bottom_right = 16
    style.border_width_left = 1
    style.border_width_right = 1
    style.border_width_top = 1
    style.border_width_bottom = 1
    style.border_color = Color(0.25, 0.75, 1.0, 0.30)
    return style

func _slot_style(active: bool) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.04, 0.07, 0.11, 0.92) if not active else Color(0.05, 0.18, 0.25, 0.96)
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    style.border_width_left = 2 if active else 1
    style.border_width_right = 2 if active else 1
    style.border_width_top = 2 if active else 1
    style.border_width_bottom = 2 if active else 1
    style.border_color = ACCENT if active else Color(0.35, 0.50, 0.60, 0.45)
    return style

func _build_crosshair() -> void:
    var h := ColorRect.new()
    h.position = Vector2(8, 15)
    h.size = Vector2(16, 2)
    h.color = Color(0.90, 0.98, 1.0, 0.92)
    h.mouse_filter = Control.MOUSE_FILTER_IGNORE
    crosshair.add_child(h)

    var v := ColorRect.new()
    v.position = Vector2(15, 8)
    v.size = Vector2(2, 16)
    v.color = Color(0.90, 0.98, 1.0, 0.92)
    v.mouse_filter = Control.MOUSE_FILTER_IGNORE
    crosshair.add_child(v)

    var dot := ColorRect.new()
    dot.position = Vector2(14, 14)
    dot.size = Vector2(4, 4)
    dot.color = ACCENT
    dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
    crosshair.add_child(dot)

func _layout_responsive() -> void:
    if ui_root == null:
        return
    var viewport_size := get_viewport_rect().size

    var stat_width := minf(360.0, maxf(260.0, viewport_size.x * 0.26))
    stats.size = Vector2(stat_width, 74)
    stats.position = Vector2(20, 54)

    var players_width := minf(290.0, maxf(220.0, viewport_size.x * 0.22))
    players_panel.size = Vector2(players_width, 132)
    players_panel.position = Vector2(-players_width - 20.0, 20)

    var slot_size := clampf(floorf((viewport_size.x - 72.0) / 9.0), 44.0, 56.0)
    var gap := clampf(floorf(slot_size * 0.09), 3.0, 5.0)
    hotbar.size = Vector2(slot_size * 9.0 + gap * 8.0, slot_size + 6.0)
    hotbar.position = Vector2(-hotbar.size.x * 0.5, -slot_size - 18.0)
    hotbar.add_theme_constant_override("separation", int(gap))
    for panel in slot_panels:
        panel.custom_minimum_size = Vector2(slot_size, slot_size)

func set_inventory(inventory) -> void:
    if inventory_ref != null and inventory_ref.changed.is_connected(_refresh_hotbar):
        inventory_ref.changed.disconnect(_refresh_hotbar)
    inventory_ref = inventory
    if inventory_ref != null and not inventory_ref.changed.is_connected(_refresh_hotbar):
        inventory_ref.changed.connect(_refresh_hotbar)
    _refresh_hotbar()
    set_selected(inventory_ref.selected if inventory_ref != null else 0)

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
        if item_id > BlockRegistry.AIR and item_id <= BlockRegistry.LAST_BLOCK and str(item.get("category", "none")) == "none":
            name = str(BlockRegistry.get_block(item_id).get("name", name))
        slot_labels[i].text = "%d\n%s x%d" % [i + 1, name, count]

func set_player_stats(health: float, hunger: float, stamina: float, fps: float) -> void:
    stats.text = "AETHRA // بقاء\nالصحة %.1f  الجوع %.1f  التحمل %.1f\nالإطارات %.0f" % [health, hunger, stamina, fps]

func set_selected(index: int) -> void:
    selected = clampi(index, 0, max(0, slot_labels.size() - 1))
    for i in slot_labels.size():
        var active := i == selected
        slot_panels[i].add_theme_stylebox_override("panel", _slot_style(active))
        slot_labels[i].add_theme_color_override("font_color", ACCENT if active else TEXT)
        slot_labels[i].add_theme_font_size_override("font_size", 12 if active else 11)

func _unhandled_input(event: InputEvent) -> void:
    if inventory_ref == null:
        return

    if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        _set_crosshair_visible(false)
        return

    if event is InputEventMouseButton and event.pressed:
        if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and event.button_index == MOUSE_BUTTON_LEFT:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            _set_crosshair_visible(true)
            return
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            inventory_ref.scroll_slot(-1)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            inventory_ref.scroll_slot(1)

func _set_crosshair_visible(visible: bool) -> void:
    if crosshair != null:
        crosshair.visible = visible

func set_players(data: Dictionary) -> void:
    var names: Array[String] = []
    for value in data.values():
        if value is Dictionary:
            names.append(str(value.get("name", "Player")))
    players.text = "\n".join(names) if not names.is_empty() else "لا يوجد لاعبون متصلون حاليًا."

func _process(delta: float) -> void:
    fps_elapsed += delta
    var live_fps := float(Engine.get_frames_per_second())
    fps_smooth = live_fps if fps_smooth <= 0.0 else lerpf(fps_smooth, live_fps, 0.18)
    if fps_badge != null and fps_elapsed >= 0.10:
        fps_elapsed = 0.0
        fps_badge.text = "FPS: %d" % maxi(0, int(round(fps_smooth)))
