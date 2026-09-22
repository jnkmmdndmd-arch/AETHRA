extends RefCounted

const CHUNK_SIZE := 16
const DEFAULT_WORLD_HEIGHT := 96
const MIN_WORLD_HEIGHT := 64
const MAX_WORLD_HEIGHT := 256
const SEA_LEVEL_RATIO := 0.35
const VERSION := 1
const AIR_ID := 0
const SOIL_ID := 1
const STONE_ID := 2
const SAND_ID := 3
const COPPER_ORE_ID := 11
const IRON_ORE_ID := 12
const CRYSTAL_ORE_ID := 13
const LOG_ID := 6
const LEAVES_ID := 7
const WATER_ID := 15
const BEDROCK_ID := 17
const SNOW_ID := 28
const SANDSTONE_ID := 29
const CACTUS_ID := 32
const DRY_GRASS_ID := 33
const ACACIA_LOG_ID := 34
const ACACIA_LEAVES_ID := 35
const PALM_LOG_ID := 36
const PALM_LEAVES_ID := 37
const YELLOW_FLOWER_ID := 38
const BLUE_FLOWER_ID := 39
const MUSHROOM_ID := 40
const VINE_ID := 41
const ICE_ID := 42
const COAL_ORE_ID := 52
const GOLD_ORE_ID := 53
const EMERALD_ORE_ID := 54
const DIAMOND_ORE_ID := 55
const OBSIDIAN_ID := 44
const BASALT_ID := 45
const CRYSTAL_BLOCK_ID := 59

var seed_value: int
var continental: FastNoiseLite
var detail: FastNoiseLite
var caves: FastNoiseLite
var ore: FastNoiseLite
var structures_enabled := true
var forced_biome := ""
var world_height := DEFAULT_WORLD_HEIGHT
var sea_level := 34

func _init(world_seed: int) -> void:
    seed_value = world_seed
    continental = FastNoiseLite.new()
    detail = FastNoiseLite.new()
    caves = FastNoiseLite.new()
    ore = FastNoiseLite.new()
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

func configure(enable_structures: bool = true, biome_override: String = "", height_value: int = DEFAULT_WORLD_HEIGHT) -> void:
    structures_enabled = enable_structures
    forced_biome = biome_override.to_lower()
    world_height = clampi(height_value, MIN_WORLD_HEIGHT, MAX_WORLD_HEIGHT)
    sea_level = maxi(16, int(world_height * SEA_LEVEL_RATIO))

func terrain_height(x: int, z: int) -> int:
    var macro: float = continental.get_noise_2d(x, z)
    var detail_v: float = detail.get_noise_2d(x, z)
    var h: int = SEA_LEVEL + int(macro * 22.0 + detail_v * 7.0)
    return clampi(h, 4, world_height - 8)

func biome_at(x: int, z: int) -> String:
    if forced_biome in ["arid", "frost", "grove", "meadow"]:
        return forced_biome
    var temp: float = continental.get_noise_2d(x + 10000, z + 10000)
    var moisture: float = continental.get_noise_2d(x - 16000, z - 16000)
    if temp > 0.45 and moisture < -0.1:
        return "arid"
    if temp < -0.45:
        return "frost"
    if moisture > 0.35:
        return "grove"
    return "meadow"

func block_at(x: int, y: int, z: int) -> int:
    if y < 0:
        return BEDROCK_ID
    if y >= world_height:
        return AIR_ID
    if y == 0:
        return BEDROCK_ID

    var surface: int = terrain_height(x, z)
    if y < surface - 3 and y > 4 and _is_cave(x, y, z):
        return AIR_ID

    if y > surface:
        if y <= SEA_LEVEL:
            return WATER_ID
        return _tree_block(x, y, z, surface) if structures_enabled else AIR_ID

    var biome: String = biome_at(x, z)
    if y == surface:
        if surface <= SEA_LEVEL + 1:
            return SAND_ID
        if biome == "frost":
            return SNOW_ID
        if biome == "arid":
            return SAND_ID
        return SOIL_ID
    if y >= surface - 3:
        return SANDSTONE_ID if biome == "arid" and y < surface - 1 else SAND_ID if biome == "arid" else SOIL_ID
    return _subsurface_resource(x, y, z)

