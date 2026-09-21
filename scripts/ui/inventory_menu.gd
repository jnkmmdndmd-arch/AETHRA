extends Control

var inventory
var crafting
var panel:PanelContainer
var slots_box:GridContainer
var recipe_box:VBoxContainer
var status_label:Label
var creative_box:VBoxContainer

func build(parent:Node, inventory_ref, crafting_ref)->void:
    inventory=inventory_ref; crafting=crafting_ref
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layout_direction=Control.LAYOUT_DIRECTION_RTL; mouse_filter=Control.MOUSE_FILTER_STOP
    panel=PanelContainer.new(); panel.set_anchors_preset(Control.PRESET_CENTER); panel.position=Vector2(-420,-280); panel.size=Vector2(840,560)
    var style:=StyleBoxFlat.new(); style.bg_color=Color(0.02,0.04,0.08,0.97); style.corner_radius_top_left=18; style.corner_radius_top_right=18; style.corner_radius_bottom_left=18; style.corner_radius_bottom_right=18; style.border_width_left=1; style.border_width_right=1; style.border_width_top=1; style.border_width_bottom=1; style.border_color=Color(0.3,0.75,1.0,0.32); panel.add_theme_stylebox_override("panel",style); add_child(panel)
    var margin:=MarginContainer.new(); margin.add_theme_constant_override("margin_left",18); margin.add_theme_constant_override("margin_top",18); margin.add_theme_constant_override("margin_right",18); margin.add_theme_constant_override("margin_bottom",18); panel.add_child(margin)
    var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",10); margin.add_child(root)
    var header:=HBoxContainer.new(); header.layout_direction=Control.LAYOUT_DIRECTION_RTL; root.add_child(header)
    var title:=Label.new(); title.text=&'5£\¸Öäb.×ŸŠwâsZ7MhŞ9"; title.add_theme_font_size_override("font_size",24); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(title)
    var close:=Button.new(); close.text="5£yÖ"#²6Æ÷6Rç&W76VBæ6öææV7B†gVæ2‚“¢f—6–&ÆSÖfÇ6S²–çWBæÖ÷W6UöÖöFSÔ–çWBäÔõU4UôÔôDUô4EU$TB“²†VFW"æFEö6†–ÆB†6Æ÷6R¢f"6öÇVÖç3£Ô„&÷„6öçF–æW"ææWr‚“²6öÇVÖç2æFE÷F†VÖUö6öç7FçEö÷fW'&–FR‚'6W&F–öâ"Ãb“²6öÇVÖç2ç6—¦UöfÆw5÷fW'F–6ÃÔ6öçG&öÂå4•¤UôU…äEôd”ÄÃ²&ö÷BæFEö6†–ÆB†6öÇVÖç2¢6Æ÷G5ö&÷ƒÔw&–D6öçF–æW"ææWr‚“²6Æ÷G5ö&÷‚æ6öÇVÖç3Óc²6Æ÷G5ö&÷‚ç6—¦UöfÆw5ö†÷&—¦öçFÃÔ6öçG&öÂå4•¤UôU…äEôd”ÄÃ²6öÇVÖç2æFEö6†–ÆB‡6Æ÷G5ö&÷‚¢&V6—Uö&÷ƒÕd&÷„6öçF–æW"ææWr‚“²&V6—Uö&÷‚æ7W7FöÕöÖ–æ–×VÕ÷6—¦SÕfV7F÷#"ƒ#ƒÃ“²6öÇVÖç2æFEö6†–ÆB‡&V6—Uö&÷‚¢f"'C£ÔÆ&VÂææWr‚“²'BçFW‡CÒ#Z5ĞMhÚ 3×3"; rt.add_theme_font_size_override("font_size",18); recipe_box.add_child(rt)
    status_label=Label.new(); status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; recipe_box.add_child(status_label)
    creative_box=VBoxContainer.new(); creative_box.add_theme_constant_override("separation", 6); recipe_box.add_child(creative_box)
    _build_slots(); _build_recipes(); _build_creative_palette(); refresh()

func _build_slots()->void:
    for child in slots_box.get_children(): child.queue_free()
    for i in inventory.SLOTS:
        var b:=Button.new(); b.custom_minimum_size=Vector2(108,68); b.pressed.connect(func(index=i): inventory.select_slot(index); refresh()); slots_box.add_child(b)

func _build_creative_palette()->void:
    for child in creative_box.get_children(): child.queue_free()
    if AppState.game_mode != "creative":
        return
    var title:=Label.new(); title.text="5£x¶éİyø§yÔ˜œÖrƒZ5ÎHÈ]K˜Yİ[YWÙ›ÛÜÚ^™WÛİ™\œšYJ™›ÛÜÚ^™H‹N
