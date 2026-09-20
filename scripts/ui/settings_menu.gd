extends Control

signal closed

const ROW_HEIGHT := 42
const LABEL_WIDTH := 190
const CONTROL_WIDTH := 250

var bindings := ["move_forward","move_back","move_left","move_right","sprint","jump","crouch","mine","place"]
var game_root: Node
var waiting_action := ""
var binding_label: Label
var body: VBoxContainer
var binding_buttons: Dictionary = {}

func build(parent: Node) -> void:
    game_root = parent
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout_direction = Control.LAYOUT_DIRECTION_RTL

    var bg := ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.015, 0.025, 0.055, 0.90)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.offset_left = 28
    panel.offset_top = 28
    panel.offset_right = -28
    panel.offset_bottom = -28
    panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(panel)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_bottom", 18)
    panel.add_child(margin)

    var root := VBoxContainer.new()
    root.layout_direction = Control.LAYOUT_DIRECTION_RTL
    root.add_theme_constant_override("separation", 10)
    margin.add_child(root)

    var head := HBoxContainer.new()
    head.layout_direction = Control.LAYOUT_DIRECTION_RTL
    head.custom_minimum_size = Vector2(0, 46)
    root.add_child(head)

    var title := Label.new()
    title.text = "الإعدادات"
    title.layout_direction = Control.LAYOUT_DIRECTION_RTL
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("#eaf6ff"))
    head.add_child(title)

    var close := Button.new()
    close.text = "إغلاق"
    close.custom_minimum_size = Vector2(92, 42)
    close.pressed.connect(func():
        Settings.save_settings()
        closed.emit()
    )
    head.add_child(close)

    var scroll := ScrollContainer.new()
    scroll.layout_direction = Control.LAYOUT_DIRECTION_RTL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)

    body = VBoxContainer.new()
    body.layout_direction = Control.LAYOUT_DIRECTION_RTL
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 7)
    scroll.add_child(body)

    _build_graphics()
    _build_window()
    _build_controls()
    _build_audio()
    _build_gameplay()
    _build_network()

    var footer := HBoxContainer.new()
    footer.layout_direction = Control.LAYOUT_DIRECTION_RTL
    footer.custom_minimum_size = Vector2(0, 46)
    footer.add_theme_constant_override("separation", 8)
    root.add_child(footer)

    var reset := Button.new()
    reset.text = "إعادة القيم الافتراضية"
    reset.custom_minimum_size = Vector2(190, 40)
    reset.pressed.connect(_reset_defaults)
    footer.add_child(reset)

    binding_label = Label.new()
    binding_label.layout_direction = Control.LAYOUT_DIRECTION_RTL
    binding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    binding_label.text = ""
    binding_label.custom_minimum_size = Vector2(230, 40)
    binding_label.add_theme_color_override("font_color", Color("#78ddff"))
    footer.add_child(binding_label)

    var save := Button.new()
    save.text = "حفظ وإغلاق"
    save.custom_minimum_size = Vector2(150, 40)
    save.pressed.connect(func():
        Settings.save_settings()
        closed.emit()
    )
    footer.add_child(save)

    _apply_camera_setting(bool(Settings.get_value("first_person", true)))

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.045, 0.09, 0.97)
    style.corner_radius_top_left = 22
    style.corner_radius_top_right = 22
    style.corner_radius_bottom_left = 22
    style.corner_radius_bottom_right = 22
    style.border_width_left = 1
    style.border_width_right = 1
    style.border_width_top = 1
    style.border_width_bottom = 1
    style.border_color = Color(0.22, 0.70, 1.0, 0.35)
    return style

func _heading(text: String) -> void:
    var label := Label.new()
    label.text = text
    label.layout_direction = Control.LAYOUT_DIRECTION_RTL
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    label.custom_minimum_size = Vector2(0, 32)
    label.add_theme_font_size_override("font_size", 17)
    label.add_theme_color_override("font_color", Color("#78ddff"))
    body.add_child(label)

func _row(label_text: String, control: Control) -> void:
    var row := HBoxContainer.new()
    row.layout_direction = Control.LAYOUT_DIRECTION_RTL
    row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 12)
    body.add_child(row)

    var label := Label.new()
    label.text = label_text
    label.layout_direction = Control.LAYOUT_DIRECTION_RTL
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size = Vector2(LABEL_WIDTH, ROW_HEIGHT)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", 13)
    row.add_child(label)

    control.custom_minimum_size = Vector2(maxf(control.custom_minimum_size.x, 120.0), maxf(control.custom_minimum_size.y, 36.0))
    control.size_flags_horizontal = Control.SIZE_SHRINK_END
    if control is OptionButton or control is CheckButton:
        control.layout_direction = Control.LAYOUT_DIRECTION_RTL
    row.add_child(control)

