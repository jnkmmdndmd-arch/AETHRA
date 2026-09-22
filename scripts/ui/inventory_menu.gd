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
    var title:=Label.new(); title.text="المخزون والتصنيع"; title.add_theme_font_size_override("font_size",24); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(title)
    var close:=Button.new(); close.text="إغلاق"; close.pressed.connect(func(): visible=false; Input.mouse_mode=Input.MOUSE_MODE_CAPTURED); header.add_child(close)
    var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",16); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(columns)
    slots_box=GridContainer.new(); slots_box.columns=6; slots_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; columns.add_child(slots_box)
    recipe_box=VBoxContainer.new(); recipe_box.custom_minimum_size=Vector2(280,0); columns.add_child(recipe_box)
    var rt:=Label.new(); rt.text="وصفات 3×3"; rt.add_theme_font_size_override("font_size",18); recipe_box.add_child(rt)
    status_label=Label.new(); status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; recipe_box.add_child(status_label)
    creative_box=VBoxContainer.new(); creative_box.add_theme_constant_override("separation", 6); recipe_box.add_child(creative_box)
    _build_slots(); _build_recipes(); _build_creative_palette(); refresh()

func _build_slots()->void:
    for child in slots_box.get_children(): child.queue_free()
    for i in inventory.SLOTS:
        var b := Button.new()
        b.custom_minimum_size = Vector2(108, 68)
        b.pressed.connect(func(index: int = i) -> void: inventory.select_slot(index); refresh())
        slots_box.add_child(b)

func _build_creative_palette()->void:
    for child in creative_box.get_children(): child.queue_free()
    if AppState.game_mode != "creative":
        return
    var title:=Label.new(); title.text="لوحة الإبداع"; title.add_theme_font_size_override("font_size",18); creative_box.add_child(title)
    var grid:=GridContainer.new(); grid.columns=3; creative_box.add_child(grid)
    for item_id in range(1,BlockRegistry.LAST_BLOCK+1):
        if item_id in [BlockRegistry.WATER,BlockRegistry.LAVA,BlockRegistry.BEDROCK]: continue
        var block:=BlockRegistry.get_block(item_id)
        var button := Button.new()
        button.text = str(block.get("name", "Block"))
        button.custom_minimum_size = Vector2(90, 34)
        button.icon = MinecraftCompat.get_block_icon(item_id)
        button.tooltip_text = "Minecraft 1.17.1 • " + str(block.get("name", "Block"))
        button.pressed.connect(func(id: int = item_id) -> void: inventory.add_item(id, inventory._stack_size_for(id)); refresh())
        grid.add_child(button)
    for item_id in ItemRegistry.MINECRAFT_ITEM_IDS + [ItemRegistry.HEAL_FOOD,ItemRegistry.WOOD_PICK,ItemRegistry.STONE_PICK,ItemRegistry.IRON_PICK,ItemRegistry.WOOD_AXE,ItemRegistry.STONE_AXE,ItemRegistry.IRON_AXE,ItemRegistry.WOOD_SWORD,ItemRegistry.STONE_SWORD,ItemRegistry.IRON_SWORD,ItemRegistry.AETHER_SWORD,ItemRegistry.BOW,ItemRegistry.ARROW]:
        var item:=ItemRegistry.get_item(item_id)
        var button := Button.new()
        button.text = str(item.get("name", "Item"))
        button.custom_minimum_size = Vector2(90, 34)
        button.icon = MinecraftCompat.get_item_icon(item_id)
        button.tooltip_text = "AETHRA"
        button.pressed.connect(func(id: int = item_id) -> void: inventory.add_item(id, inventory._stack_size_for(id)); refresh())
        grid.add_child(button)

func _build_recipes()->void:
    for child in recipe_box.get_children():
        if child is Button: child.queue_free()
    for recipe in RecipeRegistry.recipes:
        var b := Button.new()
        b.text = str(recipe.id)
        b.custom_minimum_size = Vector2(250, 40)
        b.pressed.connect(func(recipe_id: String = str(recipe.id)) -> void: _craft(recipe_id))
        recipe_box.add_child(b)

func _craft(recipe_id:String)->void:
    var ok:bool=crafting.craft(inventory,recipe_id); status_label.text="تم التصنيع" if ok else "المواد أو السعة غير كافية"; refresh()

func refresh()->void:
    if inventory==null or slots_box==null: return
    for i in mini(inventory.slots.size(), slots_box.get_child_count()):
        var b := slots_box.get_child(i) as Button
        var s: Dictionary = inventory.slots[i]
        var id: int = int(s.get("item", 0))
        var count: int = int(s.get("count", 0))
        var name: String = "فارغ"
        b.icon = null
        if id != 0 and count > 0:
            name = str(ItemRegistry.get_item(id).get("name", "Item"))
            if id > 0 and id <= BlockRegistry.LAST_BLOCK and str(ItemRegistry.get_item(id).get("category", "none")) == "none":
                name = str(BlockRegistry.get_block(id).get("name", "Block"))
                b.icon = MinecraftCompat.get_block_icon(id)
            else:
                b.icon = MinecraftCompat.get_item_icon(id)
        b.text = "%d\n%s x%d" % [i + 1, name, count]
        b.button_pressed = i == inventory.selected

func _process(_delta:float)->void:
    if visible: refresh()