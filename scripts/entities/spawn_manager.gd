extends Node3D

var world
var enabled := true
var spawn_timer := 0.0
var max_creatures := 8
var kinds := ["goat","deer","boar","fox","rabbit","wolf","horse","chicken","camel","vulture","fennec","lizard","snake","scorpion","bee","butterfly","dragonfly","firefly","beetle","moth","spider","slime","wraith","brute","drake","sand_wyrm","stone_golem","marsh_lurker","bat","crystal_mite"]

func setup(voxel_world, enable_creatures: bool = true) -> void:
    world = voxel_world
    enabled = enable_creatures
    var quality := str(Settings.get_value("graphics_quality", "low"))
    max_creatures = int({
        "low": 6,
        "medium": 10,
        "high": 16,
        "ultra": 20,
    }.get(quality, 6))
    if not enabled:
        return
    for i in mini(4, max_creatures):
        spawn_creature(kinds[i % kinds.size()])

func _process(delta: float) -> void:
    if not enabled:
        return
    spawn_timer -= delta
    if spawn_timer > 0.0:
        return
    spawn_timer = 3.0
    if get_child_count() < max_creatures:
        spawn_creature(kinds[randi_range(0, kinds.size()-1)])

func _ground_position(x: float, z: float) -> Vector3:
    var y := 32
    if world != null and world.has_method("get_block"):
        var top := 90
        if world.has_method("get_world_height"):
            top = maxi(8, int(world.get_world_height()) - 4)
        for scan_y in range(top, 0, -1):
            var ground := int(world.get_block(Vector3i(floori(x), scan_y, floori(z))))
            var above := int(world.get_block(Vector3i(floori(x), scan_y + 1, floori(z))))
            if BlockRegistry.is_solid(ground) and above == BlockRegistry.AIR:
                y = scan_y + 1
                break
    return Vector3(x, y, z)

func spawn_creature(kind: String) -> void:
    if world == null or not enabled:
        return
    var p := _ground_position(randf_range(-20, 20), randf_range(-20, 20))
    kind = _kind_for_biome(p, kind)
    var c = load("res://scripts/entities/creature.gd").new()
    add_child(c)
    c.add_to_group("creatures")
    c.setup(kind, p)

func _kind_for_biome(position: Vector3, fallback: String) -> String:
    if world == null or not world.has_method("get_biome_at"):
        return fallback
    var biome := str(world.get_biome_at(floori(position.x), floori(position.z)))
    var tables := {
        "arid": ["camel","vulture","fennec","lizard","snake","scorpion","beetle","firefly","sand_wyrm","brute"],
        "frost": ["wolf","rabbit","bat","wraith","drake","crystal_mite"],
        "grove": ["deer","boar","fox","rabbit","bee","butterfly","moth","spider","marsh_lurker"],
        "meadow": ["goat","deer","boar","fox","rabbit","horse","chicken","butterfly","dragonfly","bee","wolf","spider","slime"]
    }
    var options: Array = tables.get(biome, kinds)
    return str(options[randi_range(0, options.size() - 1)]) if not options.is_empty() else fallback