func _build_graphics() -> void:
    _heading("الرسومات")
    var quality := OptionButton.new()
    quality.layout_direction = Control.LAYOUT_DIRECTION_RTL
    for item in ["منخفض", "متوسط", "مرتفع", "فائق"]:
        quality.add_item(item)
    var values := ["low", "medium", "high", "ultra"]
    var selected := values.find(str(Settings.get_value("graphics_quality", "medium")))
    quality.select(maxi(0, selected))
    quality.item_selected.connect(func(index): Settings.set_value("graphics_quality", values[index]))
    _row("جودة الرسومات", quality)

    var fov := HSlider.new()
    fov.min_value = 55
    fov.max_value = 110
    fov.step = 1
    fov.value = float(Settings.get_value("fov", 75.0))
    fov.custom_minimum_size = Vector2(240, 36)
    fov.value_changed.connect(func(value): Settings.set_value("fov", value))
    _row("مجال الرؤية", fov)

    var rd := SpinBox.new()
    rd.min_value = 3
    rd.max_value = 16
    rd.step = 1
    rd.value = int(Settings.get_value("render_distance", 7))
    rd.custom_minimum_size = Vector2(120, 36)
    rd.value_changed.connect(func(value): Settings.set_value("render_distance", int(value)))
    _row("مسافة الرؤية", rd)

func _build_window() -> void:
    _heading("النافذة")
    var resolution := OptionButton.new()
    resolution.layout_direction = Control.LAYOUT_DIRECTION_LTR
    var options: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
    var current := get_window().size
    var selected := 0
    for i in options.size():
        var size := options[i]
        resolution.add_item("%d x %d" % [size.x, size.y])
        if size == current:
            selected = i
    resolution.select(selected)
    resolution.item_selected.connect(func(index):
        var size: Vector2i = options[index]
        get_window().mode = Window.MODE_WINDOWED
        get_window().size = size
        Settings.values["window_width"] = size.x
        Settings.values["window_height"] = size.y
        Settings.values["window_mode"] = 0
        Settings.save_settings()
    )
    _row("دقة الشاشة", resolution)

    var mode := OptionButton.new()
    mode.layout_direction = Control.LAYOUT_DIRECTION_RTL
    mode.add_item("نافذة")
    mode.add_item("تكبير")
    mode.add_item("ملء الشاشة")
    var current_mode := get_window().mode
    mode.select(2 if current_mode == Window.MODE_EXCLUSIVE_FULLSCREEN or current_mode == Window.MODE_FULLSCREEN else (1 if current_mode == Window.MODE_MAXIMIZED else 0))
    mode.item_selected.connect(func(index):
        match index:
            0: get_window().mode = Window.MODE_WINDOWED
            1: get_window().mode = Window.MODE_MAXIMIZED
            2: get_window().mode = Window.MODE_FULLSCREEN
        Settings.values["window_mode"] = index
        Settings.save_settings()
    )
    _row("وضع النافذة", mode)

func _build_controls() -> void:
    _heading("التحكم")
    var labels := {
        "move_forward": "الحركة للأمام",
        "move_back": "الحركة للخلف",
        "move_left": "الحركة لليسار",
        "move_right": "الحركة لليمين",
        "sprint": "الركض",
        "jump": "القفز",
        "crouch": "الانحناء",
        "mine": "التكسير",
        "place": "الوضع"
    }
    for action in bindings:
        var button := Button.new()
        button.text = str(Settings.controls.get(action, ""))
        button.custom_minimum_size = Vector2(150, 38)
        button.layout_direction = Control.LAYOUT_DIRECTION_LTR
        button.pressed.connect(func(): _capture(action, button))
        binding_buttons[action] = button
        _row(str(labels.get(action, action)), button)
    var sensitivity := HSlider.new()
    sensitivity.min_value = 0.05
    sensitivity.max_value = 0.5
    sensitivity.step = 0.01
    sensitivity.value = float(Settings.get_value("mouse_sensitivity", 0.15))
    sensitivity.custom_minimum_size = Vector2(240, 36)
    sensitivity.value_changed.connect(func(value): Settings.set_value("mouse_sensitivity", value))
    _row("حساسية الماوس", sensitivity)

    var invert := CheckButton.new()
    invert.text = "تفعيل"
    invert.button_pressed = bool(Settings.get_value("invert_y", false))
    invert.toggled.connect(func(value): Settings.set_value("invert_y", value))
    _row("عكس المحور العمودي", invert)

    var camera := CheckButton.new()
    camera.text = "منظور أول"
    camera.button_pressed = bool(Settings.get_value("first_person", true))
    camera.toggled.connect(func(value):
        Settings.set_value("first_person", value)
        _apply_camera_setting(value)
    )
    _row("منظور الكاميرا", camera)

