extends Node

const SOURCE_VERSION := "Minecraft Java 1.17.1"
const BLOCK_ATLAS_PATH := "res://assets/minecraft/atlas/minecraft_blocks_1_17_1.webp.b64"
const ENTITY_ATLAS_PATH := "res://assets/minecraft/atlas/minecraft_entities_1_17_1.webp.b64"
const ITEM_ATLAS_PATH := "res://assets/minecraft/atlas/minecraft_items_1_17_1.webp.b64"

const BLOCK_COLUMNS := 8
const BLOCK_ROWS := 8
const ENTITY_COLUMNS := 8
const ENTITY_ROWS := 4
const ITEM_COLUMNS := 8
const ITEM_ROWS := 9

var BLOCK_TEXTURES: PackedStringArray = PackedStringArray([
    "air","dirt","stone","sand","gravel","clay","oak_log","oak_leaves","oak_planks","glass",
    "lantern","copper_ore","iron_ore","amethyst_block","bricks","water_still","lava_still","bedrock",
    "crafting_table_side","furnace_side","chest","oak_door_top","torch","redstone_block","redstone_torch",
    "piston_side","observer_front","hopper_outside","snow","sandstone","red_sand","red_sandstone","cactus_side",
    "dead_bush","acacia_log","acacia_leaves","jungle_log","jungle_leaves","dandelion","cornflower","red_mushroom",
    "vine","ice","packed_ice","obsidian","basalt_side","deepslate","poppy","sweet_berry_bush_stage3",
    "lily_pad","grass_block_side","snow","coal_ore","gold_ore","emerald_ore","diamond_ore","glowstone",
    "cut_sandstone","moss_block","amethyst_block","cobblestone","mossy_cobblestone","stone_bricks","netherrack","nether_bricks"
])

var ENTITY_TEXTURES: PackedStringArray = PackedStringArray([
    "cow/cow","pig","sheep/sheep","chicken","horse/horse_brown","wolf/wolf","cat/tabby","fox/fox",
    "goat/goat","bee/bee","creeper/creeper","zombie/zombie","skeleton/skeleton","enderman/enderman","slime/slime",
    "witch","iron_golem/iron_golem","guardian","blaze","ghast/ghast","endermite","silverfish","piglin/piglin","hoglin/hoglin",
    "axolotl/axolotl_wild","bat","spider","villager/villager","zombie_villager/zombie_villager","ravager","wither/wither","phantom"
])

var ITEM_TEXTURES: PackedStringArray = PackedStringArray([
    "apple","bread","carrot","potato","baked_potato","beetroot","melon_slice","pumpkin_pie",
    "cookie","cake","beef","cooked_beef","chicken","cooked_chicken","porkchop","cooked_porkchop",
    "mutton","cooked_mutton","rabbit","cooked_rabbit","cod","cooked_cod","salmon","cooked_salmon",
    "coal","charcoal","iron_ingot","gold_ingot","diamond","emerald","copper_ingot","quartz",
    "amethyst_shard","stick","string","feather","leather","flint","bone","arrow","bucket","water_bucket",
    "lava_bucket","shears","fishing_rod","flint_and_steel","compass_00","clock_00","map","empty_armor_slot_shield",
    "bow","crossbow_standby","wooden_pickaxe","stone_pickaxe","iron_pickaxe","diamond_pickaxe","netherite_pickaxe",
    "wooden_axe","stone_axe","iron_axe","diamond_axe","wooden_shovel","stone_shovel","iron_shovel","wooden_sword",
    "stone_sword","iron_sword"
])

const ENTITY_TILE_BY_TYPE := {
    "goat": 8, "wolf": 5, "fox": 7, "rabbit": 3, "horse": 4, "chicken": 3, "camel": 4,
    "vulture": 25, "fennec": 7, "lizard": 24, "snake": 24, "scorpion": 26, "bee": 9,
    "butterfly": 9, "dragonfly": 25, "firefly": 9, "beetle": 21, "moth": 9, "spider": 26,
    "slime": 14, "wraith": 13, "brute": 29, "drake": 31, "sand_wyrm": 19, "stone_golem": 16,
    "marsh_lurker": 17, "bat": 25, "crystal_mite": 20,
    "cow": 0, "pig": 1, "sheep": 2, "creeper": 10, "zombie": 11, "skeleton": 12,
    "enderman": 13, "witch": 15, "iron_golem": 16, "guardian": 17, "blaze": 18, "ghast": 19,
    "endermite": 20, "silverfish": 21, "piglin": 22, "hoglin": 23, "axolotl": 24, "villager": 27,
    "zombie_villager": 28, "ravager": 29, "wither": 30, "phantom": 31, "cat": 6
}

