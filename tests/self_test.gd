extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[TEST] Initializing registries")
    var block_registry = load("res://scripts/data/block_registry.gd").new()
    var item_registry = load("res://scripts/data/item_registry.gd").new()
    var recipe_registry = load("res://scripts/data/recipe_registry.gd").new()
    var checks: Array = []
    checks.append(_check("Block registry", func() -> bool:
        return str(block_registry.get_block(block_registry.STONE).get("name", "")) == "Stone"
    ))
    checks.append(_check("Item registry", func() -> bool:
        return int(item_registry.get_item(item_registry.IRON_PICK).get("durability", 0)) > 0
    ))
    checks.append(_check("Recipes", func() -> bool:
        return not recipe_registry.find_recipe("wood_pick").is_empty()
    ))
    print("[TEST] Initializing world generators")
    var generator = load("res://scripts/world/world_generator.gd").new(1234)
    var matching_generator = load("res://scripts/world/world_generator.gd").new(1234)
    var different_generator = load("res://scripts/world/world_generator.gd").new(5678)
    checks.append(_check("Deterministic terrain", func() -> bool:
        for point in [Vector3i(14, 32, -9), Vector3i(-31, 18, 44), Vector3i(80, 51, -27)]:
            if generator.block_at(point.x, point.y, point.z) != matching_generator.block_at(point.x, point.y, point.z):
                return false
        return true
    ))
    checks.append(_check("Seed variation", func() -> bool:
        if generator.terrain_height(14, -9) != different_generator.terrain_height(14, -9):
            return true
        for point in [Vector3i(14, 32, -9), Vector3i(-31, 18, 44), Vector3i(80, 51, -27)]:
            if generator.block_at(point.x, point.y, point.z) != different_generator.block_at(point.x, point.y, point.z):
                return true
        return false
    ))
    checks.append(_check("World bounds", func() -> bool:
        return generator.block_at(0, 0, 0) == 17 and generator.block_at(0, 100, 0) == 0
    ))
    var voxel_script: GDScript = load("res://scripts/world/voxel_world.gd") as GDScript
    checks.append(_check("Voxel world parser", func() -> bool:
        return voxel_script != null
    ))
    var entry_world = voxel_script.new()
    add_child(entry_world)
    if entry_world.has_method("configure"):
        entry_world.configure({"world_height": 96, "render_distance": 2, "structures": false, "creatures": false, "weather": false})
    entry_world.initialize(1234)
    var test_player_script: GDScript = load("res://scripts/player/player_avatar.gd") as GDScript
    var entry_player = test_player_script.new()
    add_child(entry_player)
    entry_player.setup(entry_world, true, 1)
    checks.append(_check("World entry player/camera", func() -> bool:
        return entry_player.camera != null and entry_player.camera.current and entry_player.player_model != null
    ))
    var test_hud_script: GDScript = load("res://scripts/ui/hud.gd") as GDScript
    var entry_hud = test_hud_script.new()
    add_child(entry_hud)
    entry_hud.build()
    entry_hud.set_inventory(entry_player.inventory)
    checks.append(_check("Gameplay HUD construction", func() -> bool:
        return entry_hud.crosshair != null and entry_hud.hotbar != null and entry_hud.fps_badge != null
    ))
    entry_hud.queue_free()
    entry_player.queue_free()
    entry_world.queue_free()
    checks.append(_check("UI icon policy", func() -> bool:
        var banned := ["♟", "⌂", "▶", "▣", "◇", "◆", "⚙", "↪", "●", "◉", "□", "×"]
        for path in ["res://scripts/ui/main_menu.gd", "res://scripts/ui/hud.gd", "res://scripts/ui/settings_menu.gd"]:
            var text := FileAccess.get_file_as_string(path)
            for glyph in banned:
                if glyph in text:
                    return false
        return FileAccess.file_exists("res://scripts/ui/vector_icon.gd")
    ))
    print("[TEST] Initializing gameplay systems")
    var survival = load("res://scripts/gameplay/survival.gd").new()
    survival.apply_damage(3)
    checks.append(_check("Survival damage", func() -> bool:
        return survival.health == 17.0
    ))
    var inventory = load("res://scripts/gameplay/inventory.gd").new()
    checks.append(_check("Inventory validation", func() -> bool:
        return inventory.add_item(BlockRegistry.WATER, 1) == 0 and inventory.add_item(BlockRegistry.STONE, -1) == 0 and inventory.count_item(BlockRegistry.WATER) == 0
    ))
    inventory.add_item(BlockRegistry.LOG, 2)
    checks.append(_check("Crafting transaction", func() -> bool:
        var crafting = load("res://scripts/gameplay/crafting.gd").new()
        var crafted: bool = crafting.craft(inventory, "wood_pick")
        return not crafted and inventory.count_item(BlockRegistry.LOG) == 2
    ))
    for result in checks:
        print("[TEST] %s: %s" % [result[0], "PASS" if result[1] else "FAIL"])
    if checks.any(func(x): return not bool(x[1])):
        quit(1)
    quit(0)

func _check(name: String, fn: Callable) -> Array:
    return [name, bool(fn.call())]