func _build_audio() -> void:
    _heading("الصوت")
    _audio_row("الصوت الرئيسي", "master_volume", 0.8)
    _audio_row("الموسيقى", "music_volume", 0.5)
    _audio_row("المؤثرات", "sfx_volume", 0.85)

func _audio_row(label_text: String, key: String, fallback: float) -> void:
    var slider := HSlider.new()
    slider.min_value = 0
    slider.max_value = 1
    slider.step = 0.01
    slider.value = float(Settings.get_value(key, fallback))
    slider.custom_minimum_size = Vector2(240, 36)
    slider.value_changed.connect(func(value):
        Settings.set_value(key, value)
        AudioManager.apply_settings()
    )
    _row(label_text, slider)

func _build_gameplay() -> void:
    _heading("أسلوب اللعب")
    var hint := Label.new()
    hint.text = "إعدادات اللعب المحفوظة تُطبّق مباشرة وتُخزّن محليًا."
    hint.layout_direction = Control.LAYOUT_DIRECTION_RTL
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.custom_minimum_size = Vector2(0, 42)
    hint.add_theme_color_override("font_color", Color("#91a9bf"))
    body.add_child(hint)

func _build_network() -> void:
    _heading("الشبكة")
    var net := Label.new()
    net.text = "حالة الشبكة: %s" % ("متصل" if multiplayer.multiplayer_peer != null else "غير متصل")
    net.layout_direction = Control.LAYOUT_DIRECTION_RTL
    net.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    net.add_theme_color_override("font_color", Color("#91a9bf"))
    body.add_child(net)

func _reset_defaults() -> void:
    Settings.values = Settings.DEFAULTS.duplicate(true)
    Settings.controls = Settings.DEFAULT_CONTROLS.duplicate(true)
    Settings.apply_input_map()
    AudioManager.apply_settings()
    Settings.save_settings()
    closed.emit()

func _apply_camera_setting(first_person: bool) -> void:
    if game_root == null:
        return
    var player = game_root.get("player") if game_root.has_method("get") else null
    if player == null:
        return
    var camera = player.get("camera") if player.has_method("get") else null
    if camera is Camera3D:
        camera.position = Vector3.ZERO if first_person else Vector3(0, 0, 3.8)

func _capture(action: String, button: Button) -> void:
    waiting_action = action
    binding_label.text = "اضغط المفتاح أو زر الفأرة لتعيين: %s" % _action_label(action)
    button.text = "انتظر..."

func _action_label(action: String) -> String:
    var labels := {
        "move_forward": "الحركة للأمام",
        "move_back": "الحركة للخلف",
        "move_left": "الحركة لليسار",
        "move_right": "الحركة لليمين",
        "sprint": "الركض",
        "jump": "القفز",
        "crouch": "الانحناء",
        "mine": "التكسير",
        "place": "الوضع"
    }
    return str(labels.get(action, action))

func _unhandled_input(event: InputEvent) -> void:
    if waiting_action.is_empty():
        return
    var binding := ""
    if event is InputEventKey and event.pressed:
        binding = OS.get_keycode_string(event.physical_keycode)
    elif event is InputEventMouseButton and event.pressed:
        match event.button_index:
            MOUSE_BUTTON_LEFT: binding = "MOUSE1"
            MOUSE_BUTTON_RIGHT: binding = "MOUSE2"
            MOUSE_BUTTON_MIDDLE: binding = "MOUSE3"
    if not binding.is_empty():
        Settings.set_control(waiting_action, binding)
        if binding_buttons.has(waiting_action):
            binding_buttons[waiting_action].text = binding
        waiting_action = ""
        binding_label.text = "تم الحفظ: %s" % binding