var _block_atlas: Texture2D = null
var _entity_atlas: Texture2D = null
var _item_atlas: Texture2D = null
var _item_icon_cache: Dictionary = {}
var _entity_material_cache: Dictionary = {}

func _ready() -> void:
    _block_atlas = _load_b64_texture(BLOCK_ATLAS_PATH)
    _entity_atlas = _load_b64_texture(ENTITY_ATLAS_PATH)
    _item_atlas = _load_b64_texture(ITEM_ATLAS_PATH)

func _load_b64_texture(path: String) -> Texture2D:
    if not FileAccess.file_exists(path):
        push_warning("Minecraft compatibility asset missing: " + path)
        return null
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("Unable to open Minecraft compatibility asset: " + path)
        return null
    var encoded := file.get_as_text().replace("\n", "").replace("\r", "").strip_edges()
    file.close()
    if encoded.is_empty():
        return null
    var raw: PackedByteArray = Marshalls.base64_to_raw(encoded)
    if raw.is_empty():
        push_warning("Minecraft compatibility asset decoded to empty data: " + path)
        return null
    var image := Image.new()
    var error: Error = image.load_webp_from_buffer(raw)
    if error != OK:
        push_warning("Minecraft compatibility asset failed to decode, using generated compatibility fallback: " + path)
        return _build_fallback_texture(path)
    image.generate_mipmaps()
    return ImageTexture.create_from_image(image)

func _build_fallback_texture(path: String) -> Texture2D:
    var width := 128
    var height := 128
    if "entities" in path:
        width = ENTITY_COLUMNS * 64
        height = ENTITY_ROWS * 64
    elif "items" in path:
        width = ITEM_COLUMNS * 16
        height = ITEM_ROWS * 16
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    image.fill(Color(0.02, 0.02, 0.03, 1.0))
    if "blocks" in path:
        for tile in BLOCK_TEXTURES.size():
            var color := Color(0.25, 0.25, 0.25, 1.0)
            var registry_info = BlockRegistry.get_block(tile)
            color = registry_info.get("color", color)
            var tx := (tile % BLOCK_COLUMNS) * 16
            var ty := (tile / BLOCK_COLUMNS) * 16
            for y in 16:
                for x in 16:
                    var shade := 0.88 + float((x + y + tile) % 4) * 0.04
                    image.set_pixel(tx + x, ty + y, Color(color.r * shade, color.g * shade, color.b * shade, 1.0))
    elif "items" in path:
        for tile in ITEM_TEXTURES.size():
            var tx := (tile % ITEM_COLUMNS) * 16
            var ty := (tile / ITEM_COLUMNS) * 16
            var hue := float(tile % 12) / 12.0
            var color := Color.from_hsv(hue, 0.55, 0.92, 1.0)
            image.fill_rect(Rect2i(tx + 2, ty + 2, 12, 12), color)
    else:
        for tile in ENTITY_TEXTURES.size():
            var tx := (tile % ENTITY_COLUMNS) * 64
            var ty := (tile / ENTITY_COLUMNS) * 64
            var hue := float(tile % 16) / 16.0
            var color := Color.from_hsv(hue, 0.45, 0.82, 1.0)
            image.fill_rect(Rect2i(tx + 8, ty + 8, 48, 48), color)
    image.generate_mipmaps()
    return ImageTexture.create_from_image(image)

func get_atlas() -> Texture2D:
    if _block_atlas == null:
        _block_atlas = _load_b64_texture(BLOCK_ATLAS_PATH)
    return _block_atlas

func get_entity_atlas() -> Texture2D:
    if _entity_atlas == null:
        _entity_atlas = _load_b64_texture(ENTITY_ATLAS_PATH)
    return _entity_atlas

