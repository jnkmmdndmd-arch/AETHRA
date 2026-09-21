extends Node3D

signal chunk_ready(coord)
signal block_changed(world_position, new_id)

const CHUNK_SIZE := 16
const LOAD_PER_FRAME := 1

var world_seed: int = 0
var generator: RefCounted
var chunks: Dictionary = {}
var chunk_queue: Array[Vector2i] = []
var pending: Dictionary = {}
var changed_blocks: Dictionary = {}
var spawn_position := Vector3(8.5, 45.0, 8.5)
var stream_center := Vector3.ZERO
var last_stream_chunk := Vector2i(999999, 999999)
var stream_tick := 0
var world_settings: Dictionary = {}
var spawn_ready := false

func initialize(seed_value: int) -> void:
    world_seed = seed_value
    generator = load("res://scripts/world/world_generator.gd").new(world_seed)
    if generator.has_method("configure"):
        generator.configure(true)
    _resolve_spawn_position()
    for x in range(-2, 3):
        for z in range(-2, 3):
            queue_chunk(Vector2i(x, z))

func _process(_delta: float) -> void:
    _stream_chunks()
    var budget := LOAD_PER_FRAME
    while budget > 0 and not chunk_queue.is_empty():
        var coord: Vector2i = chunk_queue.pop_front()
        if chunks.has(coord) or pending.has(coord):
            continue
        pending[coord] = true
        _generate_chunk(coord)
        budget -= 1

func _resolve_spawn_position() -> void:
    if generator == null:
        return
    var ground_y := 40
    for scan_y in range(90, 0, -1):
        var ground := int(generator.block_at(0, scan_y, 0))
        var above := int(generator.block_at(0, scan_y + 1, 0))
        if BlockRegistry.is_solid(ground) and above == BlockRegistry.AIR:
            ground_y = scan_y
            break
    spawn_position = Vector3(8.5, ground_y + 1.05, 8.5)
    spawn_ready = true

func configure(settings: Dictionary) -> void:
    world_settings = settings.duplicate(true)
    if generator != null and generator.has_method("configure"):
        generator.configure(bool(world_settings.get("structures", true)))

func set_stream_center(pos: Vector3) -> void:
    stream_center = pos

func _stream_chunks() -> void:
    var center := world_to_chunk(stream_center)
    if center == last_stream_chunk and stream_tick % 30 != 0:
        stream_tick += 1
        return
    last_stream_chunk = center
    stream_tick = 0
    var radius := clampi(int(Settings.get_value("render_distance", 7)), 3, 16)
    for x in range(center.x - radius, center.x + radius + 1):
        for z in range(center.y - radius, center.y + radius + 1):
            if maxi(abs(x - center.x), abs(z - center.y)) <= radius:
                queue_chunk(Vector2i(x, z))
    var unload_radius := radius + 2
    var to_remove: Array[Vector2i] = []
    for coord in chunks:
        if maxi(abs(coord.x - center.x), abs(coord.y - center.y)) > unload_radius:
            to_remove.append(coord)
    for coord in to_remove:
        var chunk = chunks[coord]
        if is_instance_valid(chunk):
            chunk.queue_free()
        chunks.erase(coord)
    stream_tick += 1

func queue_chunk(coord: Vector2i) -> void:
    if not chunks.has(coord) and not pending.has(coord) and coord not in chunk_queue:
        chunk_queue.append(coord)

func _generate_chunk(coord: Vector2i) -> void:
    var data: PackedByteArray = generator.generate_chunk(coord.x, coord.y)
    call_deferred("_apply_chunk", coord, data)

func _apply_chunk(coord: Vector2i, data: PackedByteArray) -> void:
    pending.erase(coord)
    if chunks.has(coord):
        return
    var chunk_script: GDScript = load("res://scripts/world/voxel_chunk.gd") as GDScript
    if chunk_script == null:
        push_error("Unable to load VoxelChunk script.")
        return
    var chunk: Node3D = chunk_script.new() as Node3D
    if chunk == null:
        push_error("VoxelChunk script did not create a Node3D instance.")
        return
    add_child(chunk)
    chunk.position = Vector3(coord.x * CHUNK_SIZE, 0, coord.y * CHUNK_SIZE)
    chunk.call("setup", coord, data, self)
    _apply_changed_to_chunk(chunk, coord)
    chunks[coord] = chunk
    chunk.call("build_mesh")
    chunk_ready.emit(coord)

func world_to_chunk(pos: Vector3) -> Vector2i:
    return Vector2i(floori(pos.x / CHUNK_SIZE), floori(pos.z / CHUNK_SIZE))

func world_to_local(pos: Vector3i) -> Vector3i:
    return Vector3i(posmod(pos.x, CHUNK_SIZE), pos.y, posmod(pos.z, CHUNK_SIZE))

func get_block(pos: Vector3i) -> int:
    if pos.y < 0 or pos.y >= 96:
        return BlockRegistry.AIR
    if changed_blocks.has(pos):
        return int(changed_blocks[pos])
    var coord := Vector2i(floori(float(pos.x) / CHUNK_SIZE), floori(float(pos.z) / CHUNK_SIZE))
    var chunk: Node3D = chunks.get(coord) as Node3D
    if chunk == null:
        return generator.block_at(pos.x, pos.y, pos.z)
    return chunk.get_voxel(world_to_local(pos))

func set_block(pos: Vector3i, id: int) -> bool:
    if pos.y < 0 or pos.y >= 96:
        return false
    var old := get_block(pos)
    if old == id:
        return false
    changed_blocks[pos] = id
    var coord := world_to_chunk(Vector3(pos))
    var chunk: Node3D = chunks.get(coord) as Node3D
    if chunk:
        chunk.call("set_voxel", world_to_local(pos), id)
        chunk.call("mark_mesh_dirty")
    _mark_neighbor_dirty(pos)
    block_changed.emit(pos, id)
    return true

func _mark_neighbor_dirty(pos: Vector3i) -> void:
    for offset in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
        var neighbor: Vector3i = pos + offset
        var coord := world_to_chunk(Vector3(neighbor))
        if chunks.has(coord):
            var chunk: Node3D = chunks[coord] as Node3D
            if chunk:
                chunk.call("mark_mesh_dirty")

func _apply_changed_to_chunk(chunk: Node3D, coord: Vector2i) -> void:
    for world_pos in changed_blocks:
        var p: Vector3i = world_pos
        if world_to_chunk(Vector3(p)) == coord:
            chunk.call("set_voxel", world_to_local(p), int(changed_blocks[world_pos]))

func save_delta() -> Dictionary:
    var packed := {}
    for pos in changed_blocks:
        packed["%d,%d,%d" % [pos.x,pos.y,pos.z]] = changed_blocks[pos]
    return packed

func load_delta(data: Dictionary) -> void:
    changed_blocks.clear()
    for key in data:
        var parts := str(key).split(",")
        if parts.size() == 3:
            changed_blocks[Vector3i(int(parts[0]),int(parts[1]),int(parts[2]))] = int(data[key])
    for coord in chunks:
        var chunk: Node3D = chunks[coord] as Node3D
        if is_instance_valid(chunk):
            _apply_changed_to_chunk(chunk, coord)
            chunk.call("build_mesh")
