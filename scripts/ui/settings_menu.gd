extends Control

signal closed

var bindings := ["move_forward","move_back","move_left","move_right","sprint","jump","crouch","mine","place"]
var waiting_action := ""
var binding_label: Label
var body: VBoxContainer
var binding_buttons: Dictionary = {}

func build(_parent: Node) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout_direction = Control.LAYOUT_DIRECTION_RTL
    var bg := ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.015,0.025,0.055,0.86)
    add_child(bg)
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.offset_left = 36
    panel.offset_top = 36
    panel.offset_right = -36
    panel.offset_bottom = -36
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025,0.045,0.09,0.97)
    style.corner_radius_top_left = 24
    style.corner_radius_top_right = 24
    style.corner_radius_bottom_left = 24
    style.corner_radius_bottom_right = 24
    style.border_width_left = 1; style.border_width_right = 1; style.border_width_top = 1; style.border_width_bottom = 1
    style.border_color = Color(0.22,0.7,1.0,0.35)
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    var root := VBoxContainer.new()
    root.layout_direction = Control.LAYOUT_DIRECTION_RTL
    root.add_theme_constant_override("separation", 12)
    panel.add_child(root)
    var head := HBoxContainer.new()
    head.custom_minimum_size = Vector2(0, 48)
    root.add_child(head)
    var title := Label.new()
    title.text = "الإعدادات"
    title.add_theme_font_size_override("font_size", 30)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    head.add_child(title)
    var close := Button.new()
    close.text = "إغلاق"
    close.custom_minimum_size = Vector2(52,44)
    close.pressed.connect(func(): Settings.save_settings(); closed.emit())
    head.add_child(close)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)
    body = VBoxContainer.new()
    body.layout_direction = Control.LAYOUT_DIRECTION_RTL
    body.add_theme_constant_override("separation", 8)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(body)
    _build_graphics()
    _build_window()
    _build_controls()
    _build_audio()
    _build_gameplay()
    _build_network()
    _build_footer(root)

func _heading(text: String) -> void:
    var label := Label.new()
    label.text = text
    label.layout_direction = Control.LAYOUT_DIRECTION_RTL
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color("#78ddff"))
    body.add_child(label)

func _row(label_text: String, control: Control) -> void:
    var row := HBoxContainer.new()
    row.layout_direction = Control.LAYOUT_DIRECTION_RTL
    row.custom_minimum_size = Vector2(0, 42)
    body.add_child(row)
    var label := Label.new()
    label.text = label_text
    label.layout_direction = Control.LAYOUT_DIRECTION_RTL
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(label)
    row.add_child(control)

func _build_graphics() -> void:
    _heading("الرسومات")
    var quality := OptionButton.new()
    for v in ["low","medium","high","ultra"]: quality.add_item(v.capitalize())
    quality.select(["low","medium","high","ultra"].find(str(Settings.get_value("graphics_quality","medium"))))
    quality.item_selected.connect(func(i): Settings.set_value("graphics_quality", quality.get_item_text(i).to_lower()))
    _row("جودة الرسوم", quality)
    var fov := HSlider.new(); fov.min_value=55; fov.max_value=110; fov.step=1; fov.value=float(Settings.get_value("fov",75.0)); fov.custom_minimum_size=Vector2(250,0)
    fov.value_changed.connect(func(v): Settings.set_value("fov",v))
    _row("مجال الرؤية FOV", fov)
    var rd := SpinBox.new(); rd.min_value=3; rd.max_value=16; rd.value=int(Settings.get_value("render_distance",7)); rd.custom_minimum_size=Vector2(130,0)
    rd.value_changed.connect(func(v): Settings.set_value("render_distance",int(v)))
    _row("Render Distance", rd)