func get_item_atlas() -> Texture2D:
    if _item_atlas == null:
        _item_atlas = _load_b64_texture(ITEM_ATLAS_PATH)
    return _item_atlas

func get_block_tile(block_id: int) -> int:
    return clampi(block_id, 0, BLOCK_TEXTURES.size() - 1)

func get_entity_tile(creature_type: String) -> int:
    var key := creature_type.to_lower()
    return clampi(int(ENTITY_TILE_BY_TYPE.get(key, 0)), 0, ENTITY_TEXTURES.size() - 1)

func get_item_tile(item_id: int) -> int:
    if item_id >= ItemRegistry.MC_APPLE and item_id <= ItemRegistry.MC_CROSSBOW:
        return clampi(item_id - ItemRegistry.MC_APPLE, 0, ITEM_TEXTURES.size() - 1)
    var mapping := {
        ItemRegistry.HEAL_FOOD: 0,
        ItemRegistry.WOOD_PICK: 52, ItemRegistry.STONE_PICK: 53, ItemRegistry.IRON_PICK: 54,
        ItemRegistry.WOOD_AXE: 57, ItemRegistry.STONE_AXE: 58, ItemRegistry.IRON_AXE: 59,
        ItemRegistry.WOOD_SHOVEL: 61, ItemRegistry.STONE_SHOVEL: 62, ItemRegistry.IRON_SHOVEL: 63,
        ItemRegistry.WOOD_SWORD: 64, ItemRegistry.STONE_SWORD: 65, ItemRegistry.IRON_SWORD: 66,
        ItemRegistry.AETHER_SWORD: 28, ItemRegistry.BOW: 50, ItemRegistry.ARROW: 39,
        ItemRegistry.SHEARS: 43, ItemRegistry.BUCKET: 40, ItemRegistry.LANTERN: 22,
        ItemRegistry.ROPE: 34, ItemRegistry.HAMMER: 37, ItemRegistry.HOE: 61,
        ItemRegistry.COMPASS: 46, ItemRegistry.MAP: 48
    }
    return clampi(int(mapping.get(item_id, 0)), 0, ITEM_TEXTURES.size() - 1)

func get_item_icon(item_id: int) -> Texture2D:
    var cache_key := str(item_id)
    if _item_icon_cache.has(cache_key):
        return _item_icon_cache[cache_key]
    var atlas := get_item_atlas()
    if atlas == null:
        return null
    var texture := AtlasTexture.new()
    texture.atlas = atlas
    var tile := get_item_tile(item_id)
    var x := tile % ITEM_COLUMNS
    var y := tile / ITEM_COLUMNS
    texture.region = Rect2(x * 16, y * 16, 16, 16)
    _item_icon_cache[cache_key] = texture
    return texture

func get_block_icon(block_id: int) -> Texture2D:
    var atlas := get_atlas()
    if atlas == null:
        return null
    var texture := AtlasTexture.new()
    texture.atlas = atlas
    var tile := get_block_tile(block_id)
    texture.region = Rect2((tile % BLOCK_COLUMNS) * 16, (tile / BLOCK_COLUMNS) * 16, 16, 16)
    return texture

func get_entity_material(creature_type: String) -> Material:
    var key := creature_type.to_lower()
    if _entity_material_cache.has(key):
        return _entity_material_cache[key]
    var atlas := get_entity_atlas()
    if atlas == null:
        return null
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D atlas_texture : source_color, filter_nearest;
uniform float tile_index = 0.0;
void fragment() {
    vec2 tile = vec2(mod(tile_index, 8.0), floor(tile_index / 8.0));
    vec2 atlas_uv = (tile + fract(UV)) / vec2(8.0, 4.0);
    vec4 tex = texture(atlas_texture, atlas_uv);
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
    ROUGHNESS = 0.90;
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("atlas_texture", atlas)
    material.set_shader_parameter("tile_index", float(get_entity_tile(key)))
    _entity_material_cache[key] = material
    return material

func source_manifest() -> Dictionary:
    return {
        "source": SOURCE_VERSION,
        "blocks": BLOCK_TEXTURES.duplicate(),
        "items": ITEM_TEXTURES.duplicate(),
        "entities": ENTITY_TEXTURES.duplicate()
    }