func generate_chunk(cx: int, cz: int) -> PackedByteArray:
    var data := PackedByteArray()
    data.resize(CHUNK_SIZE * CHUNK_SIZE * world_height)
    var i := 0
    var base_x := cx * CHUNK_SIZE
    var base_z := cz * CHUNK_SIZE

    for lx in CHUNK_SIZE:
        var wx := base_x + lx
        for lz in CHUNK_SIZE:
            var wz := base_z + lz
            var surface: int = terrain_height(wx, wz)
            var biome: String = biome_at(wx, wz)
            var tree_key := posmod(hash(Vector3i(wx, surface, wz)), 97)
            var has_tree := structures_enabled and tree_key <= 4
            var tree_top := surface + 4 + posmod(wx * 13 + wz * 7, 3)

            for y in world_height:
                var id: int
                if y == 0:
                    id = BEDROCK_ID
                elif y > surface:
                    if y <= SEA_LEVEL:
                        id = WATER_ID
                    else:
                        id = _tree_block(wx, y, wz, surface) if structures_enabled else AIR_ID
                elif y < surface - 3 and y > 4 and _is_cave(wx, y, wz):
                    id = AIR_ID
                elif y == surface:
                    if surface <= SEA_LEVEL + 1:
                        id = SAND_ID
                    elif biome == "frost":
                        id = SNOW_ID
                    elif biome == "arid":
                        id = SAND_ID
                    else:
                        id = SOIL_ID
                elif y >= surface - 3:
                    id = SAND_ID if biome == "arid" else SOIL_ID
                else:
                    id = _subsurface_resource(wx, y, wz)
                data[i] = id
                i += 1
    return data

func _is_cave(x: int, y: int, z: int) -> bool:
    var n: float = caves.get_noise_3d(x, y * 1.08, z)
    var vertical := absf(float(y - 42) / 40.0)
    return n > 0.58 and vertical < 0.9

func _subsurface_resource(x: int, y: int, z: int) -> int:
    var n: float = ore.get_noise_3d(x, y, z)
    if y < 48 and y > 8 and n > 0.68:
        return COAL_ORE_ID
    if y < 40 and y > 8 and n > 0.72:
        return COPPER_ORE_ID
    if y < 34 and y > 6 and n > 0.78:
        return IRON_ORE_ID
    if y < 28 and y > 6 and n > 0.84:
        return GOLD_ORE_ID
    if y < 24 and y > 5 and n > 0.88:
        return EMERALD_ORE_ID
    if y < 18 and n > 0.91:
        return DIAMOND_ORE_ID
    if y < 14 and n > 0.88:
        return CRYSTAL_BLOCK_ID
    if y < 10 and n > 0.92:
        return OBSIDIAN_ID
    return BASALT_ID if y < 12 and n > 0.55 else STONE_ID

func _tree_block(x: int, y: int, z: int, surface: int) -> int:
    var tree_key := posmod(hash(Vector3i(x, surface, z)), 97)
    var biome := biome_at(x, z)

    if biome == "arid":
        if tree_key <= 1:
            var cactus_height := 3 + posmod(abs(x * 7 + z * 11), 2)
            if y > surface and y <= surface + cactus_height:
                return CACTUS_ID
        if tree_key >= 2 and tree_key <= 3:
            var palm_top := surface + 5
            if y > surface and y <= palm_top and x % 2 == 0 and z % 2 == 0:
                return PALM_LOG_ID
            if y >= palm_top - 2 and y <= palm_top + 1:
                return PALM_LEAVES_ID
        if y == surface + 1 and tree_key == 4:
            return DRY_GRASS_ID
        return AIR_ID

    if tree_key > 4:
        if biome == "meadow" and y == surface + 1:
            var plant_key := posmod(hash(Vector3i(x, surface + 101, z)), 19)
            if plant_key == 0:
                return YELLOW_FLOWER_ID
            if plant_key == 1:
                return BLUE_FLOWER_ID
        if biome == "grove" and y == surface + 1:
            var grove_key := posmod(hash(Vector3i(x, surface + 203, z)), 23)
            if grove_key == 0:
                return MUSHROOM_ID
            if grove_key == 1:
                return VINE_ID
        if biome == "frost" and y == surface + 1 and tree_key == 5:
            return ICE_ID
        return AIR_ID

    var top := surface + 4 + posmod(x * 13 + z * 7, 3)
    if y > surface and y <= top and x % 2 == 0 and z % 2 == 0:
        return ACACIA_LOG_ID if biome == "meadow" and tree_key <= 2 else LOG_ID
    if y >= top - 2 and y <= top + 1:
        return ACACIA_LEAVES_ID if biome == "meadow" and tree_key <= 2 else LEAVES_ID
    return AIR_ID
