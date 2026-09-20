extends RefCounted

const CHUNK_SIZE := 16
const WORLD_HEIGHT := 96
const SEA_LEVEL := 34
const VERSION := 1

var seed_value: int
var continental := FastNoiseLite.new()
var detail := FastNoiseLite.new()
var caves := FastNoiseLite.new()
var ore := FastNoiseLite.new()
var structures_enabled := true

func _fallback_block_ids() -> Dictionary:
    return {
        "AIR": 0,
        "BEDROCK": 17,
        "WATER": 15,
        "SAND": 3,
        "SNOW": 28,
        "SOIL": 1,
        "COPPER_ORE": 11,
        "IRON_ORE": 12,
        "CRYSTAL_ORE": 13,
        "STONE": 2,
        "LOG": 6,
        "LEAVES": 7
    }

func _block_id(name: String) -> int:
    var fallback := _fallback_block_ids()
    if fallback.has(name):
        return int(fallback.get(name, 0))
    return 0

func _init(world_seed: int) -> void:
    seed_value = world_seed
    continental.seed = seed_value
    continental.frequency = 0.0025
    continental.fractal_octaves = 5
    detail.seed = seed_value ^ 0x4A11C0DE
    detail.frequency = 0.016
    detail.fractal_octaves = 3
    caves.seed = seed_value ^ 0x11C4BEEF
    caves.frequency = 0.028
    caves.fractal_octaves = 2
    ore.seed = seed_value ^ 0x7788AA11
    ore.frequency = 0.07

func configure(enable_structures: bool = true) -> void:
    structures_enabled = enable_structures

func terrain_height(x: int, z: int) -> int:
    var macro := continental.get_noise_2d(x, z)
    var detail_v := detail.get_noise_2d(x, z)
    var h := SEA_LEVEL + int(macro * 22.0 + detail_v * 7.0)
    return clampi(h, 4, WORLD_HEIGHT - 8)

func biome_at(x: int, z: int) -> String:
    var temp := continental.get_noise_2d(x + 10000, z + 10000)
    var moisture := continental.get_noise_2d(x - 16000, z - 16000)
    if temp > 0.45 and moisture < -0.1:
        return "arid"
    if temp < -0.45:
        return "frost"
    if moisture > 0.35:
        return "grove"
    return "meadow"

func block_at(x: int, y: int, z: int) -> int:
    var bedrock_id := _block_id("BEDROCK")
    var air_id := _block_id("AIR")
    var water_id := _block_id("WATER")
    var sand_id := _block_id("SAND")
    var snow_id := _block_id("SNOW")
    var soil_id := _block_id("SOIL")
    if y < 0:
        return bedrock_id
    if y >= WORLD_HEIGHT:
        return air_id
    if y == 0:
        return bedrock_id
    var surface := terrain_height(x, z)
    if _is_cave(x, y, z) and y > 4 and y < surface - 3:
        return air_id
    if y > surface:
        if y <= SEA_LEVEL:
            return water_id
        return _tree_block(x, y, z, surface) if structures_enabled else air_id
    var biome := biome_at(x, z)
    if y == surface:
        if surface <= SEA_LEVEL + 1:
            return sand_id
        if biome == "frost":
            return snow_id
        if biome == "arid":
            return sand_id
        return soil_id
    if y >= surface - 3:
        return sand_id if biome == "arid" else soil_id
    return _subsurface_resource(x, y, z)

func generate_chunk(cx: int, cz: int) -> PackedByteArray:
    var data := PackedByteArray()
    data.resize(CHUNK_SIZE * CHUNK_SIZE * WORLD_HEIGHT)
    var i := 0
    for lx in CHUNK_SIZE:
        for lz in CHUNK_SIZE:
            for y in WORLD_HEIGHT:
                data[i] = block_at(cx * CHUNK_SIZE + lx, y, cz * CHUNK_SIZE + lz)
                i += 1
    return data

func _is_cave(x: int, y: int, z: int) -> bool:
    var n := caves.get_noise_3d(x, y * 1.08, z)
    var vertical := absf(float(y - 42) / 40.0)
    return n > 0.58 and vertical < 0.9

func _subsurface_resource(x: int, y: int, z: int) -> int:
    var copper := _block_id("COPPER_ORE")
    var iron := _block_id("IRON_ORE")
    var crystal := _block_id("CRYSTAL_ORE")
    var stone := _block_id("STONE")
    var n := ore.get_noise_3d(x, y, z)
    if y < 40 and y > 8 and n > 0.71:
        return copper
    if y < 30 and y > 5 and n > 0.79:
        return iron
    if y < 18 and n > 0.88:
        return crystal
    return stone

func _tree_block(x: int, y: int, z: int, surface: int) -> int:
    var air_id := _block_id("AIR")
    var log_id := _block_id("LOG")
    var leaves_id := _block_id("LEAVES")
    var trunk_key := posmod(hash(Vector3i(x, surface, z)), 97)
    if trunk_key != 0 and trunk_key > 4:
        return air_id
    var top := surface + 4 + posmod(x * 13 + z * 7, 3)
    if y > surface and y <= top and x % 2 == 0 and z % 2 == 0:
        return log_id
    if y >= top - 2 and y <= top + 1:
        return leaves_id
    return air_id
