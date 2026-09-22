extends Node

const EMPTY := 0
const HAND := 900
const WOOD_PICK := 100
const STONE_PICK := 101
const IRON_PICK := 102
const WOOD_AXE := 110
const STONE_AXE := 111
const IRON_AXE := 112
const WOOD_SHOVEL := 120
const STONE_SHOVEL := 121
const IRON_SHOVEL := 122
const HEAL_FOOD := 200
const WOOD_SWORD := 130
const STONE_SWORD := 131
const IRON_SWORD := 132
const AETHER_SWORD := 133
const BOW := 140
const ARROW := 141
const SHEARS := 142
const BUCKET := 143
const LANTERN := 144
const ROPE := 145
const HAMMER := 146
const HOE := 147
const COMPASS := 148
const MAP := 149

const MC_APPLE := 150
const MC_BREAD := 151
const MC_CARROT := 152
const MC_POTATO := 153
const MC_BAKED_POTATO := 154
const MC_BEETROOT := 155
const MC_MELON_SLICE := 156
const MC_PUMPKIN_PIE := 157
const MC_COOKIE := 158
const MC_CAKE := 159
const MC_BEEF := 160
const MC_COOKED_BEEF := 161
const MC_CHICKEN := 162
const MC_COOKED_CHICKEN := 163
const MC_PORKCHOP := 164
const MC_COOKED_PORKCHOP := 165
const MC_MUTTON := 166
const MC_COOKED_MUTTON := 167
const MC_RABBIT := 168
const MC_COOKED_RABBIT := 169
const MC_COD := 170
const MC_COOKED_COD := 171
const MC_SALMON := 172
const MC_COOKED_SALMON := 173
const MC_COAL := 174
const MC_CHARCOAL := 175
const MC_IRON_INGOT := 176
const MC_GOLD_INGOT := 177
const MC_DIAMOND := 178
const MC_EMERALD := 179
const MC_COPPER_INGOT := 180
const MC_QUARTZ := 181
const MC_AMETHYST_SHARD := 182
const MC_STICK := 183
const MC_STRING := 184
const MC_FEATHER := 185
const MC_LEATHER := 186
const MC_FLINT := 187
const MC_BONE := 188
const MC_SHIELD := 189
const MC_FISHING_ROD := 190
const MC_FLINT_STEEL := 191
const MC_CLOCK := 192
const MC_CROSSBOW := 193

const MINECRAFT_ITEM_IDS: Array[int] = [
    MC_APPLE, MC_BREAD, MC_CARROT, MC_POTATO, MC_BAKED_POTATO, MC_BEETROOT, MC_MELON_SLICE,
    MC_PUMPKIN_PIE, MC_COOKIE, MC_CAKE, MC_BEEF, MC_COOKED_BEEF, MC_CHICKEN, MC_COOKED_CHICKEN,
    MC_PORKCHOP, MC_COOKED_PORKCHOP, MC_MUTTON, MC_COOKED_MUTTON, MC_RABBIT, MC_COOKED_RABBIT,
    MC_COD, MC_COOKED_COD, MC_SALMON, MC_COOKED_SALMON, MC_COAL, MC_CHARCOAL, MC_IRON_INGOT,
    MC_GOLD_INGOT, MC_DIAMOND, MC_EMERALD, MC_COPPER_INGOT, MC_QUARTZ, MC_AMETHYST_SHARD,
    MC_STICK, MC_STRING, MC_FEATHER, MC_LEATHER, MC_FLINT, MC_BONE, MC_SHIELD, MC_FISHING_ROD,
    MC_FLINT_STEEL, MC_CLOCK, MC_CROSSBOW
]

var items: Dictionary = {}

func _init() -> void:
    _register_defaults()

func _ready() -> void:
    _register_defaults()

