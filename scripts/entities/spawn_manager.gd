extends Node3D

var world
var enabled := true
var spawn_timer := 0.0
var max_creatures := 8
var kinds := ["goat", "deer", "boar", "fox", "rabbit", "wolf", "brute", "spider", "slime", "wraith", "drake", "beetle", "moth", "firefly"]

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
    var y := 48
    if world != null and world.has_method("get_block"):
        for scan_y in range(90, 0, -1):
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
    var c = load("res://scripts/entities/creature.gd").new()
    add_child(c)
    c.setup(kind, p)
