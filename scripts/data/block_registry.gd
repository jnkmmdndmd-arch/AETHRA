extends Node

const AIR := 0
const SOIL := 1
const STONE := 2
const SAND := 3
const GRAVEL := 4
const CLAY := 5
const LOG := 6
const LEAVES := 7
const PLANK := 8
const GLASS := 9
const LAMP := 10
const COPPER_ORE := 11
const IRON_ORE := 12
const CRYSTAL_ORE := 13
const BRICK := 14
const WATER := 15
const LAVA := 16
const BEDROCK := 17
const CRAFTING := 18
const FURNACE := 19
const CHEST := 20
const DOOR := 21
const TORCH := 22
const REDSTONE := 23
const REDSTONE_TORCH := 24
const PISTON := 25
const OBSERVER := 26
const HOPPER := 27
const SNOW := 28

var blocks: Dictionary = {}

func _init() -> void:
    _register_defaults()

func _ready() -> void:
    _register_defaults()

func _register_defaults() -> void:
    register(AIR, "Air", "none", Color(0,0,0,0), -1.0, 0.0, 0, true, 1.0, "")
    register(SOIL, "Soil", "natural", Color("#6a4c3a"), 0.5, 0.0, 0, false, 1.0, "shovel")
    register(STONE, "Stone", "natural", Color("#6c7480"), 1.5, 6.0, 0, false, 0.9, "pickaxe")
    register(SAND, "Sand", "natural", Color("#d6bd78"), 0.5, 0.0, 0, false, 0.9, "shovel")
    register(GRAVEL, "Gravel", "natural", Color("#8b8580"), 0.6, 0.5, 0, false, 0.9, "shovel")
    register(CLAY, "Clay", "natural", Color("#8f9da1"), 0.6, 0.5, 0, false, 0.85, "shovel")
    register(LOG, "Timber", "building", Color("#7c5334"), 2.0, 2.0, 0, false, 0.8, "axe")
    register(LEAVES, "Foliage", "natural", Color("#3b7a4d"), 0.2, 0.2, 0, true, 0.8, "shears")
    register(PLANK, "Plank", "building", Color("#b7834f"), 2.0, 3.0, 0, false, 0.9, "axe")
    register(GLASS, "Glass", "building", Color("#8fd7df", 0.55), 0.3, 0.3, 0, true, 1.0, "")
    register(LAMP, "Glow Lamp", "functional", Color("#f7c75d"), 0.3, 0.3, 13, false, 1.0, "pickaxe")
    register(COPPER_ORE, "Copper Ore", "resource", Color("#b56b4c"), 3.0, 6.0, 0, false, 0.8, "pickaxe")
    register(IRON_ORE, "Iron Ore", "resource", Color("#d4a082"), 3.0, 6.0, 0, false, 0.8, "pickaxe")
    register(CRYSTAL_ORE, "Aether Crystal", "resource", Color("#9f8cff"), 4.5, 10.0, 6, false, 0.75, "pickaxe")
    register(BRICK, "Brick", "building", Color("#9c534e"), 2.0, 6.0, 0, false, 0.9, "pickaxe")
    register(WATER, "Water", "fluid", Color("#3e8ee6", 0.55), 100.0, 100.0, 0, true, 1.0, "")
    register(LAVA, "Lava", "fluid", Color("#ff6a24", 0.75), 100.0, 100.0, 15, true, 1.0, "")
    register(BEDROCK, "Bedrock", "natural", Color("#2d3137"), -1.0, 3600000.0, 0, false, 1.0, "")
    register(CRAFTING, "Workbench", "functional", Color("#825b3d"), 2.5, 3.5, 0, false, 0.8, "axe")
    register(FURNACE, "Kiln", "functional", Color("#555c65"), 3.5, 17.5, 0, false, 0.75, "pickaxe")
    register(CHEST, "Storage Crate", "functional", Color("#9a6a38"), 2.5, 2.5, 0, false, 0.8, "axe")
    register(DOOR, "Door", "functional", Color("#a87548"), 3.0, 3.0, 0, false, 0.8, "axe")
    register(TORCH, "Torch", "functional", Color("#ffb657"), 0.0, 0.0, 14, true, 1.0, "")
    register(REDSTONE, "Signal Dust", "mechanism", Color("#b83f47"), 0.5, 0.5, 0, false, 1.0, "pickaxe")
    register(REDSTONE_TORCH, "Signal Torch", "mechanism", Color("#e24e61"), 0.0, 0.0, 8, true, 1.0, "")
    register(PISTON, "Piston", "mechanism", Color("#7d8b92"), 1.5, 5.0, 0, false, 0.8, "pickaxe")
    register(OBSERVER, "Observer", "mechanism", Color("#525c63"), 3.0, 6.0, 0, false, 0.75, "pickaxe")
    register(HOPPER, "Hopper", "mechanism", Color("#444b52"), 3.0, 6.0, 0, false, 0.75, "pickaxe")
    register(SNOW, "Snow", "natural", Color("#e8f3ff"), 0.2, 0.2, 0, true, 1.0, "shovel")

func register(id: int, display_name: String, category: String, color: Color, hardness: float, resistance: float, light_level: int, transparent: bool, friction: float, tool: String) -> void:
    blocks[id] = {
        "id": id, "name": display_name, "category": category, "color": color,
        "hardness": hardness, "resistance": resistance, "light": light_level,
        "transparent": transparent, "friction": friction, "tool": tool,
        "solid": not transparent and id not in [WATER, LAVA],
        "flammable": id in [LOG, LEAVES, PLANK],
    }

func get_block(id: int) -> Dictionary:
    if blocks.is_empty():
        _register_defaults()
    return blocks.get(id, blocks.get(AIR, {}))

func is_solid(id: int) -> bool:
    return bool(get_block(id).get("solid", false))

func get_drop(id: int) -> int:
    return id
