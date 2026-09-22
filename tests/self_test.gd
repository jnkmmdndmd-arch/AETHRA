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
    var console_script: GDScript = load("res://scripts/tools/dev_console.gd") as GDScript
    checks.append(_check("Developer console parser", func() -> bool:
        return console_script != null
    ))

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
    checks.append(_check("World height presets", func() -> bool:
        for value in [500,800,1000]:
            var g: RefCounted = load("res://scripts/world/world_generator.gd").new(99)
            g.configure(true, "", value)
            if g.world_height!=value or g.block_at(0,value,0)!=BlockRegistry.AIR:
                return false
        return true
    ))
    checks.append(_check("Inventory UI resource", func() -> bool:
        return load("res://scripts/ui/inventory_menu.gd") != null and FileAccess.file_exists("res://scripts/ui/inventory_menu.gd")
    ))
    checks.append(_check("Economy validation", func() -> bool:
        return Economy.can_spend(0) and not Economy.can_spend(Economy.coins + 1)
    ))
    checks.append(_check("Minecraft 1.17.1 compatibility", func() -> bool:
        var manifest: Dictionary = MinecraftCompat.source_manifest()
        var blocks: Array = manifest.get("blocks", [])
        return MinecraftCompat.SOURCE_VERSION == "Minecraft Java 1.17.1" and blocks.size() == 64 and str(blocks[2]) == "stone"
    ))
    checks.append(_check("Expanded crafting recipes", func() -> bool:
        return not recipe_registry.find_recipe("iron_sword").is_empty() and not recipe_registry.find_recipe("chest").is_empty()
    ))
    checks.append(_check("Minecraft atlases", func() -> bool:
        return MinecraftCompat.get_atlas() != null and MinecraftCompat.get_entity_atlas() != null and MinecraftCompat.get_item_atlas() != null
    ))
    checks.append(_check("Minecraft item catalog", func() -> bool:
        return ItemRegistry.MINECRAFT_ITEM_IDS.size() == 44 and ItemRegistry.get_item(ItemRegistry.MC_DIAMOND).get("name", "") == "Diamond"
    ))
    checks.append(_check("Minecraft crafting content", func() -> bool:
        return (not recipe_registry.find_recipe("minecraft_bow").is_empty() and not recipe_registry.find_recipe("minecraft_shield").is_empty() and not recipe_registry.find_recipe("minecraft_arrow").is_empty())
    ))
    checks.append(_check("Minecraft texture mapping", func() -> bool:
        return (MinecraftCompat.get_block_tile(BlockRegistry.STONE) == 2 and MinecraftCompat.get_item_tile(ItemRegistry.MC_DIAMOND) == 28 and MinecraftCompat.get_entity_tile("creeper") == 10)
    ))
    for result in checks:
        print("[TEST] %s: %s" % [result[0], "PASS" if result[1] else "FAIL"])
    if checks.any(func(x): return not bool(x[1])):
        quit(1)
    quit(0)

func _check(name: String, fn: Callable) -> Array:
    return [name, bool(fn.call())]