func _register_defaults() -> void:
    register(EMPTY, "Empty", "none", 1, 0, 0)
    register(HAND, "Hand", "tool", 1, 1, 0)
    register(WOOD_PICK, "Timber Pick", "tool", 1, 2, 120)
    register(STONE_PICK, "Stone Pick", "tool", 1, 3, 220)
    register(IRON_PICK, "Iron Pick", "tool", 1, 4, 420)
    register(WOOD_AXE, "Timber Axe", "tool", 1, 2, 120)
    register(STONE_AXE, "Stone Axe", "tool", 1, 3, 220)
    register(IRON_AXE, "Iron Axe", "tool", 1, 4, 420)
    register(WOOD_SHOVEL, "Timber Shovel", "tool", 1, 2, 120)
    register(STONE_SHOVEL, "Stone Shovel", "tool", 1, 3, 220)
    register(IRON_SHOVEL, "Iron Shovel", "tool", 1, 4, 420)
    register(HEAL_FOOD, "Sun Fruit", "food", 16, 0, 0)
    register(WOOD_SWORD, "Timber Sword", "weapon", 1, 3, 120)
    register(STONE_SWORD, "Stone Sword", "weapon", 1, 4, 220)
    register(IRON_SWORD, "Iron Sword", "weapon", 1, 5, 420)
    register(AETHER_SWORD, "Aether Sword", "weapon", 1, 7, 720)
    register(BOW, "Hunter Bow", "weapon", 1, 4, 240)
    register(ARROW, "Arrow", "ammo", 64, 1, 0)
    register(SHEARS, "Shears", "tool", 1, 2, 180)
    register(BUCKET, "Water Vessel", "utility", 1, 0, 0)
    register(LANTERN, "Lantern", "utility", 16, 0, 0)
    register(ROPE, "Rope", "utility", 16, 0, 0)
    register(HAMMER, "Stone Hammer", "tool", 1, 3, 180)
    register(HOE, "Field Hoe", "tool", 1, 2, 160)
    register(COMPASS, "Compass", "utility", 1, 0, 0)
    register(MAP, "Explorer Map", "utility", 1, 0, 0)

    register(MC_APPLE, "Minecraft Apple", "food", 64, 0, 0)
    register(MC_BREAD, "Bread", "food", 64, 0, 0)
    register(MC_CARROT, "Carrot", "food", 64, 0, 0)
    register(MC_POTATO, "Potato", "food", 64, 0, 0)
    register(MC_BAKED_POTATO, "Baked Potato", "food", 64, 0, 0)
    register(MC_BEETROOT, "Beetroot", "food", 64, 0, 0)
    register(MC_MELON_SLICE, "Melon Slice", "food", 64, 0, 0)
    register(MC_PUMPKIN_PIE, "Pumpkin Pie", "food", 64, 0, 0)
    register(MC_COOKIE, "Cookie", "food", 64, 0, 0)
    register(MC_CAKE, "Cake", "food", 1, 0, 0)
    register(MC_BEEF, "Raw Beef", "food", 64, 0, 0)
    register(MC_COOKED_BEEF, "Steak", "food", 64, 0, 0)
    register(MC_CHICKEN, "Raw Chicken", "food", 64, 0, 0)
    register(MC_COOKED_CHICKEN, "Cooked Chicken", "food", 64, 0, 0)
    register(MC_PORKCHOP, "Raw Porkchop", "food", 64, 0, 0)
    register(MC_COOKED_PORKCHOP, "Cooked Porkchop", "food", 64, 0, 0)
    register(MC_MUTTON, "Raw Mutton", "food", 64, 0, 0)
    register(MC_COOKED_MUTTON, "Cooked Mutton", "food", 64, 0, 0)
    register(MC_RABBIT, "Raw Rabbit", "food", 64, 0, 0)
    register(MC_COOKED_RABBIT, "Cooked Rabbit", "food", 64, 0, 0)
    register(MC_COD, "Raw Cod", "food", 64, 0, 0)
    register(MC_COOKED_COD, "Cooked Cod", "food", 64, 0, 0)
    register(MC_SALMON, "Raw Salmon", "food", 64, 0, 0)
    register(MC_COOKED_SALMON, "Cooked Salmon", "food", 64, 0, 0)
    register(MC_COAL, "Coal", "resource", 64, 0, 0)
    register(MC_CHARCOAL, "Charcoal", "resource", 64, 0, 0)
    register(MC_IRON_INGOT, "Iron Ingot", "resource", 64, 0, 0)
    register(MC_GOLD_INGOT, "Gold Ingot", "resource", 64, 0, 0)
    register(MC_DIAMOND, "Diamond", "resource", 64, 0, 0)
    register(MC_EMERALD, "Emerald", "resource", 64, 0, 0)
    register(MC_COPPER_INGOT, "Copper Ingot", "resource", 64, 0, 0)
    register(MC_QUARTZ, "Quartz", "resource", 64, 0, 0)
    register(MC_AMETHYST_SHARD, "Amethyst Shard", "resource", 64, 0, 0)
    register(MC_STICK, "Stick", "material", 64, 0, 0)
    register(MC_STRING, "String", "material", 64, 0, 0)
    register(MC_FEATHER, "Feather", "material", 64, 0, 0)
    register(MC_LEATHER, "Leather", "material", 64, 0, 0)
    register(MC_FLINT, "Flint", "material", 64, 0, 0)
    register(MC_BONE, "Bone", "material", 64, 0, 0)
    register(MC_SHIELD, "Shield", "utility", 1, 2, 336)
    register(MC_FISHING_ROD, "Fishing Rod", "utility", 1, 1, 64)
    register(MC_FLINT_STEEL, "Flint and Steel", "utility", 1, 1, 64)
    register(MC_CLOCK, "Clock", "utility", 1, 0, 0)
    register(MC_CROSSBOW, "Crossbow", "weapon", 1, 5, 326)

func register(id: int, item_name: String, category: String, stack_size: int, power: int, durability: int) -> void:
    items[id] = {"id": id, "name": item_name, "category": category, "stack": stack_size, "power": power, "durability": durability}

func get_item(id: int) -> Dictionary:
    if items.is_empty():
        _register_defaults()
    return items.get(id, items.get(EMPTY, {}))
