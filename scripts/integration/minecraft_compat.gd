extends Node

const SOURCE_VERSION := "Minecraft Java 1.17.1"
const ATLAS_COLUMNS := 8
const ATLAS_ROWS := 8
const SOURCE_TEXTURES: PackedStringArray = PackedStringArray(["air","dirt","stone","sand","gravel","clay","oak_log","oak_leaves","oak_planks","glass","lantern","copper_ore","iron_ore","amethyst_block","bricks","water_still","lava_still","bedrock","crafting_table_side","furnace_side","oak_planks","oak_door_top","torch","redstone_block","redstone_torch","piston_side","observer_front","hopper_outside","snow","sandstone","red_sand","red_sandstone","cactus_side","dead_bush","acacia_log","acacia_leaves","jungle_log","jungle_leaves","dandelion","cornflower","red_mushroom","vine","ice","packed_ice","obsidian","basalt_side","deepslate","poppy","sweet_berry_bush_stage3","lily_pad","grass","snow","coal_ore","gold_ore","emerald_ore","diamond_ore","glowstone","cut_sandstone","moss_block","amethyst_block"])
const SOURCE_PALETTE: PackedColorArray = PackedColorArray([
    Color("#000000"),Color("#000000"),Color("#000000"),
    Color("#896142"),Color("#79553a"),Color("#876042"),
    Color("#747474"),Color("#797979"),Color("#878787"),
    Color("#ded4a8"),Color("#d3bf90"),Color("#d7c99c"),
    Color("#908c8a"),Color("#817f7f"),Color("#817f7f"),
    Color("#9da5b2"),Color("#a1a7b1"),Color("#acaebd"),
    Color("#695230"),Color("#785d36"),Color("#554328"),
    Color("#5c5e5c"),Color("#000000"),Color("#343234"),
    Color("#836a3c"),Color("#836a3c"),Color("#a78450"),
    Color("#94a8ac"),Color("#808080"),Color("#a8b5b4"),
    Color("#000000"),Color("#000000"),Color("#825640"),
    Color("#7f7f7f"),Color("#797979"),Color("#797979"),
    Color("#747474"),Color("#8f8f8f"),Color("#ab9789"),
    Color("#7858b5"),Color("#6b4aa7"),Color("#7858b5"),
    Color("#936255"),Color("#a27568"),Color("#a27568"),
    Color("#cccccc"),Color("#e9e9e9"),Color("#a9a9a9"),
    Color("#d66118"),Color("#d2510e"),Color("#d3540d"),
    Color("#333333"),Color("#4b4b4b"),Color("#636363"),
    Color("#40321c"),Color("#5d4d2d"),Color("#a78450"),
    Color("#6a6969"),Color("#a5a5a5"),Color("#717070"),
    Color("#836a3c"),Color("#836a3c"),Color("#a78450"),
    Color("#86693c"),Color("#4b3a20"),Color("#4b3a20"),
    Color("#000000"),Color("#7f7f4b"),Color("#000000"),
    Color("#c51c08"),Color("#730c00"),Color("#b01c08"),
    Color("#000000"),Color("#7f7f4b"),Color("#000000"),
    Color("#877c6c"),Color("#535151"),Color("#817462"),
    Color("#363636"),Color("#959595"),Color("#565656"),
    Color("#545353"),Color("#444345"),Color("#515050"),
    Color("#ffffff"),Color("#f7fefe"),Color("#f7fefe"),
    Color("#cdb983"),Color("#d6c996"),Color("#ded6a9"),
    Color("#c26a25"),Color("#af5b18"),Color("#b86320"),
    Color("#a85715"),Color("#b8611b"),Color("#c56b23"),
    Color("#293e13"),Color("#5b8a2c"),Color("#4e7825"),
    Color("#000000"),Color("#946428"),Color("#000000"),
    Color("#625b53"),Color("#6b645a"),Color("#59544b"),
    Color("#7a7878"),Color("#9e9e9e"),Color("#4f4f4f"),
    Color("#483a14"),Color("#544219"),Color("#59461a"),
    Color("#000000"),Color("#fee144"),Color("#000000"),
    Color("#ffffff"),Color("#96b491"),Color("#ffffff"),
    Color("#000000"),Color("#7f1515"),Color("#000000"),
    Color("#2a2a2a"),Color("#000000"),Color("#6b6b6b"),
    Color("#89b0fd"),Color("#99befe"),Color("#8cb3fd"),
    Color("#7ca5f4"),Color("#92b9fe"),Color("#85adf8"),
    Color("#0b0713"),Color("#0b0713"),Color("#08060e"),
    Color("#3a3b48"),Color("#555355"),Color("#353840"),
    Color("#505053"),Color("#656565"),Color("#47474a"),
    Color("#000000"),Color("#3a1101"),Color("#000000"),
    Color("#340f10"),Color("#484030"),Color("#340f10"),
    Color("#2e2e2e"),Color("#a3a3a3"),Color("#2e2e2e"),
    Color("#000000"),Color("#000000"),Color("#000000"),
    Color("#ffffff"),Color("#f7fefe"),Color("#f7fefe"),
    Color("#747474"),Color("#757575"),Color("#797979"),
    Color("#af8841"),Color("#909090"),Color("#7f7f7f"),
    Color("#747474"),Color("#4ba261"),Color("#3f7d4b"),
    Color("#878787"),Color("#58a1a4"),Color("#7f7f7f"),
    Color("#6f4522"),Color("#b99f80"),Color("#e3b064"),
    Color("#ded4a8"),Color("#dad2a3"),Color("#e3deb7"),
    Color("#687932"),Color("#6a8230"),Color("#42552d"),
    Color("#7858b5"),Color("#6b4aa7"),Color("#7858b5")
])

var _atlas: Texture2D = null

func _ready() -> void:
    _atlas = _build_atlas()

func get_atlas() -> Texture2D:
    if _atlas == null:
        _atlas = _build_atlas()
    return _atlas

func source_texture_path(block_id: int) -> String:
    var idx := clampi(block_id, 0, SOURCE_TEXTURES.size() - 1)
    return "assets/minecraft/textures/block/" + SOURCE_TEXTURES[idx] + ".png"

func source_manifest() -> Dictionary:
    var out: Dictionary = {}
    for i in SOURCE_TEXTURES.size():
        out[i] = {"source": SOURCE_TEXTURES[i], "path": source_texture_path(i), "tile": i}
    return out

func _build_atlas() -> Texture2D:
    var image := Image.create(ATLAS_COLUMNS * 16, ATLAS_ROWS * 16, false, Image.FORMAT_RGBA8)
    for block_id in 60:
        var base := block_id * 3
        var tx := (block_id % ATLAS_COLUMNS) * 16
        var ty := (block_id / ATLAS_COLUMNS) * 16
        for y in 16:
            for x in 16:
                var cell := ((x / 4) + (y / 4) * 3 + block_id) % 3
                var shade := 0.86 + float(((x + y + block_id * 2) % 5) - 2) * 0.045
                var c := SOURCE_PALETTE[base + cell] * shade
                image.set_pixel(tx + x, ty + y, Color(c.r, c.g, c.b, 1.0))
    image.generate_mipmaps()
    return ImageTexture.create_from_image(image)
