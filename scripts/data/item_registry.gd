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

func register(id: int, item_name: String, category: String, stack_size: int, power: int, durability: int) -> void:
    items[id] = {"id": id, "name": item_name, "category": category, "stack": stack_size, "power": power, "durability": durability}

func get_item(id: int) -> Dictionary:
    if items.is_empty():
        _register_defaults()
    return items.get(id, items.get(EMPTY, {}))
