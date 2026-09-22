extends Control

signal play_singleplayer
signal host_multiplayer
signal join_multiplayer(address)
signal open_settings(return_page)

const BG_PATH := "res://assets/ui/hero_background.png"
const ACCENT := Color("#35a8ff")
const ACCENT_BRIGHT := Color("#78ddff")
const PANEL := Color(0.025, 0.045, 0.09, 0.94)
const PANEL_2 := Color(0.035, 0.065, 0.12, 0.92)
const TEXT := Color("#eaf6ff")
const MUTED := Color("#91a9bf")
const GREEN := Color("#49e38b")
const YELLOW := Color("#f3c85b")
const RED := Color("#ff6575")

var current_page := "home"
var nav_buttons: Dictionary = {}
var page_root: Control
var content_scroll: ScrollContainer
var content: VBoxContainer
var friends_box: VBoxContainer
var status_connection: Label
var status_server: Label
var status_fps: Label
var status_friends: Label
var profile_button: Button
var search_line: LineEdit
var search_popup: PanelContainer
var search_results: VBoxContainer
var notification_popup: PanelContainer
var auth_overlay: PanelContainer
var auth_user: LineEdit
var auth_password: LineEdit
var auth_server: LineEdit
var auth_status: Label
var auth_register_mode := false
var character_index := 0
var sidebar_panel: PanelContainer
var social_panel: PanelContainer
var characters := [
    {"id":"ranger","name":"Ranger","ar":"المستكشف","description":"Balanced explorer and survival specialist"},
    {"id":"engineer","name":"Engineer","ar":"المهندس","description":"Builder focused on systems and construction"},
    {"id":"shadow","name":"Shadow","ar":"الظل","description":"Agile explorer with a stealth-focused identity"},
    {"id":"grove","name":"Grovekeeper","ar":"حارس الغابة","description":"Nature-oriented wilderness specialist"},
]

func build(_parent: Node) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout_direction = Control.LAYOUT_DIRECTION_RTL
    mouse_filter = Control.MOUSE_FILTER_STOP
    layout_direction = Control.LAYOUT_DIRECTION_RTL
    ServerDirectory.load_favorites()
    _build_backdrop()
    _build_shell()
    _show_page("home")
    if not NetworkManager.player_presence_changed.is_connected(_refresh_friends):
        NetworkManager.player_presence_changed.connect(_refresh_friends)
    if not NetworkManager.connected.is_connected(_refresh_status):
        NetworkManager.connected.connect(_refresh_status)
    if not NetworkManager.disconnected.is_connected(_refresh_status):
        NetworkManager.disconnected.connect(_refresh_status)
    _refresh_friends({})
    _refresh_status()
    _animate_intro()
    _build_auth_gate()

func _build_backdrop() -> void:
    var image := TextureRect.new()
    image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    image.texture = load(BG_PATH) as Texture2D
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(image)
    var dim := ColorRect.new()
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0.015, 0.025, 0.055, 0.68)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(dim)
    var vignette := ColorRect.new()
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vignette.color = Color(0.0, 0.0, 0.0, 0.18)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(vignette)

func _build_shell() -> void:
    var root := MarginContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("margin_left", 24)
    root.add_theme_constant_override("margin_top", 22)
    root.add_theme_constant_override("margin_right", 24)
    root.add_theme_constant_override("margin_bottom", 22)
    add_child(root)

    var columns := HBoxContainer.new()
    columns.layout_direction = Control.LAYOUT_DIRECTION_LTR
    columns.add_theme_constant_override("separation", 14)
    root.add_child(columns)

    var sidebar := _panel(PANEL, 22, Color(0.22, 0.7, 1.0, 0.28))
    sidebar_panel = sidebar
    sidebar.custom_minimum_size = Vector2(190, 0)
    columns.add_child(sidebar)
    _build_sidebar(sidebar)

    var center_column := VBoxContainer.new()
    center_column.layout_direction = Control.LAYOUT_DIRECTION_RTL
    center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center_column.add_theme_constant_override("separation", 12)
    columns.add_child(center_column)

    var header := _panel(PANEL_2, 18, Color(0.22, 0.7, 1.0, 0.2))
    header.custom_minimum_size = Vector2(0, 66)
    center_column.add_child(header)
    _build_header(header)

    content_scroll = ScrollContainer.new()
    content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    center_column.add_child(content_scroll)
    content = VBoxContainer.new()
    content.layout_direction = Control.LAYOUT_DIRECTION_RTL
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 12)
    content_scroll.add_child(content)

    var social := _panel(PANEL, 22, Color(0.22, 0.7, 1.0, 0.22))
    social_panel = social
    social.custom_minimum_size = Vector2(220, 0)
    columns.add_child(social)
    _build_social(social)

    _build_bottom_bar(center_column)
    get_viewport().size_changed.connect(_apply_responsive_layout)
    _apply_responsive_layout()

func _apply_responsive_layout() -> void:
    var viewport_size := get_viewport_rect().size
    if sidebar_panel:
        var sidebar_width := 178 if viewport_size.x < 1280.0 else (190 if viewport_size.x < 1500.0 else 210)
        sidebar_panel.custom_minimum_size = Vector2(sidebar_width, 0)
    if social_panel:
        social_panel.visible = viewport_size.x >= 1280.0
        social_panel.custom_minimum_size = Vector2(220 if viewport_size.x < 1500.0 else 280, 0)
    if auth_overlay and is_instance_valid(auth_overlay):
        _layout_auth_overlay()
    if content:
        var hero_height := 300 if viewport_size.y < 820.0 else (340 if viewport_size.y < 900.0 else 370)
        for child in content.get_children():
            if child.get_meta("responsive_role", "") == "hero":
                child.custom_minimum_size = Vector2(0, hero_height)

func _layout_auth_overlay() -> void:
    if auth_overlay == null or not is_instance_valid(auth_overlay):
        return
    var viewport_size := get_viewport_rect().size
    var panel_size := Vector2(
        minf(620.0, viewport_size.x - 64.0),
        minf(520.0, viewport_size.y - 64.0)
    )
    auth_overlay.size = Vector2(
        minf(560.0, maxf(500.0, viewport_size.x - 80.0)),
        minf(460.0, maxf(400.0, viewport_size.y - 80.0))
    )
    auth_overlay.position = (viewport_size - auth_overlay.size) * 0.5

