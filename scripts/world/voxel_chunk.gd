extends Node3D

const SIZE := 16
const HEIGHT := 96
var chunk_coord := Vector2i.ZERO
var voxels := PackedByteArray()
var mesh_instance: MeshInstance3D
var collision_body: StaticBody3D
var dirty := true
var world_ref: Node = null

func setup(coord: Vector2i, data: PackedByteArray, owner_world: Node = null) -> void:
    chunk_coord = coord
    voxels = data
    world_ref = owner_world
    if mesh_instance == null:
        mesh_instance = MeshInstance3D.new()
        add_child(mesh_instance)
    if collision_body == null:
        collision_body = StaticBody3D.new()
        add_child(collision_body)

func index_of(local: Vector3i) -> int:
    return local.x * SIZE * HEIGHT + local.z * HEIGHT + local.y

func get_voxel(local: Vector3i) -> int:
    if local.y < 0 or local.y >= HEIGHT:
        return BlockRegistry.AIR
    if local.x < 0 or local.x >= SIZE or local.z < 0 or local.z >= SIZE:
        if world_ref != null and world_ref.has_method("get_block"):
            var world_pos := Vector3i(chunk_coord.x * SIZE + local.x, local.y, chunk_coord.y * SIZE + local.z)
            return int(world_ref.get_block(world_pos))
        return BlockRegistry.AIR
    return voxels[index_of(local)]

func set_voxel(local: Vector3i, id: int) -> void:
    if local.x < 0 or local.x >= SIZE or local.z < 0 or local.z >= SIZE or local.y < 0 or local.y >= HEIGHT:
        return
    voxels[index_of(local)] = id
    dirty = true

func build_mesh() -> void:
    if voxels.is_empty():
        return
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var colors := PackedColorArray()
    var indices := PackedInt32Array()
    var fluid_vertices := PackedVector3Array()
    var fluid_normals := PackedVector3Array()
    var fluid_colors := PackedColorArray()
    var fluid_indices := PackedInt32Array()
    var face_dirs := [Vector3i.UP, Vector3i.DOWN, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]
    var face_verts := [
        [Vector3(0,1,0), Vector3(1,1,0), Vector3(1,1,1), Vector3(0,1,1)],
        [Vector3(0,0,1), Vector3(1,0,1), Vector3(1,0,0), Vector3(0,0,0)],
        [Vector3(0,0,0), Vector3(0,0,1), Vector3(0,1,1), Vector3(0,1,0)],
        [Vector3(1,0,1), Vector3(1,0,0), Vector3(1,1,0), Vector3(1,1,1)],
        [Vector3(0,0,1), Vector3(0,1,1), Vector3(1,1,1), Vector3(1,0,1)],
        [Vector3(1,0,0), Vector3(1,1,0), Vector3(0,1,0), Vector3(0,0,0)],
    ]
    var normals_face := [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
    for x in SIZE:
        for z in SIZE:
            for y in HEIGHT:
                var id := int(voxels[index_of(Vector3i(x,y,z))])
                if id == BlockRegistry.AIR:
                    continue
                var block := BlockRegistry.get_block(id)
                var base := Vector3(x, y, z)
                var is_fluid := id == BlockRegistry.WATER or id == BlockRegistry.LAVA
                for face_index in 6:
                    var n := Vector3i(x,y,z) + face_dirs[face_index]
                    var neighbor := get_voxel(n)
                    if is_fluid:
                        if neighbor == id:
                            continue
                        if BlockRegistry.is_solid(neighbor):
                            continue
                        var fluid_base := fluid_vertices.size()
                        var verts := face_verts[face_index]
                        for p in verts:
                            var fp := p
                            if face_index == 0:
                                fp.y = 0.88
                            elif face_index != 1:
                                fp.y *= 0.88
                            fluid_vertices.append(base + fp)
                            fluid_normals.append(normals_face[face_index])
                            fluid_colors.append(block.color)
                        fluid_indices.append_array(PackedInt32Array([fluid_base,fluid_base+1,fluid_base+2,fluid_base,fluid_base+2,fluid_base+3]))
                    else:
                        if BlockRegistry.is_solid(neighbor):
                            continue
                        var start := vertices.size()
                        var shade := 0.74 + face_index * 0.035
                        var c: Color = block.color * shade
                        for p in face_verts[face_index]:
                            vertices.append(base + p)
                            normals.append(normals_face[face_index])
                            colors.append(c)
                        indices.append_array(PackedInt32Array([start,start+1,start+2,start,start+2,start+3]))
    var array := []
    array.resize(Mesh.ARRAY_MAX)
    array[Mesh.ARRAY_VERTEX] = vertices
    array[Mesh.ARRAY_NORMAL] = normals
    array[Mesh.ARRAY_COLOR] = colors
    array[Mesh.ARRAY_INDEX] = indices
    var arr_mesh := ArrayMesh.new()
    if vertices.size() > 0:
        arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
        var mat := StandardMaterial3D.new()
        mat.vertex_color_use_as_albedo = true
        mat.roughness = 0.88
        arr_mesh.surface_set_material(0, mat)
    mesh_instance.mesh = arr_mesh
    for child in collision_body.get_children():
        child.queue_free()
    if arr_mesh.get_surface_count() > 0:
        var shape := arr_mesh.create_trimesh_shape()
        if shape != null:
            var collision := CollisionShape3D.new()
            collision.shape = shape
            collision_body.add_child(collision)

    var fluid_mesh := get_node_or_null("FluidMesh")
    if fluid_mesh == null:
        fluid_mesh = MeshInstance3D.new()
        fluid_mesh.name = "FluidMesh"
        add_child(fluid_mesh)
    var fluid_array := []
    fluid_array.resize(Mesh.ARRAY_MAX)
    fluid_array[Mesh.ARRAY_VERTEX] = fluid_vertices
    fluid_array[Mesh.ARRAY_NORMAL] = fluid_normals
    fluid_array[Mesh.ARRAY_COLOR] = fluid_colors
    fluid_array[Mesh.ARRAY_INDEX] = fluid_indices
    var fluid_arr := ArrayMesh.new()
    if fluid_vertices.size() > 0:
        fluid_arr.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, fluid_array)
        var fluid_mat := StandardMaterial3D.new()
        fluid_mat.vertex_color_use_as_albedo = true
        fluid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        fluid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
        fluid_mat.albedo_color = Color(1,1,1,0.62)
        fluid_mat.no_depth_test = false
        fluid_arr.surface_set_material(0, fluid_mat)
    fluid_mesh.mesh = fluid_arr
    dirty = false