NÈÜ™X]]™WØ›Ş˜YØÚ[
]JBˆ˜\ˆÜšYQÜšYÛÛZ[™\‹›™]Ê
NÈÜšY˜ÛÛ[[œÏLÎÈÜ™X]]™WØ›Ş˜YØÚ[
ÜšY
Bˆ›Üˆ][WÚY[ˆ˜[™ÙJK›ØÚÔ™YÚ\İK“TÕĞ“ĞÒÊÌJN‚ˆYˆ][WÚY[ˆĞ›ØÚÔ™YÚ\İK•ĞUT‹›ØÚÔ™YÚ\İK“UK›ØÚÔ™YÚ\İK‘Q“ĞÒ×NˆÛÛ[YBˆ˜\ˆ›ØÚÎP›ØÚÔ™YÚ\İK™Ù]Ø›ØÚÊ][WÚY
Bˆ˜\ˆ]ÛP]Û‹›™]Ê
NÈ]Û‹^\İŠ›ØÚË™Ù]
›˜[YH‹›ØÚÈŠJNÈ]Û‹˜İ\İÛWÛZ[š[][WÜÚ^™OU™XİÜŒŠLÍ
Bˆ]Û‹œ™\ÜÙY˜ÛÛ›™Xİ
[˜ÊYZ][WÚY
Nˆ[™[ÜK˜YÚ][JY[™[ÜK—ÜİXÚ×ÜÚ^™WÙ›ÜŠY
JNÈ™Yœ™\Ú

JBˆÜšY˜YØÚ[
]ÛŠBˆ›Üˆ][WÚY[ˆÒ][T™YÚ\İK’PSÑ“ÓÑ][T™YÚ\İK•ÓÓÑÔPÒË][T™YÚ\İK”ÕÓ‘WÔPÒË][T™YÚ\İK’T“Ó—ÔPÒË][T™YÚ\İK•ÓÓÑĞVK][T™YÚ\İK”ÕÓ‘WĞVK][T™YÚ\İK’T“Ó—ĞVK][T™YÚ\İK•ÓÓÑÔÕÓÔ‘][T™YÚ\İK”ÕÓ‘WÔÕÓÔ‘][T™YÚ\İK’T“Ó—ÔÕÓÔ‘][T™YÚ\İKQUT—ÔÕÓÔ‘][T™YÚ\İK“ÕË][T™YÚ\İKT”“Õ×N‚ˆ˜\ˆ][NR][T™YÚ\İK™Ù]Ú][J][WÚY
Bˆ˜\ˆ]ÛP]Û‹›™]Ê
NÈ]Û‹^\İŠ][K™Ù]
›˜[YH‹’][HŠJNÈ]Û‹˜İ\İÛWÛZ[š[][WÜÚ^™OU™XİÜŒŠLÍ
Bˆ]Û‹œ™\ÜÙY˜ÛÛ›™Xİ
[˜ÊYZ][WÚY
Nˆ[™[ÜK˜YÚ][JY[™[ÜK—ÜİXÚ×ÜÚ^™WÙ›ÜŠY
JNÈ™Yœ™\Ú

JBˆÜšY˜YØÚ[
]ÛŠB‚™[˜ÈØZ[Ü™XÚ\\Ê
KO›ÚY‚ˆ›ÜˆÚ[[ˆ™XÚ\WØ›Ş™Ù]ØÚ[™[Š
N‚ˆYˆÚ[\È]ÛˆÚ[œ]Y]YWÙœ™YJ
Bˆ›Üˆ™XÚ\H[ˆ™XÚ\T™YÚ\İKœ™XÚ\\Î‚ˆ˜\ˆP]Û‹›™]Ê
NÈ‹^\İŠ™XÚ\KšY
NÈ‹˜İ\İÛWÛZ[š[][WÜÚ^™OU™XİÜŒŠL
NÈ‹œ™\ÜÙY˜ÛÛ›™Xİ
[˜Ê™XÚ\WÚY\İŠ™XÚ\KšY
JNˆØÜ˜Y
™XÚ\WÚY
JNÈ™XÚ\WØ›Ş˜YØÚ[
ŠB‚™[˜ÈØÜ˜Y
™XÚ\WÚY”İš[™ÊKO›ÚY‚ˆ˜\ˆÚÎ˜›ÛÛXÜ˜Y[™Ë˜Ü˜Y
[™[ÜK™XÚ\WÚY
NÈİ]\×ÛX™[^IŠ®×ŸŠwI‰ÍhŞ55£xäˆ¥˜½¬•±Í”€˜œÖtƒZ7ÈhØ 5£XÌÖ’Z7ŒHºw^~)ŞuÉÍhŞ)"; refresh()

func refresh()->void:
    if inventory==null or slots_box==null: return
    for i in mini(inventory.slots.size(),slots_box.get_child_count()):
        var b:=slots_box.get_child(i) as Button; var s:Dictionary=inventory.slots[i]; var id:=int(s.get("item",0)); var count:=int(s.get("count",0)); var name: String="éİyø§y×'5£hˆ(€€€€€€€¥˜¥„ôÀ…¹½Õ¹ĞøÀè(€€€€€€€€€€€¹…µ”õÍÑÈ¡%Ñ•µI•¥ÍÑÉä¹•Ñ}¥Ñ•´¡¥¤¹•Ğ ‰¹…µ”ˆ°‰%Ñ•´ˆ¤¤(€€€€€€€€€€€¥˜¥øÀ…¹¥ğõ	±½­I•¥ÍÑÉä¹1MQ}	1=,…¹ÍÑÈ¡%Ñ•µI•¥ÍÑÉä¹•Ñ}¥Ñ•´¡¥¤¹•Ğ ‰…Ñ•½Éäˆ°‰¹½¹”ˆ¤¤ôô‰¹½¹”ˆè¹…µ”õÍÑÈ¡	±½­I•¥ÍÑÉä¹•Ñ}‰±½¬¡¥¤¹•Ğ ‰¹…µ”ˆ°‰	±½¬ˆ¤¤(€€€€€€€ˆ¹Ñ•áĞôˆ•‘q¸•Ìà•ˆ€”m¤¬Ä±¹…µ”±½Õ¹Ñtìˆ¹‰ÕÑÑ½¹}ÁÉ•ÍÍ•õ¤ôõ¥¹Ù•¹Ñ½Éä¹Í•±•Ñ•()™Õ¹Œ}ÁÉ½•ÍÌ¡}‘•±Ñ„é™±½…Ğ¤´ùÙ½¥è(€€€¥˜Ù¥Í¥‰±”èÉ•™É•Í  ¤