func _build_sidebar(parent: PanelContainer) -> void:
    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    parent.add_child(scroll)
    var box := VBoxContainer.new()
    box.layout_direction = Control.LAYOUT_DIRECTION_RTL
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 6)
    scroll.add_child(box)

    var logo := VBoxContainer.new()
    logo.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_child(logo)
    var logo_art := TextureRect.new()
    logo_art.texture = load("res://assets/icon.png") as Texture2D
    logo_art.custom_minimum_size = Vector2(82, 82)
    logo_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    logo.add_child(logo_art)
    _label(logo, "AETHRA", 32, ACCENT_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
    _label(logo, "WILDBOUND", 15, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    _label(logo, "بقاء فوكسيلي أصلي", 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

    var sep := HSeparator.new()
    sep.modulate.a = 0.25
    box.add_child(sep)

    var items := [
        ["home", "home", "الرئيسية"],
        ["solo", "person", "اللعب الفردي"],
        ["multiplayer", "players", "متعدد اللاعبين"],
        ["servers", "servers", "الخوادم"],
        ["worlds", "world", "العوالم"],
        ["store", "store", "المتجر"],
        ["settings", "settings", "الإعدادات"],
    ]
    for item in items:
        var b := _nav_button(item[1], item[2])
        nav_buttons[item[0]] = b
        b.pressed.connect(func(): _show_page(item[0]))
        box.add_child(b)

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(spacer)

    var user := _panel(PANEL_2, 14, Color(0.22, 0.7, 1.0, 0.16))
    user.custom_minimum_size = Vector2(0, 68)
    box.add_child(user)
    var user_row := HBoxContainer.new()
    user_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    user_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
    user.add_child(user_row)
    var avatar = load("res://scripts/ui/avatar_renderer.gd").new()
    avatar.avatar_index = AppState.avatar_id
    avatar.custom_minimum_size = Vector2(38, 38)
    user_row.add_child(avatar)
    var user_info := VBoxContainer.new()
    user_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    user_row.add_child(user_info)
    _label(user_info, AppState.get_display_name(), 14, TEXT)
    _label(user_info, "مسجل دخول" if AppState.is_authenticated else "وضع محلي", 10, GREEN if AppState.is_authenticated else MUTED)

    var logout := _nav_button("logout", "تسجيل الخروج")
    logout.pressed.connect(_logout)
    box.add_child(logout)

func _build_header(parent: PanelContainer) -> void:
    var row := HBoxContainer.new()
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.layout_direction = Control.LAYOUT_DIRECTION_LTR
    row.add_theme_constant_override("separation", 10)
    parent.add_child(row)
    search_line = LineEdit.new()
    search_line.placeholder_text = "ابحث عن عالم، خادم، لاعب أو إعداد..."
    search_line.clear_button_enabled = true
    search_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    search_line.custom_minimum_size = Vector2(0, 42)
    search_line.layout_direction = Control.LAYOUT_DIRECTION_RTL
    search_line.alignment = HORIZONTAL_ALIGNMENT_RIGHT
    row.add_child(search_line)
    search_line.text_changed.connect(_search)

    var notice := _small_icon_button("bell", 42)
    notice.tooltip_text = "الإشعارات"
    notice.pressed.connect(_toggle_notifications)
    row.add_child(notice)

    profile_button = _small_icon_button("profile", 42)
    profile_button.tooltip_text = "الملف الشخصي"
    profile_button.pressed.connect(func(): _show_page("profile"))
    row.add_child(profile_button)

    var min_btn := _small_icon_button("minimize", 42)
    min_btn.tooltip_text = "تصغير النافذة"
    min_btn.pressed.connect(func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED))
    row.add_child(min_btn)
    var max_btn := _small_icon_button("maximize", 42)
    max_btn.tooltip_text = "تكبير / استعادة النافذة"
    max_btn.pressed.connect(_toggle_window_mode)
    row.add_child(max_btn)
    var close_btn := _small_icon_button("close", 42)
    close_btn.tooltip_text = "إغلاق اللعبة"
    close_btn.pressed.connect(_request_close)
    row.add_child(close_btn)

func _build_social(parent: PanelContainer) -> void:
    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    box.add_theme_constant_override("separation", 10)
    parent.add_child(box)

    var profile := _panel(PANEL_2, 14, Color(0.22, 0.7, 1.0, 0.16))
    profile.custom_minimum_size = Vector2(0, 66)
    box.add_child(profile)
    var profile_row := HBoxContainer.new()
    profile_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    profile_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
    profile_row.add_theme_constant_override("separation", 9)
    profile.add_child(profile_row)
    var profile_icon = load("res://scripts/ui/vector_icon.gd").new()
    profile_icon.icon_name = "person"
    profile_icon.icon_color = ACCENT_BRIGHT
    profile_icon.custom_minimum_size = Vector2(30, 30)
    profile_row.add_child(profile_icon)
    var profile_text := VBoxContainer.new()
    profile_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    profile_row.add_child(profile_text)
    _label(profile_text, AppState.get_display_name(), 14, TEXT)
    _label(profile_text, "متصل" if AppState.is_authenticated else "وضع محلي", 10, GREEN if AppState.is_authenticated else MUTED)

    var heading := HBoxContainer.new()
    heading.layout_direction = Control.LAYOUT_DIRECTION_RTL
    heading.add_theme_constant_override("separation", 8)
    box.add_child(heading)
    var heading_icon = load("res://scripts/ui/vector_icon.gd").new()
    heading_icon.icon_name = "players"
    heading_icon.icon_color = ACCENT_BRIGHT
    heading_icon.custom_minimum_size = Vector2(24, 24)
    heading.add_child(heading_icon)
    var heading_text := VBoxContainer.new()
    heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_child(heading_text)
    _label(heading_text, "أصدقائي المتصلون", 18, TEXT)
    var count := _label(heading_text, "0 متصل", 11, MUTED)
    count.name = "FriendCount"
    friends_box = VBoxContainer.new()
    friends_box.add_theme_constant_override("separation", 6)
    friends_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(friends_box)
    _label(box, "الخصوصية محفوظة: الحالات الظاهرة هنا مصدرها جلسات الشبكة الفعلية فقط.", 9, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)

func _build_bottom_bar(center_column: VBoxContainer) -> void:
    var bar := _panel(PANEL_2, 12, Color(0.22, 0.7, 1.0, 0.18))
    bar.custom_minimum_size = Vector2(0, 38)
    center_column.add_child(bar)
    var row := HBoxContainer.new()
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    bar.add_child(row)
    status_connection = _label(row, "الاتصال: غير متصل", 10, MUTED)
    status_connection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_server = _label(row, "الخادم: غير محدد", 10, MUTED)
    status_server.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_fps = _label(row, "FPS: %d" % Engine.get_frames_per_second(), 10, MUTED)
    status_fps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_friends = _label(row, "الأصدقاء: 0", 10, MUTED)
    status_friends.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _show_page(page: String) -> void:
    if page == "settings":
        open_settings.emit(current_page)
        return
    current_page = page
    for key in nav_buttons:
        var b: Button = nav_buttons[key]
        b.disabled = key == page
    for child in content.get_children():
        child.queue_free()
    match page:
        "home": _page_home()
        "solo": _page_solo()
        "multiplayer": _page_multiplayer()
        "servers": _page_servers()
        "worlds": _page_worlds()
        "store": _page_store()
        "profile": _page_profile()
    _update_nav_state()

func _update_nav_state() -> void:
    for key in nav_buttons:
        var b: Button = nav_buttons[key]
        if key == current_page:
            b.modulate = Color(0.98, 1.0, 1.0, 1.0)
            b.add_theme_color_override("font_color", ACCENT_BRIGHT)
        else:
            b.modulate = Color.WHITE
            b.remove_theme_color_override("font_color")

func _page_home() -> void:
    var hero := _hero_panel()
    content.add_child(hero)
    var quick := HBoxContainer.new()
    quick.layout_direction = Control.LAYOUT_DIRECTION_RTL
    quick.add_theme_constant_override("separation", 10)
    content.add_child(quick)
    _quick_card(quick, "world", "إنشاء عالم جديد", "ابدأ مغامرة محفوظة فعليًا", func(): _page_create_world())
    _quick_card(quick, "players", "متعدد اللاعبين", "ادخل جلسة عبر الشبكة", func(): _show_page("multiplayer"))
    _quick_card(quick, "servers", "قائمة الخوادم", "الخوادم المحفوظة لديك", func(): _show_page("servers"))
    _section_title(content, "العوالم الأخيرة", "البيانات من SaveDB فقط")
    _world_cards(content, SaveDB.list_worlds())

func _hero_panel() -> PanelContainer:
    var panel := PanelContainer.new()
    panel.set_meta("responsive_role", "hero")
    panel.custom_minimum_size = Vector2(0, 370)
    panel.add_theme_stylebox_override("panel", _style(PANEL, 24, Color(0.25, 0.75, 1.0, 0.32)))
    var art := TextureRect.new()
    art.texture = load(BG_PATH) as Texture2D
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    panel.add_child(art)
    var overlay := ColorRect.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.color = Color(0.0, 0.01, 0.03, 0.36)
    art.add_child(overlay)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 26)
    margin.add_theme_constant_override("margin_top", 22)
    margin.add_theme_constant_override("margin_right", 26)
    margin.add_theme_constant_override("margin_bottom", 22)
    overlay.add_child(margin)
    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 10)
    margin.add_child(box)
    _label(box, "AETHRA", 44, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    _label(box, "WILDBOUND", 23, ACCENT_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
    _label(box, "عالمك. مغامرتك. قصتك.", 17, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    _label(box, "عوالم إجرائية مستمرة، استكشاف، بقاء، بناء، ولعب جماعي.", 11, Color(0.9,0.96,1.0,0.82), HORIZONTAL_ALIGNMENT_CENTER)
    var play := _primary_button("ابدأ اللعب", Vector2(260, 54))
    play.pressed.connect(func(): play_singleplayer.emit())
    box.add_child(play)
    var sub := HBoxContainer.new()
    sub.alignment = BoxContainer.ALIGNMENT_CENTER
    sub.add_theme_constant_override("separation", 8)
    box.add_child(sub)
    var solo := _button("اللعب الفردي", Vector2(150, 38))
    solo.pressed.connect(func(): _show_page("solo"))
    sub.add_child(solo)
    var multi := _button("متعدد اللاعبين", Vector2(170, 38))
    multi.pressed.connect(func(): _show_page("multiplayer"))
    sub.add_child(multi)

    var developer_credit := _panel(Color(0.01, 0.025, 0.055, 0.78), 12, Color(0.35, 0.8, 1.0, 0.22))
    developer_credit.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    developer_credit.position = Vector2(18, -18)
    developer_credit.size = Vector2(240, 46)
    developer_credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var credit_row := HBoxContainer.new()
    credit_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    credit_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
    credit_row.add_theme_constant_override("separation", 7)
    developer_credit.add_child(credit_row)
    var dev_icon = load("res://scripts/ui/vector_icon.gd").new()
    dev_icon.icon_name = "badge"
    dev_icon.icon_color = ACCENT_BRIGHT
    dev_icon.custom_minimum_size = Vector2(24, 24)
    credit_row.add_child(dev_icon)
    var credit_text := VBoxContainer.new()
    credit_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    credit_row.add_child(credit_text)
    _label(credit_text, "المطور: عبدالله لازم", 10, TEXT)
    _label(credit_text, "برمجة وتطوير: عبدالله لازم", 9, MUTED)

    return panel

func _build_auth_gate() -> void:
    if AppState.is_authenticated:
        return
    auth_overlay = _panel(Color(0.01, 0.02, 0.045, 0.96), 26, Color(0.25, 0.75, 1.0, 0.48))
    auth_overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    add_child(auth_overlay)
    _layout_auth_overlay()
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_top", 30)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_bottom", 30)
    auth_overlay.add_child(margin)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    margin.add_child(box)
    _label(box, "تسجيل الدخول إلى AETHRA", 27, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    _label(box, "حساب حقيقي محفوظ على هذا الجهاز، ومع توفر خدمة الحساب البعيدة تُستخدم تلقائيًا.", 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    auth_server = LineEdit.new()
    auth_server.text = str(Settings.get_value("auth_server_url", "http://127.0.0.1:8090"))
    auth_server.visible = false
    auth_user = LineEdit.new()
    auth_user.placeholder_text = "اسم المستخدم"
    auth_user.alignment = HORIZONTAL_ALIGNMENT_RIGHT
    auth_user.custom_minimum_size = Vector2(0, 44)
    box.add_child(auth_user)
    auth_password = LineEdit.new()
    auth_password.placeholder_text = "كلمة المرور"
    auth_password.secret = true
    auth_password.alignment = HORIZONTAL_ALIGNMENT_RIGHT
    auth_password.custom_minimum_size = Vector2(0, 44)
    box.add_child(auth_password)
    var character_select := OptionButton.new()
    character_select.name = "CharacterSelect"
    for character in characters:
        character_select.add_item(str(character.ar))
    character_select.select(character_index)
    character_select.item_selected.connect(func(index): character_index = index; AppState.character_id = str(characters[index].id))
    box.add_child(character_select)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    box.add_child(row)
    var submit := _primary_button("تسجيل الدخول", Vector2(190, 46))
    submit.pressed.connect(_submit_auth)
    row.add_child(submit)
    var toggle := _button("إنشاء حساب", Vector2(150, 46))
    toggle.pressed.connect(func():
        auth_register_mode = not auth_register_mode
        submit.text = "إنشاء الحساب" if auth_register_mode else "تسجيل الدخول"
        toggle.text = "لدي حساب" if auth_register_mode else "إنشاء حساب"
    )
    row.add_child(toggle)
    var offline := _button("متابعة دون حساب", Vector2(180, 42))
    offline.pressed.connect(func(): auth_overlay.queue_free(); auth_overlay = null)
    box.add_child(offline)
    auth_status = _label(box, "الحالة: في انتظار إدخال بياناتك", 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    _label(box, "الهوية والحالة الشبكية لا تُعتبر متصلة إلا بعد نجاح الخدمة الفعلية.", 9, Color(0.65,0.78,0.9,0.75), HORIZONTAL_ALIGNMENT_CENTER)

func _submit_auth() -> void:
    if auth_user.text.strip_edges().is_empty() or auth_password.text.length() < 8:
        auth_status.text = "الحالة: اسم المستخدم أو كلمة المرور غير صالحة."
        auth_status.add_theme_color_override("font_color", RED)
        return
    var root = get_parent()
    var auth_node = root.get("auth") if root != null else null
    if auth_node == null:
        auth_status.text = "الحالة: خدمة المصادقة غير متاحة في التطبيق."
        return
    var auth_url := auth_server.text.strip_edges()
    Settings.set_value("auth_server_url", auth_url)
    auth_node.configure(auth_url)
    auth_status.text = "الحالة: جارٍ الاتصال بالخدمة..."
    auth_status.add_theme_color_override("font_color", YELLOW)
    var character := str(characters[character_index].id)
    if auth_register_mode:
        auth_node.register(auth_user.text.strip_edges(), auth_password.text, character, AppState.avatar_id)
    else:
        auth_node.login(auth_user.text.strip_edges(), auth_password.text)

func set_connection_status(text: String) -> void:
    if status_connection:
        status_connection.text = "الاتصال: " + text
        status_connection.add_theme_color_override("font_color", YELLOW)

func refresh_profile() -> void:
    if profile_button:
        profile_button.tooltip_text = "%s - %s" % [AppState.player_name, "متصل" if AppState.is_authenticated else "وضع محلي"]
    if auth_overlay and AppState.is_authenticated:
        auth_overlay.queue_free()
        auth_overlay = null

func notify_auth_failure(message: String) -> void:
    if auth_status:
        auth_status.text = "الحالة: " + message
        auth_status.add_theme_color_override("font_color", RED)

func _page_create_world() -> void:
    for child in content.get_children():
        child.queue_free()
    _section_title(content, "إنشاء عالم جديد", "كل قيمة هنا تُحفظ مع العالم")
    var panel := _panel(PANEL, 20, Color(0.22, 0.7, 1.0, 0.2))
    panel.custom_minimum_size = Vector2(0, 440)
    content.add_child(panel)
    var form := VBoxContainer.new()
    form.layout_direction = Control.LAYOUT_DIRECTION_RTL
    form.add_theme_constant_override("separation", 10)
    panel.add_child(form)
    var name_field := LineEdit.new()
    name_field.name = "WorldName"
    name_field.placeholder_text = "اسم العالم"
    name_field.text = "Wildbound World"
    form.add_child(name_field)
    var seed_field := LineEdit.new()
    seed_field.placeholder_text = "البذرة أو اتركها عشوائية"
    seed_field.text = str(randi_range(1, 2147480000))
    form.add_child(seed_field)
    var mode := OptionButton.new()
    mode.add_item("بقاء")
    mode.add_item("إبداعي")
    var mode_ids := ["survival", "creative"]
    form.add_child(mode)

    var world_type := OptionButton.new()
    world_type.add_item("عالم طبيعي")
    world_type.add_item("عالم صحراوي")
    world_type.add_item("عالم غابة")
    world_type.add_item("عالم جليدي")
    var world_type_ids := ["", "arid", "grove", "frost"]
    form.add_child(world_type)
    var difficulty := OptionButton.new()
    difficulty.add_item("سلمي")
    difficulty.add_item("سهل")
    difficulty.add_item("عادي")
    difficulty.add_item("صعب")
    var difficulty_ids := ["peaceful", "easy", "normal", "hard"]
    difficulty.select(2)
    form.add_child(difficulty)
    var height := OptionButton.new()
    height.add_item("عمق 500")
    height.add_item("عمق 800")
    height.add_item("عمق 1000")
    height.select(0)
    form.add_child(height)
    var privacy := OptionButton.new()
    privacy.add_item("عام")
    privacy.add_item("خاص")
    privacy.add_item("للأصدقاء فقط")
    var privacy_ids := ["public", "private", "friends_only"]
    privacy.select(1)
    form.add_child(privacy)
    var structures := CheckBox.new()
    structures.text = "إنشاء المباني الطبيعية"
    structures.button_pressed = true
    form.add_child(structures)
    var creatures := CheckBox.new()
    creatures.text = "المخلوقات"
    creatures.button_pressed = true
    form.add_child(creatures)
    var weather := CheckBox.new()
    weather.text = "الطقس"
    weather.button_pressed = true
    form.add_child(weather)
    var starting_inventory := LineEdit.new()
    starting_inventory.placeholder_text = "مخزون البداية، مثال: 1=64, 2=32"
    form.add_child(starting_inventory)
    var controls := HBoxContainer.new()
    controls.alignment = BoxContainer.ALIGNMENT_END
    form.add_child(controls)
    var cancel := _button("إلغاء", Vector2(120, 42))
    cancel.pressed.connect(func(): _show_page("home"))
    controls.add_child(cancel)
    var create := _primary_button("إنشاء وابدأ", Vector2(190, 48))
    create.pressed.connect(func():
        var seed_value := int(seed_field.text) if seed_field.text.is_valid_int() else randi_range(1, 2147480000)
        AppState.pending_world_config = {
            "name": name_field.text.strip_edges() if not name_field.text.strip_edges().is_empty() else "Wildbound World",
            "seed": seed_value,
            "mode": mode_ids[mode.selected],
            "world_type": world_type_ids[world_type.selected],
            "difficulty": difficulty_ids[difficulty.selected],
            "world_height": [500, 800, 1000][height.selected],
            "world_radius": 32768,
            "privacy": privacy_ids[privacy.selected],
            "structures": structures.button_pressed,
            "creatures": creatures.button_pressed,
            "weather": weather.button_pressed,
            "starting_inventory": _parse_starting_inventory(starting_inventory.text),
        }
        play_singleplayer.emit()
    )
    controls.add_child(create)

func _page_solo() -> void:
    _section_title(content, "اللعب الفردي", "عوالم محفوظة على جهازك")
    var new_world := _primary_button("إنشاء عالم جديد", Vector2(240, 48))
    new_world.pressed.connect(_page_create_world)
    content.add_child(new_world)
    _world_cards(content, SaveDB.list_worlds())

func _parse_starting_inventory(text: String) -> Dictionary:
    var result := {}
    for part in text.split(","):
        var pair := part.strip_edges().split("=")
        if pair.size() == 2 and pair[0].is_valid_int() and pair[1].is_valid_int():
            var item_id := int(pair[0])
            var amount := maxi(0, int(pair[1]))
            if item_id >= 0 and amount > 0:
                result[item_id] = amount
    return result

func _page_worlds() -> void:
    _section_title(content, "العوالم", "إدارة العوالم المحفوظة")
    _world_cards(content, SaveDB.list_worlds(), true)

func _world_cards(parent: Control, worlds: Array, manage := false) -> void:
    if worlds.is_empty():
        var empty := _panel(PANEL_2, 18, Color(0.22, 0.7, 1.0, 0.12))
        parent.add_child(empty)
        _label(empty, "لا توجد عوالم محفوظة بعد.", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
        return
    var grid := GridContainer.new()
    grid.columns = 2
    grid.layout_direction = Control.LAYOUT_DIRECTION_RTL
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    parent.add_child(grid)
    for world in worlds:
        var card := _panel(PANEL_2, 16, Color(0.22, 0.7, 1.0, 0.14))
        card.custom_minimum_size = Vector2(0, 150)
        grid.add_child(card)
        var margin := MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 14)
        margin.add_theme_constant_override("margin_top", 12)
        margin.add_theme_constant_override("margin_right", 14)
        margin.add_theme_constant_override("margin_bottom", 12)
        card.add_child(margin)
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 6)
        margin.add_child(box)
        var thumb := TextureRect.new()
        thumb.texture = load(BG_PATH) as Texture2D
        thumb.custom_minimum_size = Vector2(0, 78)
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        box.add_child(thumb)
        var meta: Dictionary = world.get("metadata", {})
        _label(box, str(meta.get("name", world.get("id", "World"))), 17, TEXT)
        _label(box, "النمط: %s" % _mode_label(str(meta.get("mode", "unknown")) ), 10, MUTED)
        _label(box, "البذرة: %s" % str(meta.get("seed", "غير محدد")), 10, MUTED)
        _label(box, "آخر لعب: %s" % str(meta.get("saved_at", "غير محدد")), 9, MUTED)
        var actions := HBoxContainer.new()
        actions.alignment = BoxContainer.ALIGNMENT_END
        box.add_child(actions)
        var play := _button("استئناف", Vector2(110, 34))
        var world_id := str(world.get("id", ""))
        play.pressed.connect(func(): _resume_world(world_id))
        actions.add_child(play)
        if manage:
            var menu_button := _button("خيارات", Vector2(80, 34))
            menu_button.pressed.connect(func(): _world_actions(world_id, str(meta.get("name", "World"))))
            actions.add_child(menu_button)

func _page_multiplayer() -> void:
    _section_title(content, "متعدد اللاعبين", "اتصال حقيقي عبر مدير الشبكة")
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    content.add_child(row)
    var host := _quick_card(row, "host", "استضافة", "تشغيل جلسة ENet فعلية", func(): host_multiplayer.emit())
    host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var join := _quick_card(row, "join", "انضمام", "الاتصال بعنوان سيرفر فعلي", func(): _join_dialog())
    join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var servers := _quick_card(row, "servers", "الخوادم", "المفضلة والاتصال المباشر", func(): _show_page("servers"))
    servers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _section_title(content, "الأصدقاء داخل الجلسة", "لا يعرض إلا اللاعبين الموجودين في الجلسة الحالية")
    _refresh_friends(NetworkManager.remote_players)

func _page_servers() -> void:
    _section_title(content, "قائمة الخوادم", "القيم المعروضة من الشبكة الفعلية أو من مفضلاتك المحفوظة")
    var add := _primary_button("إضافة سيرفر", Vector2(190, 44))
    add.pressed.connect(_add_server_dialog)
    content.add_child(add)
    var favorites := ServerDirectory.recent()
    if favorites.is_empty():
        var empty := _panel(PANEL_2, 18, Color(0.22, 0.7, 1.0, 0.12))
        content.add_child(empty)
        _label(empty, "لا توجد خوادم محفوظة. أضف عنوان سيرفر لبدء الاتصال.", 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    else:
        for server in favorites:
            _server_card(server)

func _server_card(server: Dictionary) -> void:
    var card := _panel(PANEL_2, 16, Color(0.22, 0.7, 1.0, 0.14))
    card.custom_minimum_size = Vector2(0, 92)
    content.add_child(card)
    var row := HBoxContainer.new()
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.add_theme_constant_override("separation", 10)
    card.add_child(row)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)
    _label(info, str(server.get("name", "سيرفر")), 15, TEXT)
    var address_label := _label(info, str(server.get("address", "")), 10, MUTED)
    address_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
    address_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var state := _label(info, "جارٍ فحص الاتصال...", 10, YELLOW)
    _probe_server(str(server.get("address", "")), state)
    var join := _button("دخول", Vector2(100, 38))
    join.pressed.connect(func(): _join_remote(str(server.get("address", ""))))
    row.add_child(join)
    var remove := _button("حذف", Vector2(80, 38))
    remove.pressed.connect(func(): ServerDirectory.remove_favorite(str(server.get("address", ""))); _show_page("servers"))
    row.add_child(remove)

func _page_store() -> void:
    _section_title(content, "المتجر", "اقتصاد محلي محفوظ فعليًا مع مخزن مشتريات")
    var wallet:=_panel(PANEL_2, 18, Color(0.22, 0.7, 1.0, 0.14)); content.add_child(wallet)
    var wbox:=HBoxContainer.new(); wallet.add_child(wbox)
    var coins_label:=_label(wbox, "الرصيد: %d" % Economy.coins, 18, ACCENT_BRIGHT); coins_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    Economy.wallet_changed.connect(func(value:int): if is_instance_valid(coins_label): coins_label.text="الرصيد: %d" % value)
    var grid:=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12); content.add_child(grid)
    for offer in Economy.shop_catalog():
        var card:=_panel(PANEL_2, 14, Color(0.15,0.20,0.28,0.94)); card.custom_minimum_size=Vector2(280,110); grid.add_child(card)
        var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",6); card.add_child(box)
        _label(box, str(offer.get("name","Item")), 16, TEXT)
        _label(box, "%d x بسعر %d" % [int(offer.get("amount",1)),int(offer.get("price",0))], 11, MUTED)
        var buy:=_primary_button("شراء", Vector2(120,36))
        buy.pressed.connect(func(id: int = int(offer.get("item_id",0)), amount: int = int(offer.get("amount",1)), price: int = int(offer.get("price",0))) -> void:
            var ok:=Economy.purchase(id,amount,price)
            _show_page("store") if not ok else _show_page("store")
        )
        box.add_child(buy)

func _page_profile() -> void:
    _section_title(content, "الملف الشخصي", "بيانات الحساب والصورة المحفوظة")
    var panel := _panel(PANEL, 22, Color(0.22, 0.7, 1.0, 0.2))
    content.add_child(panel)
    var root := VBoxContainer.new()
    root.layout_direction = Control.LAYOUT_DIRECTION_RTL
    root.add_theme_constant_override("separation", 12)
    panel.add_child(root)

    var identity := HBoxContainer.new()
    identity.layout_direction = Control.LAYOUT_DIRECTION_RTL
    identity.add_theme_constant_override("separation", 14)
    root.add_child(identity)

    var preview = load("res://scripts/ui/avatar_renderer.gd").new()
    preview.avatar_index = AppState.avatar_id
    preview.custom_minimum_size = Vector2(96, 96)
    identity.add_child(preview)

    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    identity.add_child(info)
    _label(info, AppState.get_display_name(), 24, TEXT)
    _label(info, "الحساب: %s" % ("متحقق — بيانات محفوظة فعليًا" if AppState.is_authenticated else "محلي"), 11, GREEN if AppState.is_authenticated else MUTED)
    _label(info, "الشخصية: %s" % _character_label(AppState.character_id), 11, ACCENT_BRIGHT)

    var name_field := LineEdit.new()
    name_field.text = AppState.get_display_name()
    name_field.placeholder_text = "اسم العرض"
    name_field.editable = true
    name_field.custom_minimum_size = Vector2(0, 40)
    name_field.layout_direction = Control.LAYOUT_DIRECTION_RTL
    root.add_child(name_field)

    _label(root, "اختر صورة كرتونية", 16, TEXT)
    var grid := GridContainer.new()
    grid.columns = 5
    grid.layout_direction = Control.LAYOUT_DIRECTION_RTL
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(grid)

    var avatar_buttons: Array[Button] = []
    for index in 30:
        var button := Button.new()
        button.toggle_mode = true
        button.button_pressed = index == AppState.avatar_id
        button.custom_minimum_size = Vector2(96, 108)
        var avatar = load("res://scripts/ui/avatar_renderer.gd").new()
        avatar.avatar_index = index
        avatar.custom_minimum_size = Vector2(72, 72)
        button.add_child(avatar)
        var text := Label.new()
        text.text = "الصورة %02d" % [index + 1]
        text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        text.layout_direction = Control.LAYOUT_DIRECTION_RTL
        text.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(text)
        button.pressed.connect(func(selected_index: int = index) -> void:
            AppState.avatar_id = selected_index
            for peer in avatar_buttons:
                peer.button_pressed = false
            button.button_pressed = true
            preview.avatar_index = selected_index
            preview.queue_redraw()
        )
        grid.add_child(button)
        avatar_buttons.append(button)

    var save := _primary_button("حفظ الملف الشخصي", Vector2(220, 46))
    save.pressed.connect(func():
        if AppState.is_authenticated:
            var auth_root = get_parent()
            var auth_node = auth_root.get("auth") if auth_root != null else null
            if auth_node != null:
                auth_node.update_profile(AppState.auth_token, name_field.text, AppState.avatar_id)
        else:
            AppState.save_profile(name_field.text, AppState.avatar_id)
        _show_page("profile")
    )
    root.add_child(save)
    
func _page_developer() -> void:
    _section_title(content, "أدوات المطور", "مقاييس تشغيل فعلية فقط")
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    content.add_child(grid)
    _metric(grid, "FPS", str(Engine.get_frames_per_second()))
    _metric(grid, "الذاكرة", "%0.2f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
    _metric(grid, "لاعبو الشبكة", str(multiplayer.get_peers().size()))
    _metric(grid, "العوالم المحفوظة", str(SaveDB.list_worlds().size()))
    _metric(grid, "عقد المشهد", str(get_tree().get_node_count()))
    _metric(grid, "الاتصال", "متصل" if multiplayer.multiplayer_peer != null else "غير متصل")
    var console := _button("فتح وحدة المطور (F8)", Vector2(270, 44))
    console.pressed.connect(func():
        var root := get_parent()
        if root and root.has_method("toggle_developer_console"):
            root.toggle_developer_console()
    )
    content.add_child(console)

func _metric(parent: Control, title: String, value: String) -> void:
    var card := _panel(PANEL_2, 14, Color(0.22, 0.7, 1.0, 0.12))
    card.custom_minimum_size = Vector2(0, 92)
    parent.add_child(card)
    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    card.add_child(box)
    _label(box, title, 11, MUTED)
    var value_label := _label(box, value, 24, ACCENT_BRIGHT)
    value_label.name = "MetricValue"

func _refresh_friends(players: Dictionary) -> void:
    if friends_box == null:
        return
    for child in friends_box.get_children():
        child.queue_free()
    var valid := 0
    for id in players:
        var profile: Dictionary = players[id]
        if profile.is_empty():
            continue
        valid += 1
        var row := _panel(PANEL_2, 12, Color(0.22, 0.7, 1.0, 0.1))
        row.custom_minimum_size = Vector2(0, 54)
        friends_box.add_child(row)
        var inner := HBoxContainer.new()
        inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        inner.layout_direction = Control.LAYOUT_DIRECTION_RTL
        inner.add_theme_constant_override("separation", 8)
        row.add_child(inner)
        var person_icon = load("res://scripts/ui/vector_icon.gd").new()
        person_icon.icon_name = "person"
        person_icon.icon_color = GREEN
        person_icon.custom_minimum_size = Vector2(24, 24)
        inner.add_child(person_icon)
        var box := VBoxContainer.new()
        box.layout_direction = Control.LAYOUT_DIRECTION_RTL
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        inner.add_child(box)
        var name := str(profile.get("name", "Player"))
        _label(box, name, 12, TEXT)
        _label(box, "متصل داخل الجلسة - %s" % _character_label(str(profile.get("character", "ranger"))), 9, GREEN)
        var view := _button("عرض", Vector2(70, 30))
        view.pressed.connect(func(): _show_friend_profile(name, profile))
        inner.add_child(view)
    if valid == 0:
        _label(friends_box, "لا يوجد أصدقاء متصلون حاليًا.", 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    var count_label := _find_child_label("FriendCount")
    if count_label:
        count_label.text = "%d متصل" % valid
    status_friends.text = "الأصدقاء: %d" % valid

func _show_friend_profile(name: String, profile: Dictionary) -> void:
    var dialog := AcceptDialog.new()
    dialog.title = "ملف اللاعب"
    dialog.dialog_text = "%s\nالشخصية: %s\nالحالة: متصل داخل الجلسة الحالية" % [name, _character_label(str(profile.get("character", "ranger")))]
    add_child(dialog)
    dialog.popup_centered(Vector2i(420, 220))

func _refresh_status() -> void:
    if status_connection == null:
        return
    var state := str(NetworkManager.connection_state)
    var online := state in ["connected", "hosting"]
    status_connection.text = "الاتصال: %s" % ({"connected":"متصل", "hosting":"مستضيف", "connecting":"جارٍ الاتصال", "offline":"غير متصل"}.get(state, state))
    status_connection.add_theme_color_override("font_color", GREEN if online else (YELLOW if state == "connecting" else MUTED))
    status_server.text = "الخادم: مستضاف" if NetworkManager.server_started else "الخادم: عميل"
    status_fps.text = "FPS: %d" % Engine.get_frames_per_second()

func _process(_delta: float) -> void:
    if status_fps:
        status_fps.text = "FPS: %d" % Engine.get_frames_per_second()
    if current_page == "developer" and content:
        for child in content.get_children():
            if child is GridContainer:
                _refresh_metric_grid(child)

func _refresh_metric_grid(grid: GridContainer) -> void:
    var values := [
        str(Engine.get_frames_per_second()),
        "%0.2f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0),
        str(multiplayer.get_peers().size()),
        str(SaveDB.list_worlds().size()),
        str(get_tree().get_node_count()),
        "متصل" if multiplayer.multiplayer_peer != null else "غير متصل"
    ]
    var i := 0
    for card in grid.get_children():
        var labels := card.find_children("Label", "Label", true, false)
        if labels.size() >= 2 and i < values.size():
            labels[1].text = values[i]
        i += 1

func _search(query: String) -> void:
    _close_search_popup()
    var q := query.strip_edges().to_lower()
    if q.is_empty():
        return
    search_popup = _panel(PANEL, 16, Color(0.22, 0.7, 1.0, 0.22))
    search_popup.custom_minimum_size = Vector2(520, 340)
    search_popup.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    search_popup.position = Vector2(-540, 90)
    add_child(search_popup)
    search_results = VBoxContainer.new()
    search_results.add_theme_constant_override("separation", 7)
    search_popup.add_child(search_results)
    _label(search_results, "نتائج البحث", 17, TEXT)
    var found := 0
    for world in SaveDB.list_worlds():
        var meta: Dictionary = world.get("metadata", {})
        var name := str(meta.get("name", ""))
        if q in name.to_lower():
            found += 1
            var b := _button("عالم: %s" % name, Vector2(0, 38))
            search_results.add_child(b)
            var id := str(world.get("id", ""))
            b.pressed.connect(func(): _close_search_popup(); _resume_world(id))
    for server in ServerDirectory.recent():
        var searchable := (str(server.get("name", "")) + " " + str(server.get("address", ""))).to_lower()
        if q in searchable:
            found += 1
            var sb := _button("خادم: %s" % str(server.get("name", "Server")), Vector2(0, 38))
            search_results.add_child(sb)
            var addr := str(server.get("address", ""))
            sb.pressed.connect(func(): _close_search_popup(); _join_remote(addr))
    for id in NetworkManager.remote_players:
        var profile: Dictionary = NetworkManager.remote_players[id]
        var name := str(profile.get("name", ""))
        if q in name.to_lower():
            found += 1
            _label(search_results, "لاعب: %s - متصل" % name, 11, GREEN)
    if found == 0:
        _label(search_results, "لا توجد نتائج مطابقة من البيانات المتوفرة حاليًا.", 11, MUTED)

func _toggle_notifications() -> void:
    if notification_popup:
        notification_popup.queue_free()
        notification_popup = null
        return
    notification_popup = _panel(PANEL, 16, Color(0.22, 0.7, 1.0, 0.22))
    notification_popup.custom_minimum_size = Vector2(360, 180)
    notification_popup.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    notification_popup.position = Vector2(-380, 90)
    add_child(notification_popup)
    var box := VBoxContainer.new()
    notification_popup.add_child(box)
    _label(box, "الإشعارات", 18, TEXT)
    _label(box, "لا توجد إشعارات غير مقروءة محفوظة في الخدمة الحالية.", 11, MUTED)

func _close_search_popup() -> void:
    if search_popup:
        search_popup.queue_free()
        search_popup = null

func _join_dialog() -> void:
    var dialog := AcceptDialog.new()
    dialog.title = "الانضمام إلى سيرفر"
    var box := VBoxContainer.new()
    var address := LineEdit.new()
    address.placeholder_text = "عنوان السيرفر أو النطاق"
    address.text = "127.0.0.1"
    box.add_child(address)
    dialog.add_child(box)
    add_child(dialog)
    dialog.confirmed.connect(func(): _join_remote(address.text))
    dialog.popup_centered(Vector2i(520, 190))

func _join_remote(address: String) -> void:
    var normalized := address.strip_edges()
    if normalized.is_empty():
        return
    if not ":" in normalized:
        normalized += ":%d" % NetworkManager.DEFAULT_PORT
    join_multiplayer.emit(normalized)

func _add_server_dialog() -> void:
    var dialog := AcceptDialog.new()
    dialog.title = "إضافة سيرفر"
    var box := VBoxContainer.new()
    var name := LineEdit.new()
    name.placeholder_text = "اسم السيرفر"
    box.add_child(name)
    var address := LineEdit.new()
    address.placeholder_text = "127.0.0.1:31001"
    box.add_child(address)
    dialog.add_child(box)
    add_child(dialog)
    dialog.confirmed.connect(func():
        var n := name.text.strip_edges()
        var a := address.text.strip_edges()
        if not a.is_empty():
            ServerDirectory.add_favorite(a, n if not n.is_empty() else "مفضلة")
            _show_page("servers")
    )
    dialog.popup_centered(Vector2i(540, 220))

func _probe_server(address: String, label: Label) -> void:
    # ENet servers do not expose an HTTP/TCP status port in the current client.
    # Never mislabel a server as online using an incompatible transport probe.
    label.text = "محفوظ محليًا - الحالة عبر الاتصال المباشر"
    label.add_theme_color_override("font_color", MUTED)

func _resume_world(world_id: String) -> void:
    var data := SaveDB.load_world(world_id)
    if data.is_empty():
        return
    var meta: Dictionary = data.get("metadata", {})
    AppState.pending_world_config = {
        "name": str(meta.get("name", "World")),
        "seed": int(meta.get("seed", 7777)),
        "mode": str(meta.get("mode", "survival")),
        "difficulty": str(meta.get("difficulty", "normal")),
        "privacy": str(meta.get("privacy", "private")),
        "resume_id": world_id,
    }
    play_singleplayer.emit()

func _world_actions(world_id: String, world_name: String) -> void:
    var popup := PopupMenu.new()
    popup.add_item("تشغيل", 1)
    popup.add_item("إعادة تسمية", 2)
    popup.add_item("نسخة", 3)
    popup.add_item("نسخ احتياطي", 4)
    popup.add_item("حذف", 5)
    add_child(popup)
    popup.id_pressed.connect(func(id):
        popup.queue_free()
        match id:
            1: _resume_world(world_id)
            2: _rename_world_dialog(world_id, world_name)
            3: _duplicate_world_dialog(world_id, world_name)
            4: _backup_world(world_id)
            5: _confirm_delete_world(world_id)
    )
    popup.popup_centered(Vector2i(220, 220))

func _rename_world_dialog(world_id: String, old_name: String) -> void:
    var dialog := AcceptDialog.new()
    dialog.title = "إعادة تسمية العالم"
    var input := LineEdit.new()
    input.text = old_name
    dialog.add_child(input)
    add_child(dialog)
    dialog.confirmed.connect(func():
        var name := input.text.strip_edges()
        if not name.is_empty():
            SaveDB.rename_world(world_id, name)
            _show_page("worlds")
    )
    dialog.popup_centered(Vector2i(460, 180))

func _duplicate_world_dialog(world_id: String, old_name: String) -> void:
    var dialog := AcceptDialog.new()
    dialog.title = "نسخ العالم"
    var input := LineEdit.new()
    input.placeholder_text = "اسم النسخة"
    input.text = "%s Copy" % old_name
    dialog.add_child(input)
    add_child(dialog)
    dialog.confirmed.connect(func():
        var name := input.text.strip_edges()
        SaveDB.duplicate_world(world_id, name)
        _show_page("worlds")
    )
    dialog.popup_centered(Vector2i(460, 180))

func _backup_world(world_id: String) -> void:
    var path := SaveDB.backup_world(world_id)
    var dialog := AcceptDialog.new()
    dialog.title = "النسخ الاحتياطي"
    dialog.dialog_text = "تم إنشاء النسخة الاحتياطية." if not path.is_empty() else "فشل إنشاء النسخة الاحتياطية."
    add_child(dialog)
    dialog.popup_centered()

func _confirm_delete_world(world_id: String) -> void:
    var dialog := ConfirmationDialog.new()
    dialog.title = "حذف العالم"
    dialog.dialog_text = "سيتم حذف العالم من التخزين المحلي. هذا الإجراء لا يمكن التراجع عنه."
    add_child(dialog)
    dialog.confirmed.connect(func():
        SaveDB.delete_world(world_id)
        _show_page("worlds")
    )
    dialog.popup_centered()

func _logout() -> void:
    var root := get_parent()
    var auth_node = root.get("auth") if root != null else null
    if auth_node != null and auth_node.has_method("logout") and not AppState.auth_token.is_empty():
        auth_node.logout(AppState.auth_token)
    AppState.set_session("Guest", "")
    AppState.clear_saved_session()
    _show_page("home")

func _request_close() -> void:
    var root := get_parent()
    if root != null and root.has_method("request_close"):
        root.request_close()
    else:
        get_tree().quit()

func _toggle_window_mode() -> void:
    var mode := DisplayServer.window_get_mode()
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_MAXIMIZED else DisplayServer.WINDOW_MODE_MAXIMIZED)

func _animate_intro() -> void:
    modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _panel(color: Color, radius: int, border: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _style(color, radius, border))
    return panel

func _style(color: Color, radius: int, border: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.corner_radius_top_left = radius
    s.corner_radius_top_right = radius
    s.corner_radius_bottom_left = radius
    s.corner_radius_bottom_right = radius
    s.border_width_left = 1
    s.border_width_right = 1
    s.border_width_top = 1
    s.border_width_bottom = 1
    s.border_color = border
    s.content_margin_left = 10
    s.content_margin_right = 10
    s.content_margin_top = 10
    s.content_margin_bottom = 10
    return s

func _label(parent: Control, text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_RIGHT) -> Label:
    var l := Label.new()
    l.text = text
    var is_arabic := _contains_arabic(text)
    l.text_direction = Control.TEXT_DIRECTION_RTL if is_arabic else Control.TEXT_DIRECTION_LTR
    l.layout_direction = Control.LAYOUT_DIRECTION_RTL if is_arabic else Control.LAYOUT_DIRECTION_LTR
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(l)
    return l

func _contains_arabic(value: String) -> bool:
    for i in value.length():
        var code := value.unicode_at(i)
        if (code >= 0x0600 and code <= 0x06FF) or (code >= 0x0750 and code <= 0x077F) or (code >= 0x08A0 and code <= 0x08FF):
            return true
    return false

func _nav_button(icon_kind: String, text: String) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(0, 38)
    var row := HBoxContainer.new()
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.layout_direction = Control.LAYOUT_DIRECTION_RTL
    row.alignment = BoxContainer.ALIGNMENT_END
    row.add_theme_constant_override("separation", 8)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var label := Label.new()
    label.text = text
    label.text_direction = Control.TEXT_DIRECTION_RTL
    label.layout_direction = Control.LAYOUT_DIRECTION_RTL
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", TEXT)
    label.clip_text = true
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var icon = load("res://scripts/ui/vector_icon.gd").new()
    icon.icon_name = icon_kind
    icon.icon_color = ACCENT_BRIGHT
    icon.custom_minimum_size = Vector2(22, 22)
    row.add_child(icon)
    row.add_child(label)
    b.add_child(row)
    b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
    b.add_theme_font_size_override("font_size", 13)
    var normal := _style(Color(0.02,0.04,0.08,0.66), 12, Color(0.18,0.36,0.55,0.20))
    var hover := _style(Color(0.03,0.10,0.18,0.88), 12, Color(0.22,0.67,1.0,0.55))
    var pressed := _style(Color(0.02,0.14,0.25,0.95), 12, ACCENT)
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", pressed)
    b.add_theme_stylebox_override("disabled", pressed)
    return b

func _button(text: String, size: Vector2) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = size
    b.add_theme_font_size_override("font_size", 12)
    b.add_theme_stylebox_override("normal", _style(Color(0.03,0.07,0.12,0.82), 10, Color(0.24,0.52,0.78,0.25)))
    b.add_theme_stylebox_override("hover", _style(Color(0.04,0.12,0.20,0.94), 10, Color(0.25,0.72,1.0,0.6)))
    b.add_theme_stylebox_override("pressed", _style(Color(0.03,0.16,0.26,0.98), 10, ACCENT))
    return b

func _primary_button(text: String, size: Vector2) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = size
    b.add_theme_font_size_override("font_size", 15)
    b.add_theme_color_override("font_color", Color.WHITE)
    b.add_theme_stylebox_override("normal", _style(Color(0.02,0.34,0.72,0.92), 14, Color(0.35,0.85,1.0,0.9)))
    b.add_theme_stylebox_override("hover", _style(Color(0.02,0.46,0.92,0.97), 14, ACCENT_BRIGHT))
    b.add_theme_stylebox_override("pressed", _style(Color(0.02,0.22,0.52,1.0), 14, ACCENT_BRIGHT))
    return b

func _small_button(text: String, width: int) -> Button:
    return _button(text, Vector2(width, 40))

func _small_icon_button(icon_kind: String, width: int) -> Button:
    var b := _button("", Vector2(width, 40))
    var icon = load("res://scripts/ui/vector_icon.gd").new()
    icon.icon_name = icon_kind
    icon.icon_color = ACCENT_BRIGHT
    icon.custom_minimum_size = Vector2(20, 20)
    icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    b.add_child(icon)
    return b

func _quick_card(parent: Control, icon: String, title: String, subtitle: String, action: Callable) -> PanelContainer:
    var card := _panel(PANEL_2, 16, Color(0.22,0.7,1.0,0.16))
    card.custom_minimum_size = Vector2(0, 104)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(card)
    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.layout_direction = Control.LAYOUT_DIRECTION_RTL
    card.add_child(box)
    var icon_node = load("res://scripts/ui/vector_icon.gd").new()
    icon_node.icon_name = icon
    icon_node.icon_color = ACCENT_BRIGHT
    icon_node.custom_minimum_size = Vector2(30, 30)
    icon_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    box.add_child(icon_node)
    _label(box, title, 14, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    _label(box, subtitle, 9, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    card.gui_input.connect(func(event):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            action.call()
    )
    card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    return card

func _section_title(parent: Control, title: String, subtitle: String) -> void:
    _label(parent, title, 22, TEXT)
    _label(parent, subtitle, 10, MUTED)


func _mode_label(mode: String) -> String:
    match mode:
        "survival": return "بقاء"
        "creative": return "إبداعي"
        "adventure": return "مغامرة"
        "peaceful": return "سلمي"
        "easy": return "سهل"
        "normal": return "عادي"
        "hard": return "صعب"
        _: return mode

func _character_label(character: String) -> String:
    match character:
        "ranger": return "المستكشف"
        "engineer": return "المهندس"
        "shadow": return "الظل"
        "grove": return "حارس الغابة"
        _: return character

func _find_child_label(node_name: String) -> Label:
    return find_child(node_name, true, false) as Label
