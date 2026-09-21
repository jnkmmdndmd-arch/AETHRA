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
    {"id":"ranger","name":"Ranger","ar":&'5£\ÌÖsK§uçâçR"Â&FW67&—F–öâ#¢$&Ææ6VBW‡Æ÷&W"æB7W'f—fÂ7V6–Æ—7B'ÒÀ¢²&–B#¢&Væv–æVW""Â&æÖR#¢$Væv–æVW""Â&"#¢#Z5‘MhÖ/ºw^~)Þw","description":"Builder focused on systems and construction"},
    {"id":"shadow","name":"Shadow","ar":"éÝyø§y×D5£Pˆ°‰‘•ÍÉ¥ÁÑ¥½¸ˆè‰¥±”•áÁ±½É•ÈÝ¥Ñ „ÍÑ•…±Ñ µ™½ÕÍ•¥‘•¹Ñ¥Ñä‰ô°(€€€ì‰¥ˆè‰É½Ù”ˆ°‰¹…µ”ˆè‰É½Ù•­••Á•Èˆ°‰…ÈˆèˆÖs§uçâçrbsZ7‰ÍhÙ","description":"Nature-oriented wilderness specialist"},
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
    _label(logo, "5£XžéÝyø§yÔ™Ös3Z5’ˆºw^~)ÞuÍMhÚ", 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

    var sep := HSeparator.new()
    sep.modulate.a = 0.25
    box.add_child(sep)

    var items := [
        ["home", "home", &'5£\˜Öt«§uçâçR%ÒÀ¢²'6öÆò"Â'W'6öâ"Â#Z5‘hØ 5£YÖô¢%ÒÀ¢²&×VÇF—Æ–W""Â'Æ–W'2"Â.×ŸŠwr£Z7ËÈºw^~)ÞuÑh×95£y‰t°(€€€€€€€l‰Í•ÉÙ•ÉÌˆ°€‰Í•ÉÙ•ÉÌˆ°€ˆÖbãZ5Ëî×ŸŠwH—KˆÈÛÜ›È‹ÛÜ›‹ºw^~)ÞuÑhÞ'5£T‰t°(€€€€€€€l‰ÍÑ½É”ˆ°€‰ÍÑ½É”ˆ°€‹§uçâç]ÖâË§uçâçR%ÒÀ¢²'6WGF–æw2"Â'6WGF–æw2"Â#Z5‰Mhß'5£\¨‰t°(€€€t(€€€™½È¥Ñ•´¥¸¥Ñ•µÌè(€€€€€€€Ù…Èˆ€èô}¹…Ù}‰ÕÑÑ½¸¡¥Ñ•µlÅt°¥Ñ•µlÉt¤(€€€€€€€¹…Ù}‰ÕÑÑ½¹Ím¥Ñ•µlÁut€ôˆ(€€€€€€€ˆ¹ÁÉ•ÍÍ•¹½¹¹•Ð¡™Õ¹Œ ¤è}Í¡½Ý}Á…”¡¥Ñ•µlÁt¤¤(€€€€€€€‰½à¹…‘‘}¡¥±¡ˆ¤((€€€Ù…ÈÍÁ…•È€èô½¹ÑÉ½°¹¹•Ü ¤(€€€ÍÁ…•È¹Í¥é•}™±…Í}Ù•ÉÑ¥…°€ô½¹ÑÉ½°¹M%i}aA9}%10(€€€‰½à¹…‘‘}¡¥±¡ÍÁ…•È¤((€€€Ù…ÈÕÍ•È€èô}Á…¹•°¡A91|È°€ÄÐ°½±½È À¸ÈÈ°€À¸Ü°€Ä¸À°€À¸ÄØ¤¤(€€€ÕÍ•È¹ÕÍÑ½µ}µ¥¹¥µÕµ}Í¥é”€ôY•Ñ½ÈÈ À°€Øà¤(€€€‰½à¹…‘‘}¡¥±¡ÕÍ•È¤(€€€Ù…ÈÕÍ•É}É½Ü€èô!	½á½¹Ñ…¥¹•È¹¹•Ü ¤(€€€ÕÍ•É}É½Ü¹Í•Ñ}…¹¡½ÉÍ}…¹‘}½™™Í•ÑÍ}ÁÉ•Í•Ð¡½¹ÑÉ½°¹AIMQ}U11}IP¤(€€€ÕÍ•É}É½Ü¹±…å½ÕÑ}‘¥É•Ñ¥½¸€ô½¹ÑÉ½°¹1e=UQ}%IQ%=9}IQ0(€€€ÕÍ•È¹…‘‘}¡¥±¡ÕÍ•É}É½Ü¤(€€€Ù…È…Ù…Ñ…È€ô±½… ‰É•Ìè¼½ÍÉ¥ÁÑÌ½Õ¤½…Ù…Ñ…É}É•¹‘•É•È¹ˆ¤¹¹•Ü ¤(€€€…Ù…Ñ…È¹…Ù…Ñ…É}¥¹‘•à€ôÁÁMÑ…Ñ”¹…Ù…Ñ…É}¥(€€€…Ù…Ñ…È¹ÕÍÑ½µ}µ¥¹¥µÕµ}Í¥é”€ôY•Ñ½ÈÈ Ìà°€Ìà¤(€€€ÕÍ•É}É½Ü¹…‘‘}¡¥±¡…Ù…Ñ…È¤(€€€Ù…ÈÕÍ•É}¥¹™¼€èôY	½á½¹Ñ…¥¹•È¹¹•Ü ¤(€€€ÕÍ•É}¥¹™¼¹Í¥é•}™±…Í}¡½É¥é½¹Ñ…°€ô½¹ÑÉ½°¹M%i}aA9}%10(€€€ÕÍ•É}É½Ü¹…‘‘}¡¥±¡ÕÍ•É}¥¹™¼¤(€€€}±…‰•°¡ÕÍ•É}¥¹™¼°ÁÁMÑ…Ñ”¹•Ñ}‘¥ÍÁ±…å}¹…µ” ¤°€ÄÐ°QaP¤(€€€}±…‰•°¡ÕÍ•É}¥¹™¼°€‹§uçâç\ÌÖBZ7’.×ŸŠwˆYˆ\Ý]Kš\×Ø]][XØ]Y[ÙH	’hÙ 5£}éÝyø§yØˆ°€ÄÀ°I8¥˜ÁÁMÑ…Ñ”¹¥Í}…ÕÑ¡•¹Ñ¥…Ñ••±Í”5UQ¤((€€€Ù…È±½½ÕÐ€èô}¹…Ù}‰ÕÑÑ½¸ ‰±½½ÕÐˆ°€‹§uçâçxÌÖäB.×ŸŠwtCZ5Ò.×ŸŠwŠBˆÙÛÝ]œ™\ÜÙY˜ÛÛ›™XÝ
ÛÙÛÝ]
Bˆ›Þ˜YØÚ[
ÙÛÝ]
B‚™[˜ÈØZ[ÚXY\Š\™[ˆ[™[ÛÛZ[™\ŠHOˆ›ÚY‚ˆ˜\ˆ›ÝÈH›ÞÛÛZ[™\‹›™]Ê
Bˆ›ÝËœÙ]Ø[˜ÚÜœ×Ø[™ÛÙ™œÙ]×Ü™\Ù]
ÛÛ›Û”‘TÑUÑ•SÔ‘PÕ
Bˆ›ÝË›^[Ý]Ù\™XÝ[ÛˆHÛÛ›Û“VSÕUÑT‘PÕSÓ—Ó‚ˆ›ÝË˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJœÙ\\˜][Ûˆ‹L
Bˆ\™[˜YØÚ[
›ÝÊBˆÙX\˜ÚÛ[™HH[™QY]›™]Ê
BˆÙX\˜ÚÛ[™KœXÙZÛ\—Ý^Hºw^~)ÞuÊhÛ 5£X€ÖtCZ7h×/5£p€Ös›§uçâçBb;§uçâçBbSZ7Éî×ŸŠwË‹‹ˆ‚ˆÙX\˜ÚÛ[™K˜ÛX\—Ø]Û—Ù[˜X›YHYBˆÙX\˜ÚÛ[™KœÚ^™WÙ›YÜ×ÚÜš^›Û[HÛÛ›Û”ÒV‘WÑVS‘Ñ’SˆÙX\˜ÚÛ[™K˜Ý\ÝÛWÛZ[š[][WÜÚ^™HH™XÝÜŒŠŠBˆÙX\˜ÚÛ[™K›^[Ý]Ù\™XÝ[ÛˆHÛÛ›Û“VSÕUÑT‘PÕSÓ—Ô•ˆÙX\˜ÚÛ[™K˜[YÛ›Y[HÔ’V“Ó•SÐSQÓ“QS•Ô’QÒˆ›ÝË˜YØÚ[
ÙX\˜ÚÛ[™JBˆÙX\˜ÚÛ[™K^ØÚ[™ÙY˜ÛÛ›™XÝ
ÜÙX\˜Ú
B‚ˆ˜\ˆ›ÝXÙHHÜÛX[ÚXÛÛ—Ø]ÛŠ˜™[‹ŠBˆ›ÝXÙKÛÛ\Ý^HhÖ%5£|œÖr¢ ¢æ÷F–6Rç&W76VBæ6öææV7B…÷FövvÆUöæ÷F–f–6F–öç2¢&÷ræFEö6†–ÆB†æ÷F–6R ¢&öf–ÆUö'WGFöâÒ÷6ÖÆÅö–6öåö'WGFöâ‚'&öf–ÆR"ÂC"¢&öf–ÆUö'WGFöâçFööÇF—÷FW‡BÒ.×ŸŠwtCZ5Hºw^~)ÞuÑhÞ5ºw^~)Þv"
    profile_button.pressed.connect(func(): _show_page("profile"))
    row.add_child(profile_button)

    var min_btn := _small_icon_button("minimize", 42)
    min_btn.tooltip_text = "5£\èÖZ5‘h×0ºw^~)Þu"
    min_btn.pressed.connect(func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED))
    row.add_child(min_btn)
    var max_btn := _small_icon_button("maximize", 42)
    max_btn.tooltip_text = "5£\ ÖòbsZ7ŽMhß)"éÝyø§y×D5£]Ö’ ¢Ö…ö'Fâç&W76VBæ6öææV7B…÷FövvÆU÷v–æF÷uöÖöFR¢&÷ræFEö6†–ÆB†Ö…ö'Fâ¢f"6Æ÷6Uö'Fâ£Ò÷6ÖÆÅö–6öåö'WGFöâ‚&6Æ÷6R"ÂC"¢6Æ÷6Uö'FâçFööÇF—÷FW‡BÒ.×ŸŠws£Z5Ðˆºw^~)ÞuÑhß(ºw^~)Þu"
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
    _label(profile_text, "5£xÖéÝyø§yÐˆ¥˜ÁÁMÑ…Ñ”¹¥Í}…ÕÑ¡•¹Ñ¥…Ñ••±Í”€™ Ö’Z7Ñ.×ŸŠwˆ‹LÔ‘QSˆYˆ\Ý]Kš\×Ø]][XØ]Y[ÙHUUQ
B‚ˆ˜\ˆXY[™ÈH›ÞÛÛZ[™\‹›™]Ê
BˆXY[™Ë›^[Ý]Ù\™XÝ[ÛˆHÛÛ›Û“VSÕUÑT‘PÕSÓ—Ô•ˆXY[™Ë˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJœÙ\\˜][Ûˆ‹
Bˆ›Þ˜YØÚ[
XY[™ÊBˆ˜\ˆXY[™×ÚXÛÛˆHØY
œ™\Î‹ËÜØÜš\ËÝZKÝ™XÝÜ—ÚXÛÛ‹™ÙŠK›™]Ê
BˆXY[™×ÚXÛÛ‹šXÛÛ—Û˜[YHHœ^Y\œÈ‚ˆXY[™×ÚXÛÛ‹šXÛÛ—ØÛÛÜˆHPÐÑS•Ð”’QÒˆXY[™×ÚXÛÛ‹˜Ý\ÝÛWÛZ[š[][WÜÚ^™HH™XÝÜŒŠ
BˆXY[™Ë˜YØÚ[
XY[™×ÚXÛÛŠBˆ˜\ˆXY[™×Ý^H›ÞÛÛZ[™\‹›™]Ê
BˆXY[™×Ý^œÚ^™WÙ›YÜ×ÚÜš^›Û[HÛÛ›Û”ÒV‘WÑVS‘Ñ’SˆXY[™Ë˜YØÚ[
XY[™×Ý^
BˆÛX™[
XY[™×Ý^h×/5£\šéÝyø§yØ˜œÖr£Z5’.×ŸŠwˆ‹NV
Bˆ˜\ˆÛÝ[HÛX™[
XY[™×Ý^Œºw^~)ÞuÊhÔ", 11, MUTED)
    count.name = "FriendCount"
    friends_box = VBoxContainer.new()
    friends_box.add_theme_constant_override("separation", 6)
    friends_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(friends_box)
    _label(box, &'5£xÔÖt«§uçâçRdSZ5ÒhÙ:"éÝyø§y×D5£]Ö¢Z5Žh×1ºw^~)Þu&G5£\€ÖróZ5ÉÈºw^~)Þw‘h×*"éÝyø§y×D5£yéÝyø§yÔ˜œÖs“Z7ŠHºw^~)ÞuÐ®×ŸŠwËˆ‹KUUQÔ’V“Ó•SÐSQÓ“QS•Ô’QÒ
B‚™[˜ÈØZ[Ø›ÝÛWØ˜\ŠÙ[\—ØÛÛ[[Žˆ›ÞÛÛZ[™\ŠHOˆ›ÚY‚ˆ˜\ˆ˜\ˆHÜ[™[
S‘SÌ‹L‹ÛÛÜŠŒŒ‹ËKŒŒN
JBˆ˜\‹˜Ý\ÝÛWÛZ[š[][WÜÚ^™HH™XÝÜŒŠÎ
BˆÙ[\—ØÛÛ[[‹˜YØÚ[
˜\ŠBˆ˜\ˆ›ÝÈH›ÞÛÛZ[™\‹›™]Ê
Bˆ›ÝËœÙ]Ø[˜ÚÜœ×Ø[™ÛÙ™œÙ]×Ü™\Ù]
ÛÛ›Û”‘TÑUÑ•SÔ‘PÕ
Bˆ›ÝË˜[YÛ›Y[H›ÞÛÛZ[™\‹SQÓ“QS•ÐÑS•T‚ˆ˜\‹˜YØÚ[
›ÝÊBˆÝ]\×ØÛÛ›™XÝ[ÛˆHÛX™[
›ÝË	‰Íh×*5£]è˜èÖZ7n×ŸŠw‹LUUQ
BˆÝ]\×ØÛÛ›™XÝ[Û‹œÚ^™WÙ›YÜ×ÚÜš^›Û[HÛÛ›Û”ÒV‘WÑVS‘Ñ’SˆÝ]\×ÜÙ\™\ˆHÛX™[
›ÝË	‰ÍhÞ'5£Tè‹§uçâçy*éÝyø§yÔ™Öòò"ÂÂÕUDTB¢7FGW5÷6W'fW"ç6—¦UöfÆw5ö†÷&—¦öçFÂÒ6öçG&öÂå4•¤UôU…äEôd”ÄÀ¢7FGW5ög2ÒöÆ&VÂ‡&÷rÂ$e3¢VB"RVæv–æRævWEög&ÖW5÷W%÷6V6öæB‚’ÂÂÕUDTB¢7FGW5ög2ç6—¦UöfÆw5ö†÷&—¦öçFÂÒ6öçG&öÂå4•¤UôU…äEôd”ÄÀ¢7FGW5ög&–VæG2ÒöÆ&VÂ‡&÷rÂbsZ5ÍMhÖ'ºw^~)Þu: 0", 10, MUTED)
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
    _quick_card(quick, "world", &%5£XžéÝyø§yÔ˜äÖdR.×ŸŠwâóZ7È‹hÞ/ºw^~)Þw&E5£]Ö’Z7ÐMhÞ)"éÝyø§y×95£y.éÝyø§yÜˆ°™Õ¹Œ ¤è}Á…•}É•…Ñ•}Ý½É± ¤¤(€€€}ÅÕ¥­}…É¡ÅÕ¥¬°€‰Á±…å•ÉÌˆ°€ˆÖã“Z7ÈhÖD5£| Öb"Â#Z7Ë®×ŸŠw	‹h×)"éÝyø§yß(ºw^~)Þu&'5£X Ö’"ÂgVæ2‚“¢÷6†÷u÷vR‚&×VÇF—Æ–W""’¢÷V–6µö6&B‡V–6²Â'6W'fW'2"Â#Z5ÉhÙ 5£X¸Örû§uçâçR"ÂbsZ7’hßE"éÝyø§y×D5£}Öâ’.×ŸŠwbóZ4È‹[˜Ê
NˆÜÚÝ×ÜYÙJœÙ\™\œÈŠJBˆÜÙXÝ[Û—Ý]JÛÛ[	‰ÍhßH5£Y‹§uçâç]Öä£Z6H‹hÖ(5£]Ö¢Z5ˆØ]™Qˆºw^~)ÞuÐ®×ŸŠwÈŠBˆÝÛÜ›ØØ\™ÊÛÛ[Ø]™Q‹›\ÝÝÛÜ›Ê
JB‚™[˜ÈÚ\›×Ü[™[

HOˆ[™[ÛÛZ[™\Ž‚ˆ˜\ˆ[™[H[™[ÛÛZ[™\‹›™]Ê
Bˆ[™[œÙ]ÛY]Jœ™\ÜÛœÚ]™WÜ›ÛH‹š\›ÈŠBˆ[™[˜Ý\ÝÛWÛZ[š[][WÜÚ^™HH™XÝÜŒŠÍÌ
Bˆ[™[˜YÝ[YWÜÝ[X›ÞÛÝ™\œšYJœ[™[‹ÜÝ[JS‘SÛÛÜŠŒKÍKKŒŒÌŠJJBˆ˜\ˆ\H^\™T™XÝ›™]Ê
Bˆ\^\™HHØY
‘×ÔU
H\È^\™L‘ˆ\™^[™Û[ÙHH^\™T™XÝ‘VS‘ÒQÓ“Ô‘WÔÒV‘Bˆ\œÝ™]ÚÛ[ÙHH^\™T™XÝ”Õ‘UÒÒÑQTÐTÔPÕÐÓÕ‘T‘Qˆ[™[˜YØÚ[
\
Bˆ˜\ˆÝ™\›^HHÛÛÜ”™XÝ›™]Ê
BˆÝ™\›^KœÙ]Ø[˜ÚÜœ×Ø[™ÛÙ™œÙ]×Ü™\Ù]
ÛÛ›Û”‘TÑUÑ•SÔ‘PÕ
BˆÝ™\›^K˜ÛÛÜˆHÛÛÜŠŒŒKŒËŒÍŠBˆ\˜YØÚ[
Ý™\›^JBˆ˜\ˆX\™Ú[ˆHX\™Ú[ÛÛZ[™\‹›™]Ê
BˆX\™Ú[‹œÙ]Ø[˜ÚÜœ×Ø[™ÛÙ™œÙ]×Ü™\Ù]
ÛÛ›Û”‘TÑUÑ•SÔ‘PÕ
BˆX\™Ú[‹˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJ›X\™Ú[—ÛY‹ŠBˆX\™Ú[‹˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJ›X\™Ú[—ÝÜ‹ŒŠBˆX\™Ú[‹˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJ›X\™Ú[—ÜšYÚ‹ŠBˆX\™Ú[‹˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJ›X\™Ú[—Ø›ÝÛH‹ŒŠBˆÝ™\›^K˜YØÚ[
X\™Ú[ŠBˆ˜\ˆ›ÞH›ÞÛÛZ[™\‹›™]Ê
Bˆ›Þ˜[YÛ›Y[H›ÞÛÛZ[™\‹SQÓ“QS•ÐÑS•T‚ˆ›Þ˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJœÙ\\˜][Ûˆ‹L
BˆX\™Ú[‹˜YØÚ[
›Þ
BˆÛX™[
›ÞQUH‹VÔ’V“Ó•SÐSQÓ“QS•ÐÑS•TŠBˆÛX™[
›Þ•ÒS“ÕS‘‹ŒËPÐÑS•Ð”’QÒÔ’V“Ó•SÐSQÓ“QS•ÐÑS•TŠBˆÛX™[
›Þºw^~)ÞwÉÍh×C.&E5£]Öä2âd#Z7Ëˆ‹MËVÔ’V“Ó•SÐSQÓ“QS•ÐÑS•TŠBˆÛX™[
›ÞhÞ'5£T€ÖãZ5’®×ŸŠwI‘MhÞE5£|0‹§uçâç\ÌÖsCZ5Ãºw^~)Þwh×"éÝyø§yÞF5£\0‹§uçâçyÖ‚Z5ÉÍhÚ.", 11, Color(0.9,0.96,1.0,0.82), HORIZONTAL_ALIGNMENT_CENTER)
    var play := _primary_button(&'5£|Œ‹§uçâç]Öò‚"ÂfV7F÷#"ƒ#cÂSB’¢Æ’ç&W76VBæ6öææV7B†gVæ2‚“¢Æ•÷6–ævÆWÆ–W"æVÖ—B‚’¢&÷‚æFEö6†–ÆB‡Æ’¢f"7V"£Ò„&÷„6öçF–æW"ææWr‚¢7V"æÆ–væÖVçBÒ&÷„6öçF–æW"äÄ”täÔTåEô4TåDU ¢7V"æFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'6W&F–öâ"Â‚¢&÷‚æFEö6†–ÆB‡7V"¢f"6öÆò£Òö'WGFöâ‚bsZ5Žn×ŸŠw	‰Íh×15£hˆ°Y•Ñ½ÈÈ ÄÔÀ°€Ìà¤¤(€€€Í½±¼¹ÁÉ•ÍÍ•¹½¹¹•Ð¡™Õ¹Œ ¤è}Í¡½Ý}Á…” ‰Í½±¼ˆ¤¤(€€€ÍÕˆ¹…‘‘}¡¥±¡Í½±¼¤(€€€Ù…ÈµÕ±Ñ¤€èô}‰ÕÑÑ½¸ ˆÖã“Z7ÈhÖD5£| Öb"ÂfV7F÷#"ƒsÂ3‚’¢×VÇF’ç&W76VBæ6öææV7B†gVæ2‚“¢÷6†÷u÷vR‚&×VÇF—Æ–W""’¢7V"æFEö6†–ÆB†×VÇF’ ¢f"FWfVÆ÷W%ö7&VF—B£Ò÷æVÂ„6öÆ÷"ƒãÂã#RÂãSRÂãs‚’Â"Â6öÆ÷"ƒã3RÂã‚ÂãÂã#"’¢FWfVÆ÷W%ö7&VF—Bç6WEöæ6†÷'5÷&W6WB„6öçG&öÂå$U4UEô$õEDôÕôÄTeB¢FWfVÆ÷W%ö7&VF—Bç÷6—F–öâÒfV7F÷#"ƒ‚ÂÓ‚¢FWfVÆ÷W%ö7&VF—Bç6—¦RÒfV7F÷#"ƒ#CÂCb¢FWfVÆ÷W%ö7&VF—BæÖ÷W6Uöf–ÇFW"Ò6öçG&öÂäÔõU4Uôd”ÅDU%ô”täõ$P¢f"7&VF—E÷&÷r£Ò„&÷„6öçF–æW"ææWr‚¢7&VF—E÷&÷rç6WEöæ6†÷'5öæEööfg6WG5÷&W6WB„6öçG&öÂå$U4UEôeTÄÅõ$T5B¢7&VF—E÷&÷ræÆ–÷WEöF—&V7F–öâÒ6öçG&öÂäÄ”õUEôD•$T5D”ôåõ%DÀ¢7&VF—E÷&÷ræFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'6W&F–öâ"Âr¢FWfVÆ÷W%ö7&VF—BæFEö6†–ÆB†7&VF—E÷&÷r¢f"FWeö–6öâÒÆöB‚'&W3¢ò÷67&—G2÷V’÷fV7F÷%ö–6öâævB"’ææWr‚¢FWeö–6öâæ–6öåöæÖRÒ&&FvR ¢FWeö–6öâæ–6öåö6öÆ÷"Ò44TåEô%$”t…@¢FWeö–6öâæ7W7FöÕöÖ–æ–×VÕ÷6—¦RÒfV7F÷#"ƒ#BÂ#B¢7&VF—E÷&÷ræFEö6†–ÆB†FWeö–6öâ¢f"7&VF—E÷FW‡B£Òd&÷„6öçF–æW"ææWr‚¢7&VF—E÷FW‡Bç6—¦UöfÆw5ö†÷&—¦öçFÂÒ6öçG&öÂå4•¤UôU…äEôd”ÄÀ¢7&VF—E÷&÷ræFEö6†–ÆB†7&VF—E÷FW‡B¢öÆ&VÂ†7&VF—E÷FW‡BÂbsZ5ÍÍhÑ:"éÝyø§yß(5£]ÖrZ5Ì®×ŸŠwH‹LV
BˆÛX™[
Ü™Y]Ý^h×E5£d€ÖãsZ7ŒN‰ŽMhß'5£Y‹§uçâçXœÖR"Â’ÂÕUDTB ¢&WGW&âæVÀ ¦gVæ2ö'V–ÆEöWF…övFR‚’Óâfö–C ¢–b7FFRæ—5öWF†VçF–6FVC ¢&WGW&à¢WF…ö÷fW&Æ’Ò÷æVÂ„6öÆ÷"ƒãÂã"ÂãCRÂã“b’Â#bÂ6öÆ÷"ƒã#RÂãsRÂãÂãC‚’¢WF…ö÷fW&Æ’ç6WEöæ6†÷'5öæEööfg6WG5÷&W6WB„6öçG&öÂå$U4UEõDõôÄTeB¢FEö6†–ÆB†WF…ö÷fW&Æ’¢öÆ–÷WEöWF…ö÷fW&Æ’‚¢f"Ö&v–â£ÒÖ&v–ä6öçF–æW"ææWr‚¢Ö&v–âç6WEöæ6†÷'5öæEööfg6WG5÷&W6WB„6öçG&öÂå$U4UEôeTÄÅõ$T5B¢Ö&v–âæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚&Ö&v–åöÆVgB"Â3B¢Ö&v–âæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚&Ö&v–å÷F÷"Â3¢Ö&v–âæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚&Ö&v–å÷&–v‡B"Â3B¢Ö&v–âæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚&Ö&v–åö&÷GFöÒ"Â3¢WF…ö÷fW&Æ’æFEö6†–ÆB†Ö&v–â¢f"&÷‚£Òd&÷„6öçF–æW"ææWr‚¢&÷‚æFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'6W&F–öâ"Â¢Ö&v–âæFEö6†–ÆB†&÷‚¢öÆ&VÂ†&÷‚Âb£Z7’®×ŸŠw	‰Íhß.5£P€Öd’UD…$"Â#rÂDU…BÂ„õ$•¤ôåDÅôÄ”täÔTåEô4TåDU"¢öÆ&VÂ†&÷‚Â#Z5Éî×ŸŠw	‹MhÞBºw^~)Þv&E5£]"éÝyø§yÐ˜äÖ’Z5‰Èºw^~)ÞuÑh×'5£p€Ös’.×ŸŠwäƒZ4HhßEºw^~)Þu&'5£|ÌÖ‚Z5ŠhÞ/ºw^~)Þu&*5£\¨ÖôR.×ŸŠwäCZ5Éhß'.", 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    auth_server = LineEdit.new()
    auth_server.text = str(Settings.get_value("auth_server_url", "http://127.0.0.1:8090"))
    auth_server.visible = false
    auth_user = LineEdit.new()
    auth_user.placeholder_text = "éÝyø§y×3ºw^~)Þu&'5£\ÌÖâû§uçâçR ¢WF…÷W6W"æÆ–væÖVçBÒ„õ$•¤ôåDÅôÄ”täÔTåEõ$”t…@¢WF…÷W6W"æ7W7FöÕöÖ–æ–×VÕ÷6—¦RÒfV7F÷#"ƒÂCB¢&÷‚æFEö6†–ÆB†WF…÷W6W"¢WF…÷77v÷&BÒÆ–æTVF—BææWr‚¢WF…÷77v÷&BçÆ6V†öÆFW%÷FW‡BÒd3Z5ÊHºw^~)ÞuÑh×Hºw^~)Þu"
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
    var submit := _primary_button("éÝyø§yÞ35£y‹§uçâç]Öä‹§uçâçB"ÂfV7F÷#"ƒ“ÂCb’¢7V&Ö—Bç&W76VBæ6öææV7B…÷7V&Ö—EöWF‚¢&÷ræFEö6†–ÆB‡7V&Ö—B¢f"FövvÆR£Òö'WGFöâ‚bSZ5‰î×ŸŠwI‹Mh×(", Vector2(150, 46))
    toggle.pressed.connect(func():
        auth_register_mode = not auth_register_mode
        submit.text = &%5£XžéÝyø§yÔ˜œÖó3Z6ˆYˆ]]Ü™YÚ\Ý\—Û[ÙH[ÙH	ŠhÞJºw^~)Þt&'5£|¸ÖB ¢FövvÆRçFW‡BÒ#Z7Òˆºw^~)ÞwÌÍhØ" if auth_register_mode else &%5£XžéÝyø§yÔ˜´Ör‚ ¢¢&÷ræFEö6†–ÆB‡FövvÆR¢f"öffÆ–æR£Òö'WGFöâ‚dSZ5ÊhÙ 5£y‹§uçâç|ÌÖ‚"ÂfV7F÷#"ƒƒÂC"’¢öffÆ–æRç&W76VBæ6öææV7B†gVæ2‚“¢WF…ö÷fW&Æ’çVWVUög&VR‚“²WF…ö÷fW&Æ’ÒçVÆÂ¢&÷‚æFEö6†–ÆB†öffÆ–æR¢WF…÷7FGW2ÒöÆ&VÂ†&÷‚Â#Z5‹MhÖ):&Aºw^~)Þv&'5£xàÖZ7ËhÔ 5£xœÖr«§uçâçr"ÂÂÕUDTBÂ„õ$•¤ôåDÅôÄ”täÔTåEô4TåDU"¢öÆ&VÂ†&÷‚Â.×ŸŠwtCZ7’®×ŸŠwI’hÖ-5£X¤‹§uçâç]Öä3Z6Hh× 5£|äÖã.×ŸŠwr£Z5ŠHºw^~)ÞuÑ.×ŸŠwÉŠhß 5£xžéÝyø§yÔ˜œÖâóZ6HhÖA5£Y*éÝyø§yÔ¸ˆ°€ä°½±½È À¸ØÔ°À¸Üà°À¸ä°À¸ÜÔ¤°!=I%i=9Q1}1%959Q}9QH¤()™Õ¹Œ}ÍÕ‰µ¥Ñ}…ÕÑ  ¤€´øÙ½¥è(€€€¥˜…ÕÑ¡}ÕÍ•È¹Ñ•áÐ¹ÍÑÉ¥Á}•‘•Ì ¤¹¥Í}•µÁÑä ¤½È…ÕÑ¡}Á…ÍÍÝ½É¹Ñ•áÐ¹±•¹Ñ  ¤€ð€àè(€€€€€€€…ÕÑ¡}ÍÑ…ÑÕÌ¹Ñ•áÐ€ô€‹§uçâç]ÖtK§uçâçS¢Z5ÑHºw^~)ÞuÑh×*5£}‹§uçâç] ‹§uçâç]Ö’Z5‘MhÞ1"éÝyø§yÞJºw^~)Þu&55£X¶éÝyø§yÔ¸ˆ(€€€€€€€…ÕÑ¡}ÍÑ…ÑÕÌ¹…‘‘}Ñ¡•µ•}½±½É}½Ù•ÉÉ¥‘” ‰™½¹Ñ}½±½Èˆ°I¤(€€€€€€€É•ÑÕÉ¸(€€€Ù…ÈÉ½½Ð€ô•Ñ}Á…É•¹Ð ¤(€€€Ù…È…ÕÑ¡}¹½‘”€ôÉ½½Ð¹•Ð ‰…ÕÑ ˆ¤¥˜É½½Ð€„ô¹Õ±°•±Í”¹Õ±°(€€€¥˜…ÕÑ¡}¹½‘”€ôô¹Õ±°è(€€€€€€€…ÕÑ¡}ÍÑ…ÑÕÌ¹Ñ•áÐ€ô€ˆÖbÓZ5ŠN‰‹h×)"éÝyø§y×D5£\œÖb’.×ŸŠwä«§uçâçRdSZ5Ën×ŸŠwIn×ŸŠw‰‰ÍhÞ75£y¸ˆ(€€€€€€€É•ÑÕÉ¸(€€€Ù…È…ÕÑ¡}ÕÉ°€èô…ÕÑ¡}Í•ÉÙ•È¹Ñ•áÐ¹ÍÑÉ¥Á}•‘•Ì ¤(€€€M•ÑÑ¥¹Ì¹Í•Ñ}Ù…±Õ” ‰…ÕÑ¡}Í•ÉÙ•É}ÕÉ°ˆ°…ÕÑ¡}ÕÉ°¤(€€€…ÕÑ¡}¹½‘”¹½¹™¥ÕÉ”¡…ÕÑ¡}ÕÉ°¤(€€€…ÕÑ¡}ÍÑ…ÑÕÌ¹Ñ•áÐ€ô€˜œÖòsZ6Nˆºw^~)Þw‰ÍhÝ 5£XœÖr{§uçâçBbƒZ5‹h×)..."
    auth_status.add_theme_color_override("font_color", YELLOW)
    var character := str(characters[character_index].id)
    if auth_register_mode:
        auth_node.register(auth_user.text.strip_edges(), auth_password.text, character, AppState.avatar_id)
    else:
        auth_node.login(auth_user.text.strip_edges(), auth_password.text)

func set_connection_status(text: String) -> void:
    if status_connection:
        status_connection.text = &'5£\¨ÖtC¢"²FW‡@¢7FGW5ö6öææV7F–öâæFE÷F†VÖUö6öÆ÷%ö÷fW'&–FR‚&föçEö6öÆ÷""Â”TÄÄõr ¦gVæ2&Vg&W6…÷&öf–ÆR‚’Óâfö–C ¢–b&öf–ÆUö'WGFöã ¢&öf–ÆUö'WGFöâçFööÇF—÷FW‡BÒ"W2ÒW2"R´7FFRçÆ–W%öæÖRÂ.×ŸŠwr£Z5ˆYˆ\Ý]Kš\×Ø]][XØ]Y[ÙHhÖ9"éÝyø§y×-5£h‰t(€€€¥˜…ÕÑ¡}½Ù•É±…ä…¹ÁÁMÑ…Ñ”¹¥Í}…ÕÑ¡•¹Ñ¥…Ñ•è(€€€€€€€…ÕÑ¡}½Ù•É±…ä¹ÅÕ•Õ•}™É•” ¤(€€€€€€€…ÕÑ¡}½Ù•É±…ä€ô¹Õ±°()™Õ¹Œ¹½Ñ¥™å}…ÕÑ¡}™…¥±ÕÉ”¡µ•ÍÍ…”èMÑÉ¥¹œ¤€´øÙ½¥è(€€€¥˜…ÕÑ¡}ÍÑ…ÑÕÌè(€€€€€€€…ÕÑ¡}ÍÑ…ÑÕÌ¹Ñ•áÐ€ô€˜œÖòsZ6Nˆˆ
ÈY\ÜØYÙBˆ]]ÜÝ]\Ë˜YÝ[YWØÛÛÜ—ÛÝ™\œšYJ™›ÛØÛÛÜˆ‹‘Q
B‚™[˜ÈÜYÙWØÜ™X]WÝÛÜ›

HOˆ›ÚY‚ˆ›ÜˆÚ[[ˆÛÛ[™Ù]ØÚ[™[Š
N‚ˆÚ[œ]Y]YWÙœ™YJ
BˆÜÙXÝ[Û—Ý]JÛÛ[hÖ45£D€ÖtK§uçâçRbÃZ7‹È‹ºw^~)ÞuÑºw^~)Þu’hÙ 5£Xœ‹§uçâçy<Ös‚.×ŸŠws’.×ŸŠwtCZ5Ñ.×ŸŠwHŠBˆ˜\ˆ[™[HÜ[™[
S‘SŒÛÛÜŠŒŒ‹ËKŒŒŠJBˆ[™[˜Ý\ÝÛWÛZ[š[][WÜÚ^™HH™XÝÜŒŠ
BˆÛÛ[˜YØÚ[
[™[
Bˆ˜\ˆ›Ü›HH›ÞÛÛZ[™\‹›™]Ê
Bˆ›Ü›K›^[Ý]Ù\™XÝ[ÛˆHÛÛ›Û“VSÕUÑT‘PÕSÓ—Ô•ˆ›Ü›K˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJœÙ\\˜][Ûˆ‹L
Bˆ[™[˜YØÚ[
›Ü›JBˆ˜\ˆ˜[YWÙšY[H[™QY]›™]Ê
Bˆ˜[YWÙšY[›˜[YHH•ÛÜ›˜[YH‚ˆ˜[YWÙšY[œXÙZÛ\—Ý^Hºw^~)ÞuÌî×ŸŠwI‰Íhß'5£Tˆ(€€€¹…µ•}™¥•±¹Ñ•áÐ€ô€‰]¥±‘‰½Õ¹]½É±ˆ(€€€™½É´¹…‘‘}¡¥±¡¹…µ•}™¥•±¤(€€€Ù…ÈÍ••‘}™¥•±€èô1¥¹•‘¥Ð¹¹•Ü ¤(€€€Í••‘}™¥•±¹Á±…•¡½±‘•É}Ñ•áÐ€ô€ˆÖbƒZ5ÊHºw^~)ÞuÒºw^~)ÞuÊh×Gºw^~)Þw&95£xœÖâ’ ¢6VVEöf–VÆBçFW‡BÒ7G"‡&æF•÷&ævRƒÂ#CsCƒ’¢f÷&ÒæFEö6†–ÆB‡6VVEöf–VÆB¢f"ÖöFR£Ò÷F–öä'WGFöâææWr‚¢ÖöFRæFEö—FVÒ‚#Z5‰î×ŸŠwHŠBˆ[ÙK˜YÚ][J	‰Mhß'5£hˆ¤(€€€Ù…Èµ½‘•}¥‘Ì€èôl‰ÍÕÉÙ¥Ù…°ˆ°€‰É•…Ñ¥Ù”‰t(€€€™½É´¹…‘‘}¡¥±¡µ½‘”¤((€€€Ù…ÈÝ½É±‘}ÑåÁ”€èô=ÁÑ¥½¹	ÕÑÑ½¸¹¹•Ü ¤(€€€Ý½É±‘}ÑåÁ”¹…‘‘}¥Ñ•´ ‹§uçâç|œÖRZ7’hÚ")
    world_type.add_item("5£]éÝyø§yÔ˜ÔÖrsZ6ˆŠBˆÛÜ›Ý\K˜YÚ][Jh×Dºw^~)Þu&:5£x¤ˆ¤(€€€Ý½É±‘}ÑåÁ”¹…‘‘}¥Ñ•´ ‹§uçâç|œÖRZ5’hÚ")
    var world_type_ids := ["", "arid", "grove", "frost"]
    form.add_child(world_type)
    var difficulty := OptionButton.new()
    difficulty.add_item("5£YéÝyø§yØˆ¤(€€€‘¥™™¥Õ±Ñä¹…‘‘}¥Ñ•´ ˜ÌÖB"¢F–ff–7VÇG’æFEö—FVÒ‚#Z5Ëî×ŸŠwˆŠBˆY™šXÝ[K˜YÚ][J	MhØ")
    var difficulty_ids := ["peaceful", "easy", "normal", "hard"]
    difficulty.select(2)
    form.add_child(difficulty)
    var height := OptionButton.new()
    height.add_item("éÝyø§yßEºw^~)Þv 500")
    height.add_item(&95£H€àÀÀˆ¤(€€€¡•¥¡Ð¹…‘‘}¥Ñ•´ ˆÖt""¢†V–v‡Bç6VÆV7Bƒ¢f÷&ÒæFEö6†–ÆB††V–v‡B¢f"&—f7’£Ò÷F–öä'WGFöâææWr‚¢&—f7’æFEö—FVÒ‚c“Z5HŠBˆš]˜XÞK˜YÚ][Jh×5")
    privacy.add_item("éÝyø§yÖD5£\¼Ör.×ŸŠwt+§uçâçr"¢f"&—f7•ö–G2£Ò²'V&Æ–2"Â'&—fFR"Â&g&–VæG5ööæÇ’%Ð¢&—f7’ç6VÆV7Bƒ¢f÷&ÒæFEö6†–ÆB‡&—f7’¢f"7G'V7GW&W2£Ò6†V6´&÷‚ææWr‚¢7G'V7GW&W2çFW‡BÒ.×ŸŠwtcZ5ÈHºw^~)ÞuÑhÞ'5£h€ÖcsZ7ŽMhÙ"
    structures.button_pressed = true
    form.add_child(structures)
    var creatures := CheckBox.new()
    creatures.text = "éÝyø§y×D5£yÖb{§uçâçb ¢7&VGW&W2æ'WGFöå÷&W76VBÒG'VP¢f÷&ÒæFEö6†–ÆB†7&VGW&W2¢f"vVF†W"£Ò6†V6´&÷‚ææWr‚¢vVF†W"çFW‡BÒ#Z5ÍhÓ"
    weather.button_pressed = true
    form.add_child(weather)
    var starting_inventory := LineEdit.new()
    starting_inventory.placeholder_text = "éÝyø§y×.5£y‹§uçâç]ÖòsZ7Ãºw^~)ÞuÊÍhÔ: 1=64, 2=32"
    form.add_child(starting_inventory)
    var controls := HBoxContainer.new()
    controls.alignment = BoxContainer.ALIGNMENT_END
    form.add_child(controls)
    var cancel := _button(&%5£xžéÝyø§yÔˆ°Y•Ñ½ÈÈ ÄÈÀ°€ÐÈ¤¤(€€€…¹•°¹ÁÉ•ÍÍ•¹½¹¹•Ð¡™Õ¹Œ ¤è}Í¡½Ý}Á…” ‰¡½µ”ˆ¤¤(€€€½¹ÑÉ½±Ì¹…‘‘}¡¥±¡…¹•°¤(€€€Ù…ÈÉ•…Ñ”€èô}ÁÉ¥µ…Éå}‰ÕÑÑ½¸ ˜”Öb{§uçâçRdƒZ7‹î×ŸŠwÈ‹™XÝÜŒŠNL
JBˆÜ™X]Kœ™\ÜÙY˜ÛÛ›™XÝ
[˜Ê
N‚ˆ˜\ˆÙYYÝ˜[YHH[
ÙYYÙšY[^
HYˆÙYYÙšY[^š\×Ý˜[YÚ[

H[ÙH˜[™WÜ˜[™ÙJKŒMÍ
Bˆ\Ý]Kœ[™[™×ÝÛÜ›ØÛÛ™šYÈHÂˆ›˜[YHŽˆ˜[YWÙšY[^œÝš\ÙYÙ\Ê
HYˆ›Ý˜[YWÙšY[^œÝš\ÙYÙ\Ê
Kš\×Ù[\J
H[ÙH•Ú[›Ý[™ÛÜ›‹ˆœÙYYŽˆÙYYÝ˜[YKˆ›[ÙHŽˆ[ÙWÚYÖÛ[ÙKœÙ[XÝYKˆÛÜ›Ý\HŽˆÛÜ›Ý\WÚYÖÝÛÜ›Ý\KœÙ[XÝYKˆ™Y™šXÝ[HŽˆY™šXÝ[WÚYÖÙY™šXÝ[KœÙ[XÝYKˆÛÜ›ÚZYÚŽˆÍLLVÚZYÚœÙ[XÝYKˆÛÜ›Ü˜Y]\ÈŽˆÌÍŽˆœš]˜XÞHŽˆš]˜XÞWÚYÖÜš]˜XÞKœÙ[XÝYKˆœÝXÝ\™\ÈŽˆÝXÝ\™\Ë˜]Û—Ü™\ÜÙYˆ˜Ü™X]\™\ÈŽˆÜ™X]\™\Ë˜]Û—Ü™\ÜÙYˆÙX]\ˆŽˆÙX]\‹˜]Û—Ü™\ÜÙYˆœÝ\[™×Ú[™[ÜžHŽˆÜ\œÙWÜÝ\[™×Ú[™[ÜžJÝ\[™×Ú[™[ÜžK^
KˆBˆ^WÜÚ[™Û\^Y\‹™[Z]

Bˆ
BˆÛÛ›ÛË˜YØÚ[
Ü™X]JB‚™[˜ÈÜYÙWÜÛÛÊ
HOˆ›ÚY‚ˆÜÙXÝ[Û—Ý]JÛÛ[ºw^~)ÞuÑhß("éÝyø§y×D5£\¾éÝyø§yØˆ°€˜äÖtK§uçâçRdSZ5ÒhÙ 5£Y$‹§uçâçyÖd2"¢f"æWu÷v÷&ÆB£Ò÷&–Ö'•ö'WGFöâ‚bSZ5‰î×ŸŠwIŽMhÖE"éÝyø§yÞ/5£|ˆ°Y•Ñ½ÈÈ ÈÐÀ°€Ðà¤¤(€€€¹•Ý}Ý½É±¹ÁÉ•ÍÍ•¹½¹¹•Ð¡}Á…•}É•…Ñ•}Ý½É±¤(€€€½¹Ñ•¹Ð¹…‘‘}¡¥±¡¹•Ý}Ý½É±¤(€€€}Ý½É±‘}…É‘Ì¡½¹Ñ•¹Ð°M…Ù•¹±¥ÍÑ}Ý½É±‘Ì ¤¤()™Õ¹Œ}Á…ÉÍ•}ÍÑ…ÉÑ¥¹}¥¹Ù•¹Ñ½Éä¡Ñ•áÐèMÑÉ¥¹œ¤€´ø¥Ñ¥½¹…Éäè(€€€Ù…ÈÉ•ÍÕ±Ð€èôíô(€€€™½ÈÁ…ÉÐ¥¸Ñ•áÐ¹ÍÁ±¥Ð ˆ°ˆ¤è(€€€€€€€Ù…ÈÁ…¥È€èôÁ…ÉÐ¹ÍÑÉ¥Á}•‘•Ì ¤¹ÍÁ±¥Ð ˆôˆ¤(€€€€€€€¥˜Á…¥È¹Í¥é” ¤€ôô€È…¹Á…¥ÉlÁt¹¥Í}Ù…±¥‘}¥¹Ð ¤…¹Á…¥ÉlÅt¹¥Í}Ù…±¥‘}¥¹Ð ¤è(€€€€€€€€€€€Ù…È¥Ñ•µ}¥€èô¥¹Ð¡Á…¥ÉlÁt¤(€€€€€€€€€€€Ù…È…µ½Õ¹Ð€èôµ…á¤ À°¥¹Ð¡Á…¥ÉlÅt¤¤(€€€€€€€€€€€¥˜¥Ñ•µ}¥€øô€À…¹…µ½Õ¹Ð€ø€Àè(€€€€€€€€€€€€€€€É•ÍÕ±Ñm¥Ñ•µ}¥‘t€ô…µ½Õ¹Ð(€€€É•ÑÕÉ¸É•ÍÕ±Ð()™Õ¹Œ}Á…•}Ý½É±‘Ì ¤€´øÙ½¥è(€€€}Í•Ñ¥½¹}Ñ¥Ñ±”¡½¹Ñ•¹Ð°€‹§uçâç]ÖâsZ5H‹hß'5£d€Öc“Z5Ñ.×ŸŠwI‰Íh×-5£xâéÝyø§yÔˆ¤(€€€}Ý½É±‘}…É‘Ì¡½¹Ñ•¹Ð°M…Ù•¹±¥ÍÑ}Ý½É±‘Ì ¤°ÑÉÕ”¤()™Õ¹Œ}Ý½É±‘}…É‘Ì¡Á…É•¹Ðè½¹ÑÉ½°°Ý½É±‘ÌèÉÉ…ä°µ…¹…”€èô™…±Í”¤€´øÙ½¥è(€€€¥˜Ý½É±‘Ì¹¥Í}•µÁÑä ¤è(€€€€€€€Ù…È•µÁÑä€èô}Á…¹•°¡A91|È°€Äà°½±½È À¸ÈÈ°€À¸Ü°€Ä¸À°€À¸ÄÈ¤¤(€€€€€€€Á…É•¹Ð¹…‘‘}¡¥±¡•µÁÑä¤(€€€€€€€}±…‰•°¡•µÁÑä°€‹§uçâçXœ‹§uçâçy ÖòZ7‰ÍhÕ 5£}Öâ’.×ŸŠwã›§uçâçrâ"ÂBÂÕUDTBÂ„õ$•¤ôåDÅôÄ”täÔTåEô4TåDU"¢&WGW&à¢f"w&–B£Òw&–D6öçF–æW"ææWr‚¢w&–Bæ6öÇVÖç2Ò ¢w&–BæÆ–÷WEöF—&V7F–öâÒ6öçG&öÂäÄ”õUEôD•$T5D”ôåõ%DÀ¢w&–BæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚&…÷6W&F–öâ"Â¢w&–BæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'e÷6W&F–öâ"Â¢&VçBæFEö6†–ÆB†w&–B¢f÷"v÷&ÆB–âv÷&ÆG3 ¢f"6&B£Ò÷æVÂ…äTÅó"ÂbÂ6öÆ÷"ƒã#"ÂãrÂãÂãB’¢6&Bæ7W7FöÕöÖ–æ–×VÕ÷6—¦RÒfV7F÷#"ƒÂS¢w&–BæFEö6†–ÆB†6&B¢f"Ö&v–â£ÒÖ&v–ä6öçF–æW"ææWr‚¢Ö&v–âæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚&Ö&v–åöÆVgB"ÂB¢Ö&v–âæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚&Ö&v–å÷F÷"Â"¢Ö&v–âæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚&Ö&v–å÷&–v‡B"ÂB¢Ö&v–âæFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚&Ö&v–åö&÷GFöÒ"Â"¢6&BæFEö6†–ÆB†Ö&v–â¢f"&÷‚£Òd&÷„6öçF–æW"ææWr‚¢&÷‚æFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'6W&F–öâ"Âb¢Ö&v–âæFEö6†–ÆB†&÷‚¢f"F‡VÖ"£ÒFW‡GW&U&V7BææWr‚¢F‡VÖ"çFW‡GW&RÒÆöB„$uõD‚’2FW‡GW&S$@¢F‡VÖ"æ7W7FöÕöÖ–æ–×VÕ÷6—¦RÒfV7F÷#"ƒÂs‚¢F‡VÖ"æW‡æEöÖöFRÒFW‡GW&U&V7BäU…äEô”täõ$Uõ4•¤P¢F‡VÖ"ç7G&WF6…öÖöFRÒFW‡GW&U&V7Bå5E$UD4…ô´TUô5T5Eô4õdU$T@¢F‡VÖ"æÖ÷W6Uöf–ÇFW"Ò6öçG&öÂäÔõU4Uôd”ÅDU%ô”täõ$P¢&÷‚æFEö6†–ÆB‡F‡VÖ"¢f"ÖWF¢F–7F–öæ'’Òv÷&ÆBævWB‚&ÖWFFF"Â·Ò¢öÆ&VÂ†&÷‚Â7G"†ÖWFævWB‚&æÖR"Âv÷&ÆBævWB‚&–B"Â%v÷&ÆB"’’’ÂrÂDU…B¢öÆ&VÂ†&÷‚Â#Z5‘h×: %s" % _mode_label(str(meta.get("mode", "unknown")) ), 10, MUTED)
        _label(box, "5£X Ör“¢W2"R7G"†ÖWFævWB‚'6VVB"Â#Z7ŒHºw^~)ÞuËMhß")), 10, MUTED)
        _label(box, "5£xÄ‹§uçâçXæéÝyø§yÐè€•Ìˆ€”ÍÑÈ¡µ•Ñ„¹•Ð ‰Í…Ù•‘}…Ðˆ°€˜èÖZ7Ëî×ŸŠwÈŠJKKUUQ
Bˆ˜\ˆXÝ[ÛœÈH›ÞÛÛZ[™\‹›™]Ê
BˆXÝ[ÛœË˜[YÛ›Y[H›ÞÛÛZ[™\‹SQÓ“QS•ÑS‘ˆ›Þ˜YØÚ[
XÝ[ÛœÊBˆ˜\ˆ^HHØ]ÛŠh×*5£XžéÝyø§yÔˆ°Y•Ñ½ÈÈ ÄÄÀ°€ÌÐ¤¤(€€€€€€€Ù…ÈÝ½É±‘}¥€èôÍÑÈ¡Ý½É±¹•Ð ‰¥ˆ°€ˆˆ¤¤(€€€€€€€Á±…ä¹ÁÉ•ÍÍ•¹½¹¹•Ð¡™Õ¹Œ ¤è}É•ÍÕµ•}Ý½É±¡Ý½É±‘}¥¤¤(€€€€€€€…Ñ¥½¹Ì¹…‘‘}¡¥±¡Á±…ä¤(€€€€€€€¥˜µ…¹…”è(€€€€€€€€€€€Ù…Èµ•¹Õ}‰ÕÑÑ½¸€èô}‰ÕÑÑ½¸ ˜¸ÖsZ6ˆ‹™XÝÜŒŠÍ
JBˆY[WØ]Û‹œ™\ÜÙY˜ÛÛ›™XÝ
[˜Ê
NˆÝÛÜ›ØXÝ[ÛœÊÛÜ›ÚYÝŠY]K™Ù]
›˜[YH‹•ÛÜ›ŠJJJBˆXÝ[ÛœË˜YØÚ[
Y[WØ]ÛŠB‚™[˜ÈÜYÙWÛ][\^Y\Š
HOˆ›ÚY‚ˆÜÙXÝ[Û—Ý]JÛÛ[ºw^~)ÞuÊhß/"éÝyø§y×D5£\äÖäb"Â.×ŸŠwr£Z5Ñºw^~)ÞwÐhÖJ"éÝyø§yß(ºw^~)Þu&E5£xÄ‹§uçâç]Öä;§uçâçR"¢f"&÷r£Ò„&÷„6öçF–æW"ææWr‚¢&÷ræFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'6W&F–öâ"Â¢6öçFVçBæFEö6†–ÆB‡&÷r¢f"†÷7B£Ò÷V–6µö6&B‡&÷rÂ&†÷7B"Â#Z5Êh×Aºw^~)Þu", &*5£y*éÝyø§yÐ˜°Ör’TæWBZ7ÑhÙ", func(): host_multiplayer.emit())
    host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var join := _quick_card(row, "join", "5£XØÖtR"Â.×ŸŠwtCZ7MhÔ 5£}Ötb.×ŸŠwt£Z5ÌHºw^~)ÞuÎMhÚ", func(): _join_dialog())
    join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var servers := _quick_card(row, "servers", "5£X¸Örû§uçâçR"ÂbsZ5ÐMhÖ)"éÝyø§yÞ'5£\¨ÖtB.×ŸŠwtCZ7‰ÍhÑ", func(): _show_page("servers"))
    servers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _section_title(content, "5£XŒÖô#Z4Hh×.ºw^~)Þt&'5£yÖ’"Â#Z5Èhß1ºw^~)Þv&%5£\€ÖdCZ7ÊhÖ 5£YÖäƒZ7‘ˆºw^~)ÞuÒˆºw^~)ÞuÑhÖ3ºw^~)Þu&'5£|œÖâ’"¢÷&Vg&W6…ög&–VæG2„æWGv÷&´ÖævW"ç&VÖ÷FU÷Æ–W'2 ¦gVæ2÷vU÷6W'fW'2‚’Óâfö–C ¢÷6V7F–öå÷F—FÆR†6öçFVçBÂ.×ŸŠwbsZ5ÊHºw^~)ÞuÑhÞ'5£Tˆ°€ˆÖd#Z5HhÖE5£] Ö’Z5ˆhÖ45£\¤‹§uçâç]ÖôCZ6HhØ 5£X€ÖscZ5Ê®×ŸŠwÉ‰Íh×-5£xâéÝyø§yÔˆ¤(€€€Ù…È…‘€èô}ÁÉ¥µ…Éå}‰ÕÑÑ½¸ ˆÖbsZ6HhÞ15£Dˆ°Y•Ñ½ÈÈ ÄäÀ°€ÐÐ¤¤(€€€…‘¹ÁÉ•ÍÍ•¹½¹¹•Ð¡}…‘‘}Í•ÉÙ•É}‘¥…±½œ¤(€€€½¹Ñ•¹Ð¹…‘‘}¡¥±¡…‘¤(€€€Ù…È™…Ù½É¥Ñ•Ì€èôM•ÉÙ•É¥É•Ñ½Éä¹É••¹Ð ¤(€€€¥˜™…Ù½É¥Ñ•Ì¹¥Í}•µÁÑä ¤è(€€€€€€€Ù…È•µÁÑä€èô}Á…¹•°¡A91|È°€Äà°½±½È À¸ÈÈ°€À¸Ü°€Ä¸À°€À¸ÄÈ¤¤(€€€€€€€½¹Ñ•¹Ð¹…‘‘}¡¥±¡•µÁÑä¤(€€€€€€€}±…‰•°¡•µÁÑä°€‹§uçâçXœ‹§uçâçy ÖòZ7‰ÍhÕ 5£}Öâ’âb3Z4HhÖH5£X€ÖãZ4HhÞ/ºw^~)Þu&'5£\¨ÖtBâ"Â2ÂÕUDTBÂ„õ$•¤ôåDÅôÄ”täÔTåEô4TåDU"¢VÇ6S ¢f÷"6W'fW"–âff÷&—FW3 ¢÷6W'fW%ö6&B‡6W'fW" ¦gVæ2÷6W'fW%ö6&B‡6W'fW#¢F–7F–öæ'’’Óâfö–C ¢f"6&B£Ò÷æVÂ…äTÅó"ÂbÂ6öÆ÷"ƒã#"ÂãrÂãÂãB’¢6&Bæ7W7FöÕöÖ–æ–×VÕ÷6—¦RÒfV7F÷#"ƒÂ“"¢6öçFVçBæFEö6†–ÆB†6&B¢f"&÷r£Ò„&÷„6öçF–æW"ææWr‚¢&÷rç6WEöæ6†÷'5öæEööfg6WG5÷&W6WB„6öçG&öÂå$U4UEôeTÄÅõ$T5B¢&÷ræFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'6W&F–öâ"Â¢6&BæFEö6†–ÆB‡&÷r¢f"–æfò£Òd&÷„6öçF–æW"ææWr‚¢–æfòç6—¦UöfÆw5ö†÷&—¦öçFÂÒ6öçG&öÂå4•¤UôU…äEôd”ÄÀ¢&÷ræFEö6†–ÆB†–æfò¢öÆ&VÂ†–æfòÂ7G"‡6W'fW"ævWB‚&æÖR"Âc3Z5Ðn×ŸŠwHŠJKMKV
Bˆ˜\ˆY™\Ü×ÛX™[HÛX™[
[™›ËÝŠÙ\™\‹™Ù]
˜Y™\ÜÈ‹ˆŠJKLUUQ
BˆY™\Ü×ÛX™[›^[Ý]Ù\™XÝ[ÛˆHÛÛ›Û“VSÕUÑT‘PÕSÓ—Ó‚ˆY™\Ü×ÛX™[šÜš^›Û[Ø[YÛ›Y[HÔ’V“Ó•SÐSQÓ“QS•ÓQ•ˆ˜\ˆÝ]HHÛX™[
[™›Ëh×1ºw^~)Þu&A5£T€ÖbsZ5Éî×ŸŠw‹‹ˆ‹LQSÕÊBˆÜ›Ø™WÜÙ\™\ŠÝŠÙ\™\‹™Ù]
˜Y™\ÜÈ‹ˆŠJKÝ]JBˆ˜\ˆ›Ú[ˆHØ]ÛŠ	‹ÍhÞD", Vector2(100, 38))
    join.pressed.connect(func(): _join_remote(str(server.get("address", ""))))
    row.add_child(join)
    var remove := _button("éÝyø§yß0ºw^~)Þu", Vector2(80, 38))
    remove.pressed.connect(func(): ServerDirectory.remove_favorite(str(server.get("address", ""))); _show_page("servers"))
    row.add_child(remove)

func _page_store() -> void:
    _section_title(content, "5£YÖã"Â.×ŸŠwt#Z5Éî×ŸŠwÉ‘MhÖJ"éÝyø§y×-5£xà‹§uçâç\äÖä»§uçâçrd[§uçâçRdSZ5‘ˆºw^~)ÞuÍh×J5£hˆ¤(€€€Ù…ÈÝ…±±•Ðèõ}Á…¹•°¡A91|È°€Äà°½±½È À¸ÈÈ°€À¸Ü°€Ä¸À°€À¸ÄÐ¤¤ì½¹Ñ•¹Ð¹…‘‘}¡¥±¡Ý…±±•Ð¤(€€€Ù…ÈÝ‰½àèõ!	½á½¹Ñ…¥¹•È¹¹•Ü ¤ìÝ…±±•Ð¹…‘‘}¡¥±¡Ý‰½à¤(€€€Ù…È½¥¹Í}±…‰•°èõ}±…‰•°¡Ý‰½à°€‹§uçâç]Öt«§uçâçs¢VB"RV6öæö×’æ6ö–ç2Â‚Â44TåEô%$”t…B“²6ö–ç5öÆ&VÂç6—¦UöfÆw5ö†÷&—¦öçFÃÔ6öçG&öÂå4•¤UôU…äEôd”ÄÀ¢V6öæö×’çvÆÆWEö6†ævVBæ6öææV7B†gVæ2‡fÇVS¦–çB“¢–b—5ö–ç7Fæ6U÷fÆ–B†6ö–ç5öÆ&VÂ“¢6ö–ç5öÆ&VÂçFW‡CÒ.×ŸŠwtCZ5Ò®×ŸŠwÎˆ	Yˆ	H˜[YJBˆ˜\ˆÜšYQÜšYÛÛZ[™\‹›™]Ê
NÈÜšY˜ÛÛ[[œÏLŽÈÜšY˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJšÜÙ\\˜][Ûˆ‹LŠNÈÜšY˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJ—ÜÙ\\˜][Ûˆ‹LŠNÈÛÛ[˜YØÚ[
ÜšY
Bˆ›ÜˆÙ™™\ˆ[ˆXÛÛ›Û^KœÚÜØØ][ÙÊ
N‚ˆ˜\ˆØ\™WÜ[™[
S‘SÌ‹MÛÛÜŠŒMKŒŒŒŽŽM
JNÈØ\™˜Ý\ÝÛWÛZ[š[][WÜÚ^™OU™XÝÜŒŠŽLL
NÈÜšY˜YØÚ[
Ø\™
Bˆ˜\ˆ›ÞU›ÞÛÛZ[™\‹›™]Ê
NÈ›Þ˜YÝ[YWØÛÛœÝ[ÛÝ™\œšYJœÙ\\˜][Ûˆ‹ŠNÈØ\™˜YØÚ[
›Þ
BˆÛX™[
›ÞÝŠÙ™™\‹™Ù]
›˜[YH‹’][HŠJKM‹V
BˆÛX™[
›Þ‰Y5ÉŠhß1 %d" % [int(offer.get("amount",1)),int(offer.get("price",0))], 11, MUTED)
        var buy:=_primary_button("5£\žéÝyø§yÔˆ°Y•Ñ½ÈÈ ÄÈÀ°ÌØ¤¤(€€€€€€€‰Õä¹ÁÉ•ÍÍ•¹½¹¹•Ð¡™Õ¹Œ¡¥èõ¥¹Ð¡½™™•È¹•Ð ‰¥Ñ•µ}¥ˆ°À¤¤°…µ½Õ¹Ðèõ¥¹Ð¡½™™•È¹•Ð ‰…µ½Õ¹Ðˆ°Ä¤¤°ÁÉ¥”èõ¥¹Ð¡½™™•È¹•Ð ‰ÁÉ¥”ˆ°À¤¤¤è(€€€€€€€€€€€Ù…È½¬èõ½¹½µä¹ÁÕÉ¡…Í”¡¥±…µ½Õ¹Ð±ÁÉ¥”¤(€€€€€€€€€€€}Í¡½Ý}Á…” ‰ÍÑ½É”ˆ¤¥˜¹½Ð½¬•±Í”}Í¡½Ý}Á…” ‰ÍÑ½É”ˆ¤(€€€€€€€€¤(€€€€€€€‰½à¹…‘‘}¡¥±¡‰Õä¤()™Õ¹Œ}Á…•}ÁÉ½™¥±” ¤€´øÙ½¥è(€€€}Í•Ñ¥½¹}Ñ¥Ñ±”¡½¹Ñ•¹Ð°€‹§uçâç]Öd.×ŸŠwtCZ7n×ŸŠwˆ‹	Šh×F5£h€ÖbÓZ5Êºw^~)Þw‰Íh×H5£d€ÖdSZ5ÒhÙ")
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
    _label(info, "éÝyø§y×D5£\žéÝyø§yÐè€•Ìˆ€”€ ™Öô+§uçâçbºw^~)ÞuB.×ŸŠwä£Z5‰î×ŸŠw‰‘Mh×H5£d€ÖôCZ7ÉÈˆYˆ\Ý]Kš\×Ø]][XØ]Y[ÙHºw^~)ÞuËMhÚ"), 11, GREEN if AppState.is_authenticated else MUTED)
    _label(info, "5£XÐÖt«§uçâçS¢W2"Rö6†&7FW%öÆ&VÂ„7FFRæ6†&7FW%ö–B’ÂÂ44TåEô%$”t…B ¢f"æÖUöf–VÆB£ÒÆ–æTVF—BææWr‚¢æÖUöf–VÆBçFW‡BÒ7FFRævWEöF—7Æ•öæÖR‚¢æÖUöf–VÆBçÆ6V†öÆFW%÷FW‡BÒ#Z5ÑHºw^~)ÞuÑh×6"
    name_field.editable = true
    name_field.custom_minimum_size = Vector2(0, 40)
    name_field.layout_direction = Control.LAYOUT_DIRECTION_RTL
    root.add_child(name_field)

    _label(root, "5£xªéÝyø§yÔ˜ÔÖr’.×ŸŠwsZ7‘hÙ", 16, TEXT)
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
        text.text = "éÝyø§y×D5£xÆéÝyø§yÔ€”ÀÉˆ€”m¥¹‘•à€¬€Åt(€€€€€€€Ñ•áÐ¹¡½É¥é½¹Ñ…±}…±¥¹µ•¹Ð€ô!=I%i=9Q1}1%959Q}9QH(€€€€€€€Ñ•áÐ¹±…å½ÕÑ}‘¥É•Ñ¥½¸€ô½¹ÑÉ½°¹1e=UQ}%IQ%=9}IQ0(€€€€€€€Ñ•áÐ¹µ½ÕÍ•}™¥±Ñ•È€ô½¹ÑÉ½°¹5=UM}%1QI}%9=I(€€€€€€€‰ÕÑÑ½¸¹…‘‘}¡¥±¡Ñ•áÐ¤(€€€€€€€‰ÕÑÑ½¸¹ÁÉ•ÍÍ•¹½¹¹•Ð¡™Õ¹Œ¡Í•±•Ñ•‘}¥¹‘•à€èô¥¹‘•à¤è(€€€€€€€€€€€ÁÁMÑ…Ñ”¹…Ù…Ñ…É}¥€ôÍ•±•Ñ•‘}¥¹‘•à(€€€€€€€€€€€™½ÈÁ••È¥¸…Ù…Ñ…É}‰ÕÑÑ½¹Ìè(€€€€€€€€€€€€€€€Á••È¹‰ÕÑÑ½¹}ÁÉ•ÍÍ•€ô™…±Í”(€€€€€€€€€€€‰ÕÑÑ½¸¹‰ÕÑÑ½¹}ÁÉ•ÍÍ•€ôÑÉÕ”(€€€€€€€€€€€ÁÉ•Ù¥•Ü¹…Ù…Ñ…É}¥¹‘•à€ôÍ•±•Ñ•‘}¥¹‘•à(€€€€€€€€€€€ÁÉ•Ù¥•Ü¹ÅÕ•Õ•}É•‘É…Ü ¤(€€€€€€€€¤(€€€€€€€É¥¹…‘‘}¡¥±¡‰ÕÑÑ½¸¤(€€€€€€€…Ù…Ñ…É}‰ÕÑÑ½¹Ì¹…ÁÁ•¹¡‰ÕÑÑ½¸¤((€€€Ù…ÈÍ…Ù”€èô}ÁÉ¥µ…Éå}‰ÕÑÑ½¸ ‹§uçâç}éÝyø§yÐ˜œÖtK§uçâçRbsZ5‹hÚ", Vector2(220, 46))
    save.pressed.connect(func():
        if AppState.is_authenticated:
            var root = get_parent()
            var auth_node = root.get("auth") if root != null else null
            if auth_node != null:
                auth_node.update_profile(AppState.auth_token, name_field.text, AppState.avatar_id)
        else:
            AppState.save_profile(name_field.text, AppState.avatar_id)
        _show_page("profile")
    )
    root.add_child(save)
    
func _page_developer() -> void:
    _section_title(content, "5£} Ö¢Z5‘MhÞ1", "éÝyø§y×B5£y*éÝyø§yÜ˜¨Öä«§uçâçBdZ5’®×ŸŠwIMh×")
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    content.add_child(grid)
    _metric(grid, "FPS", str(Engine.get_frames_per_second()))
    _metric(grid, "5£XÀÖs§uçâçR"Â"Sã&bÔ""R…W&f÷&Öæ6RævWEöÖöæ—F÷"…W&f÷&Öæ6RäÔTÔõ%•õ5DD”2’òCƒSsbã’¢öÖWG&–2†w&–BÂ#Z5ÎMhØ 5£XÐÖr’"Â7G"†×VÇF—Æ–W"ævWE÷VW'2‚’ç6—¦R‚’’¢öÖWG&–2†w&–BÂbsZ7ÒhÖE"éÝyø§y×D5£}Öâ’"Â7G"…6fTD"æÆ—7E÷v÷&ÆG2‚’ç6—¦R‚’’¢öÖWG&–2†w&–BÂc“Z7ÈhÖE5£\¼ˆ°ÍÑÈ¡•Ñ}ÑÉ•” ¤¹•Ñ}¹½‘•}½Õ¹Ð ¤¤¤(€€€}µ•ÑÉ¥Œ¡É¥°€˜œÖr£Z5Ñ‹ºw^~)ÞuÊhÔ" if multiplayer.multiplayer_peer != null else &:5£D€Öã[§uçâçB"¢f"6öç6öÆR£Òö'WGFöâ‚dZ7Hhß/ºw^~)Þu&'5£\ÜÖ„c‚’"ÂfV7F÷#"ƒ#sÂCB’¢6öç6öÆRç&W76VBæ6öææV7B†gVæ2‚“ ¢f"&ö÷B£ÒvWE÷&VçB‚¢–b&ö÷BæB&ö÷Bæ†5öÖWF†öB‚'FövvÆUöFWfVÆ÷W%ö6öç6öÆR"“ ¢&ö÷BçFövvÆUöFWfVÆ÷W%ö6öç6öÆR‚¢¢6öçFVçBæFEö6†–ÆB†6öç6öÆR ¦gVæ2öÖWG&–2‡&VçC¢6öçG&öÂÂF—FÆS¢7G&–ærÂfÇVS¢7G&–ær’Óâfö–C ¢f"6&B£Ò÷æVÂ…äTÅó"ÂBÂ6öÆ÷"ƒã#"ÂãrÂãÂã"’¢6&Bæ7W7FöÕöÖ–æ–×VÕ÷6—¦RÒfV7F÷#"ƒÂ“"¢&VçBæFEö6†–ÆB†6&B¢f"&÷‚£Òd&÷„6öçF–æW"ææWr‚¢&÷‚æÆ–væÖVçBÒ&÷„6öçF–æW"äÄ”täÔTåEô4TåDU ¢6&BæFEö6†–ÆB†&÷‚¢öÆ&VÂ†&÷‚ÂF—FÆRÂÂÕUDTB¢f"fÇVUöÆ&VÂ£ÒöÆ&VÂ†&÷‚ÂfÇVRÂ#BÂ44TåEô%$”t…B¢fÇVUöÆ&VÂææÖRÒ$ÖWG&–5fÇVR  ¦gVæ2÷&Vg&W6…ög&–VæG2‡Æ–W'3¢F–7F–öæ'’’Óâfö–C ¢–bg&–VæG5ö&÷‚ÓÒçVÆÃ ¢&WGW&à¢f÷"6†–ÆB–âg&–VæG5ö&÷‚ævWEö6†–ÆG&Vâ‚“ ¢6†–ÆBçVWVUög&VR‚¢f"fÆ–B£Ò ¢f÷"–B–âÆ–W'3 ¢f"&öf–ÆS¢F–7F–öæ'’ÒÆ–W'5¶–EÐ¢–b&öf–ÆRæ—5öV×G’‚“ ¢6öçF–çVP¢fÆ–B³Ò¢f"&÷r£Ò÷æVÂ…äTÅó"Â"Â6öÆ÷"ƒã#"ÂãrÂãÂã’¢&÷ræ7W7FöÕöÖ–æ–×VÕ÷6—¦RÒfV7F÷#"ƒÂSB¢g&–VæG5ö&÷‚æFEö6†–ÆB‡&÷r¢f"–ææW"£Ò„&÷„6öçF–æW"ææWr‚¢–ææW"ç6WEöæ6†÷'5öæEööfg6WG5÷&W6WB„6öçG&öÂå$U4UEôeTÄÅõ$T5B¢–ææW"æÆ–÷WEöF—&V7F–öâÒ6öçG&öÂäÄ”õUEôD•$T5D”ôåõ%DÀ¢–ææW"æFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'6W&F–öâ"Â‚¢&÷ræFEö6†–ÆB†–ææW"¢f"W'6öåö–6öâÒÆöB‚'&W3¢ò÷67&—G2÷V’÷fV7F÷%ö–6öâævB"’ææWr‚¢W'6öåö–6öâæ–6öåöæÖRÒ'W'6öâ ¢W'6öåö–6öâæ–6öåö6öÆ÷"Òu$TTà¢W'6öåö–6öâæ7W7FöÕöÖ–æ–×VÕ÷6—¦RÒfV7F÷#"ƒ#BÂ#B¢–ææW"æFEö6†–ÆB‡W'6öåö–6öâ¢f"&÷‚£Òd&÷„6öçF–æW"ææWr‚¢&÷‚æÆ–÷WEöF—&V7F–öâÒ6öçG&öÂäÄ”õUEôD•$T5D”ôåõ%DÀ¢&÷‚ç6—¦UöfÆw5ö†÷&—¦öçFÂÒ6öçG&öÂå4•¤UôU…äEôd”ÄÀ¢–ææW"æFEö6†–ÆB†&÷‚¢f"æÖR£Ò7G"‡&öf–ÆRævWB‚&æÖR"Â%Æ–W""’¢öÆ&VÂ†&÷‚ÂæÖRÂ"ÂDU…B¢öÆ&VÂ†&÷‚Â#Z7n×ŸŠw	‹ÍhÞD"éÝyø§y×D5£XÎéÝyø§yÔ€´€•Ìˆ€”}¡…É…Ñ•É}±…‰•°¡ÍÑÈ¡ÁÉ½™¥±”¹•Ð ‰¡…É…Ñ•Èˆ°€‰É…¹•Èˆ¤¤¤°€ä°I8¤(€€€€€€€Ù…ÈÙ¥•Ü€èô}‰ÕÑÑ½¸ ˆÖsb"ÂfV7F÷#"ƒsÂ3’¢f–Wrç&W76VBæ6öææV7B†gVæ2‚“¢÷6†÷uög&–VæE÷&öf–ÆR†æÖRÂ&öf–ÆR’¢–ææW"æFEö6†–ÆB‡f–Wr¢–bfÆ–BÓÒ ¢öÆ&VÂ†g&–VæG5ö&÷‚Â.×ŸŠwbr.×ŸŠwäƒZ7Èh×/5£\„‹§uçâç\¨Öd‹§uçâçbbÓZ5’h×.", 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    var count_label := _find_child_label("FriendCount")
    if count_label:
        count_label.text = "%d 5£xÖéÝyø§yÐˆ€”Ù…±¥(€€€ÍÑ…ÑÕÍ}™É¥•¹‘Ì¹Ñ•áÐ€ô€˜œÖsSZ5‰î×ŸŠwNˆ	Yˆ	H˜[Y‚™[˜ÈÜÚÝ×ÙœšY[™Ü›Ùš[J˜[YNˆÝš[™Ë›Ùš[NˆXÝ[Û˜\žJHOˆ›ÚY‚ˆ˜\ˆX[ÙÈHXØÙ\X[ÙË›™]Ê
BˆX[ÙË]HH	‘MhÑ 5£YÖò‚ ¢F–ÆöræF–Æöu÷FW‡BÒ"W5ÆâsZ5‹hÞ): %s\n5£X´Öb“¢dSZ5Ñºw^~)ÞwÉÍhÔ 5£X°Ör’.×ŸŠwtCZ5ÑhÙ" % [name, _character_label(str(profile.get("character", "ranger")))]
    add_child(dialog)
    dialog.popup_centered(Vector2i(420, 220))

func _refresh_status() -> void:
    if status_connection == null:
        return
    var state := str(NetworkManager.connection_state)
    var online := state in ["connected", "hosting"]
    status_connection.text = "éÝyø§y×D5£xÔÖC¢W2"R‡²&6öææV7FVB#¢.×ŸŠwr£Z5‹šÜÝ[™ÈŽˆºw^~)ÞuÌÍhÖJºw^~)Þu", "connecting":"5£\ÆéÝyø§yÔ˜œÖr£Z5Ñ‹›Ù™›[™HŽ‰ŽhÑ 5£xÖéÝyø§yÐ‰ô¹•Ð¡ÍÑ…Ñ”°ÍÑ…Ñ”¤¤(€€€ÍÑ…ÑÕÍ}½¹¹•Ñ¥½¸¹…‘‘}Ñ¡•µ•}½±½É}½Ù•ÉÉ¥‘” ‰™½¹Ñ}½±½Èˆ°I8¥˜½¹±¥¹”•±Í”€¡e11=\¥˜ÍÑ…Ñ”€ôô€‰½¹¹•Ñ¥¹œˆ•±Í”5UQ¤¤(€€€ÍÑ…ÑÕÍ}Í•ÉÙ•È¹Ñ•áÐ€ô€ˆÖbãZ7ÑN‰‘MhÞ65£Dˆ¥˜9•ÑÝ½É­5…¹…•È¹Í•ÉÙ•É}ÍÑ…ÉÑ••±Í”€‹§uçâç]Örû§uçâçS¢Z5Ò®×ŸŠw‚ˆÝ]\×ÙœË^H‘”Îˆ	Yˆ	H[™Ú[™K™Ù]Ùœ˜[Y\×Ü\—ÜÙXÛÛ™

B‚™[˜ÈÜ›ØÙ\ÜÊÙ[Nˆ›Ø]
HOˆ›ÚY‚ˆYˆÝ]\×ÙœÎ‚ˆÝ]\×ÙœË^H‘”Îˆ	Yˆ	H[™Ú[™K™Ù]Ùœ˜[Y\×Ü\—ÜÙXÛÛ™

BˆYˆÝ\œ™[ÜYÙHOH™]™[Ü\ˆˆ[™ÛÛ[‚ˆ›ÜˆÚ[[ˆÛÛ[™Ù]ØÚ[™[Š
N‚ˆYˆÚ[\ÈÜšYÛÛZ[™\Ž‚ˆÜ™Yœ™\ÚÛY]šX×ÙÜšY
Ú[
B‚™[˜ÈÜ™Yœ™\ÚÛY]šX×ÙÜšY
ÜšYˆÜšYÛÛZ[™\ŠHOˆ›ÚY‚ˆ˜\ˆ˜[Y\ÈHÂˆÝŠ[™Ú[™K™Ù]Ùœ˜[Y\×Ü\—ÜÙXÛÛ™

JKˆ‰LŒ™ˆPˆˆ	H
\™›Ü›X[˜ÙK™Ù]Û[Ûš]ÜŠ\™›Ü›X[˜ÙK“QSSÔ–WÔÕUPÊHÈLMÍ‹Œ
KˆÝŠ][\^Y\‹™Ù]ÜY\œÊ
KœÚ^™J
JKˆÝŠØ]™Q‹›\ÝÝÛÜ›Ê
KœÚ^™J
JKˆÝŠÙ]Ý™YJ
K™Ù]Û›ÙWØÛÝ[

JKˆºw^~)ÞuÊhÔ" if multiplayer.multiplayer_peer != null else &:5£D€Öã[§uçâçB ¢Ð¢f"’£Ò ¢f÷"6&B–âw&–BævWEö6†–ÆG&Vâ‚“ ¢f"Æ&VÇ2£Ò6&Bæf–æEö6†–ÆG&Vâ‚$Æ&VÂ"Â$Æ&VÂ"ÂG'VRÂfÇ6R¢–bÆ&VÇ2ç6—¦R‚’ãÒ"æB’ÂfÇVW2ç6—¦R‚“ ¢Æ&VÇ5³ÒçFW‡BÒfÇVW5¶•Ð¢’³Ò ¦gVæ2÷6V&6‚‡VW'“¢7G&–ær’Óâfö–C ¢ö6Æ÷6U÷6V&6…÷÷W‚¢f"£ÒVW'’ç7G&—öVFvW2‚’çFõöÆ÷vW"‚¢–bæ—5öV×G’‚“ ¢&WGW&à¢6V&6…÷÷WÒ÷æVÂ…äTÂÂbÂ6öÆ÷"ƒã#"ÂãrÂãÂã#"’¢6V&6…÷÷Wæ7W7FöÕöÖ–æ–×VÕ÷6—¦RÒfV7F÷#"ƒS#Â3C¢6V&6…÷÷Wç6WEöæ6†÷'5÷&W6WB„6öçG&öÂå$U4UEõDõõ$”t…B¢6V&6…÷÷Wç÷6—F–öâÒfV7F÷#"‚ÓSCÂ“¢FEö6†–ÆB‡6V&6…÷÷W¢6V&6…÷&W7VÇG2Òd&÷„6öçF–æW"ææWr‚¢6V&6…÷&W7VÇG2æFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'6W&F–öâ"Âr¢6V&6…÷÷WæFEö6†–ÆB‡6V&6…÷&W7VÇG2¢öÆ&VÂ‡6V&6…÷&W7VÇG2Â#Z7‰ÍhÜ 5£X Ö²"ÂrÂDU…B¢f"f÷VæB£Ò ¢f÷"v÷&ÆB–â6fTD"æÆ—7E÷v÷&ÆG2‚“ ¢f"ÖWF¢F–7F–öæ'’Òv÷&ÆBævWB‚&ÖWFFF"Â·Ò¢f"æÖR£Ò7G"†ÖWFævWB‚&æÖR"Â""’