func _build_window() -> void:
    _heading("النافذة")
    var resolution := OptionButton.new()
    var options: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
    var current := get_window().size
    var selected := 0
    for i in options.size():
        var size := options[i]
        resolution.add_item("%d × %d" % [size.x, size.y])
        if size == current:
            selected = i
    resolution.select(selected)
    resolution.item_selected.connect(func(i):
        var size: Vector2i = options[i]
        get_window().mode = Window.MODE_WINDOWED
        get_window().size = size
        Settings.values["window_width"] = size.x
        Settings.values["window_height"] = size.y
        Settings.values["window_mode"] = 0
        Settings.save_settings()
    )
    _row("حجم النافذة", resolution)
    var mode := OptionButton.new()
    mode.add_item("Windowed")
    mode.add_item("Maximized")
    mode.add_item("Fullscreen")
    var current_mode := get_window().mode
    mode.select(2 if current_mode == Window.MODE_EXCLUSIVE_FULLSCREEN or current_mode == Window.MODE_FULLSCREEN else (1 if current_mode == Window.MODE_MAXIMIZED else 0))
    mode.item_selected.connect(func(i):
        match i:
            0: get_window().mode = Window.MODE_WINDOWED
            1: get_window().mode = Window.MODE_MAXIMIZED
            2: get_window().mode = Window.MODE_FULLSCREEN
        Settings.values["window_mode"] = i
        Settings.save_settings()
    )
    _row("وضع النافذة", mode)

func _build_controls() -> void:
    _heading("التحكم")
    for action in bindings:
        var button := Button.new()
        button.text = str(Settings.controls.get(action, ""))
        button.custom_minimum_size = Vector2(180, 38)
        binding_buttons[action] = button
        button.pressed.connect(func(): _capture(action, button))
        _row(action.capitalize(), button)
    var sensitivity := HSlider.new(); sensitivity.min_value=0.05; sensitivity.max_value=0.5; sensitivity.step=0.01; sensitivity.value=float(Settings.get_value("mouse_sensitivity",0.15)); sensitivity.custom_minimum_size=Vector2(250,0)
    sensitivity.value_changed.connect(func(v): Settings.set_value("mouse_sensitivity",v))
    _row("حساسية الماوس", sensitivity)
    var invert := CheckButton.new(); invert.button_pressed=bool(Settings.get_value("invert_y",false)); invert.toggled.connect(func(v): Settings.set_value("invert_y",v))
    _row("عكس المحور Y", invert)
    var camera := CheckButton.new(); camera.text="First Person"; camera.button_pressed=bool(Settings.get_value("first_person",true)); camera.toggled.connect(func(v): Settings.set_value("first_person",v))
    _row("الكاميرا", camera)

func _build_audio() -> void:
    _heading("الصوت")
    _audio_row("Master", "master_volume")
    _audio_row("Music", "music_volume")
    _audio_row("Effects", "sfx_volume")

func _audio_row(label_text: String, key: String) -> void:
    var slider := HSlider.new(); slider.min_value=0; slider.max_value=1; slider.step=0.01; slider.value=float(Settings.get_value(key,0.8)); slider.custom_minimum_size=Vector2(250,0)
    slider.value_changed.connect(func(v): Settings.set_value(key,v); AudioManager.apply_settings())
    _row(label_text, slider)

func _build_gameplay() -> void:
    _heading("أسلوب اللعب")
    var hint := Label.new(); hint.text="الإعدادات المؤثرة مباشرة على اللعب محفوظة إلى user://aethra_settings.json"; hint.add_theme_color_override("font_color",Color("#91a9bf")); body.add_child(hint)

func _build_network() -> void:
    _heading("الشبكة")
    var net := Label.new(); net.text="حالة الشبكة: %s" % ("متصل" if multiplayer.multiplayer_peer != null else "غير متصل"); net.layout_direction = Control.LAYOUT_DIRECTION_RTL; net.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; net.add_theme_color_override("font_color",Color("#91a9bf")); body.add_child(net)

func _build_footer(root: VBoxContainer) -> void:
    var spacer := Control.new(); spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(spacer)
    var footer := HBoxContainer.new(); footer.layout_direction = Control.LAYOUT_DIRECTION_RTL; root.add_child(footer)
    var reset := Button.new(); reset.text="إعادة القيم الافتراضية"; reset.pressed.connect(func(): Settings.values=Settings.DEFAULTS.duplicate(true); Settings.controls=Settings.DEFAULT_CONTROLS.duplicate(true); Settings.save_settings(); closed.emit())
    footer.add_child(reset)
    var save := Button.new(); save.text="حفظ وإغلاق"; save.size_flags_horizontal=Control.SIZE_EXPAND_FILL; save.pressed.connect(func(): Settings.save_settings(); closed.emit()); footer.add_child(save)
    binding_label = Label.new(); binding_label.add_theme_color_override("font_color",Color("#78ddff")); footer.add_child(binding_label)

func _capture(action: String, button: Button) -> void:
    waiting_action = action
    binding_label.text = "اضغط المفتاح أو زر الفأرة لـ %s" % action
    button.text = "انتظر..."

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
