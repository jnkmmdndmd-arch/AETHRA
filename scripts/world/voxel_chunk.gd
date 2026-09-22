extends Node3D

const SIZE := 16
const DEFAULT_HEIGHT := 500
const FACE_DIRS: Array[Vector3i] = [Vector3i.UP, Vector3i.DOWN, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]
const FACE_NORMALS: Array[Vector3] = [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

var chunk_coord := Vector2i.ZERO
var voxels := PackedByteArray()
var mesh_instance: MeshInstance3D
var collision_body: StaticBody3D
var fluid_mesh: MeshInstance3D
var dirty := true
var collision_dirty := true
var collision_enabled := false
var world_ref: Node = null
var height := DEFAULT_HEIGHT
var lod_level := 0
var _minecraft_material: ShaderMaterial = null

func setup(coord: Vector2i, data: PackedByteArray, owner_world: Node = null) -> void:
    chunk_coord = coord
    voxels = data
    world_ref = owner_world
    height = maxi(1, int(float(data.size()) / float(SIZE * SIZE)))
    mesh_instance = MeshInstance3D.new()
    add_child(mesh_instance)
    collision_body = StaticBody3D.new()
    add_child(collision_body)
    fluid_mesh = MeshInstance3D.new()
    fluid_mesh.name = "FluidMesh"
    add_child(fluid_mesh)

func set_lod(level: int) -> void:
    var normalized := clampi(level, 0, 1)
    if lod_level == normalized:
        return
    lod_level = normalized
    dirty = true
    collision_dirty = true

func index_of(local: Vector3i) -> int:
    return local.x * SIZE * height + local.z * height + local.y

func get_voxel(local: Vector3i) -> int:
    if local.y < 0 or local.y >= height:
        return BlockRegistry.AIR
    if local.x < 0 or local.x >= SIZE or local.z < 0 or local.z >= SIZE:
        if world_ref != null and world_ref.has_method("get_block"):
            var world_pos := Vector3i(chunk_coord.x * SIZE + local.x, local.y, chunk_coord.y * SIZE + local.z)
            return int(world_ref.get_block(world_pos))
        return BlockRegistry.AIR
    return int(voxels[index_of(local)])

func set_voxel(local: Vector3i, id: int) -> void:
    if local.x < 0 or local.x >= SIZE or local.z < 0 or local.z >= SIZE or local.y < 0 or local.y >= height:
        return
    voxels[index_of(local)] = id
    dirty = true
    collision_dirty = true

func mark_mesh_dirty() -> void:
    dirty = true

func set_collision_enabled(enabled: bool) -> void:
    collision_enabled = enabled
    if not enabled or lod_level > 0:
        _clear_collision()
        return
    if not dirty and collision_dirty:
        _rebuild_collision()

func _clear_collision() -> void:
    if collision_body == null: return
    for child in collision_body.get_children(): child.queue_free()
    collision_dirty = false

func _rebuild_collision() -> void:
    if collision_body == null or mesh_instance == null or lod_level > 0: return
    for child in collision_body.get_children(): child.queue_free()
    var arr_mesh := mesh_instance.mesh as ArrayMesh
    if arr_mesh == null or arr_mesh.get_surface_count() == 0:
        collision_dirty = false
        return
    var shape := arr_mesh.create_trimesh_shape()
    if shape == null: return
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision_body.add_child(collision)
    collision_dirty = false

func _is_opaque_solid(id: int) -> bool:
    if id <= BlockRegistry.AIR or id > BlockRegistry.LAST_BLOCK or id in [BlockRegistry.WATER, BlockRegistry.LAVA]:
        return false
    var info := BlockRegistry.get_block(id)
    return bool(info.get("solid", false)) and not bool(info.get("transparent", false))

func _face_index(axis: int, positive: bool) -> int:
    if axis == 0: return 3 if positive else 2
    if axis == 1: return 0 if positive else 1
    return 4 if positive else 5

func _face_shade(face_index: int) -> float:
    return 0.72 + float(face_index) * 0.04

func _get_minecraft_material() -> ShaderMaterial:
    if _minecraft_material != null:
        return _minecraft_material
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D atlas_texture : source_color, filter_nearest;

void fragment() {
    float raw_id = floor(COLOR.r * 64.0);
    float tile_x = mod(raw_id, 8.0);
    float tile_y = floor(raw_id / 8.0);
    vec2 atlas_uv = (vec2(tile_x, tile_y) + fract(UV)) / 8.0;
    vec4 tex = texture(atlas_texture, atlas_uv);
    ALBEDO = tex.rgb * max(COLOR.g, 0.20);
    ROUGHNESS = 0.88;
}
"""
    _minecraft_material = ShaderMaterial.new()
    _minecraft_material.shader = shader
    _minecraft_material.set_shader_parameter("atlas_texture", MinecraftCompat.get_atlas())
    return _minecraft_material

func _emission_factor(id: int) -> float:
    return clampf(float(BlockRegistry.get_block(id).get("light_level", 0)) / 15.0, 0.0, 1.0)

func _quad_ao(p: Vector3i, axis: int) -> float:
    var dirs: Array[Vector3i]
    match axis:
        0: dirs = [Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]
        1: dirs = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]
        _: dirs = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN]
    var occupied := 0
    for d in dirs:
        if _is_opaque_solid(get_voxel(p + d)): occupied += 1
    return clampf(1.0 - float(occupied) * 0.045, 0.78, 1.05)

func _append_quad(vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array, indices: PackedInt32Array, p: Vector3, u: Vector3, v: Vector3, normal: Vector3, shade: float, positive: bool, block_id: int) -> void:
    var start := vertices.size()
    var uv_u := maxf(u.length(), 1.0)
    var uv_v := maxf(v.length(), 1.0)
    if positive:
        vertices.append(p); vertices.append(p + u); vertices.append(p + u + v); vertices.append(p + v)
        uvs.append(Vector2(0, 0)); uvs.append(Vector2(uv_u, 0)); uvs.append(Vector2(uv_u, uv_v)); uvs.append(Vector2(0, uv_v))
    else:
        vertices.append(p); vertices.append(p + v); vertices.append(p + u + v); vertices.append(p + u)
        uvs.append(Vector2(0, 0)); uvs.append(Vector2(0, uv_v)); uvs.append(Vector2(uv_u, uv_v)); uvs.append(Vector2(uv_u, 0))
    var encoded_id := (float(block_id) + 0.5) / 64.0
    var encoded_color := Color(encoded_id, clampf(shade, 0.20, 1.5), 1.0, 1.0)
    for _i in 4:
        normals.append(normal)
        colors.append(encoded_color)
    indices.append_array(PackedInt32Array([start,start+1,start+2,start,start+2,start+3]))

func _build_heightfield_lod() -> void:
    var step := 2
    var vertices := PackedVector3Array(); var normals := PackedVector3Array(); var colors := PackedColorArray(); var uvs := PackedVector2Array(); var indices := PackedInt32Array()
    for z in range(0,SIZE,step):
        for x in range(0,SIZE,step):
            var top_y := 0; var top_id := BlockRegistry.AIR
            for zz in range(z,mini(z+step,SIZE)):
                for xx in range(x,mini(x+step,SIZE)):
                    for yy in range(height-1,-1,-1):
                        var id := int(voxels[index_of(Vector3i(xx,yy,zz))])
                        if id != BlockRegistry.AIR and id != BlockRegistry.WATER and id != BlockRegistry.LAVA:
                            if yy >= top_y: top_y = yy; top_id = id
                            break
            if top_id == BlockRegistry.AIR: continue
            var encoded_id := (float(top_id) + 0.5) / 64.0
            var encoded_color := Color(encoded_id, 0.95, 1.0, 1.0)
            var start := vertices.size(); var y := float(top_y+1)
            vertices.append(Vector3(x,y,z)); vertices.append(Vector3(x+step,y,z)); vertices.append(Vector3(x+step,y,z+step)); vertices.append(Vector3(x,y,z+step))
            uvs.append(Vector2(0,0)); uvs.append(Vector2(step,0)); uvs.append(Vector2(step,step)); uvs.append(Vector2(0,step))
            for _i in 4: normals.append(Vector3.UP); colors.append(encoded_color)
            indices.append_array(PackedInt32Array([start,start+1,start+2,start,start+2,start+3]))
    var array := []; array.resize(Mesh.ARRAY_MAX); array[Mesh.ARRAY_VERTEX]=vertices; array[Mesh.ARRAY_NORMAL]=normals; array[Mesh.ARRAY_COLOR]=colors; array[Mesh.ARRAY_TEX_UV]=uvs; array[Mesh.ARRAY_INDEX]=indices
    var arr_mesh := ArrayMesh.new()
    if vertices.size()>0:
        arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,array)
        arr_mesh.surface_set_material(0,_get_minecraft_material())
    mesh_instance.mesh=arr_mesh; fluid_mesh.mesh=ArrayMesh.new(); dirty=false; collision_dirty=true; _clear_collision()

func build_mesh(build_collision: bool = false, requested_lod: int = 0) -> void:
    lod_level=clampi(requested_lod,0,1)
    if voxels.is_empty(): return
    if lod_level>0: _build_heightfield_lod(); return
    var vertices:=PackedVector3Array(); var normals:=PackedVector3Array(); var colors:=PackedColorArray(); var uvs:=PackedVector2Array(); var indices:=PackedInt32Array()
    var fluid_vertices:=PackedVector3Array(); var fluid_normals:=PackedVector3Array(); var fluid_colors:=PackedColorArray(); var fluid_indices:=PackedInt32Array()
    for axis in 3:
        var dims:=[SIZE,SIZE,height]
        var u_axis:=(axis+1)%3; var v_axis:=(axis+2)%3
        for slice in range(-1,dims[axis]):
            var mask:=[]; mask.resize(dims[u_axis]*dims[v_axis])
            for j in dims[v_axis]:
                for i in dims[u_axis]:
                    var pos:=Vector3i.ZERO; pos[axis]=slice; pos[u_axis]=i; pos[v_axis]=j
                    var a:=get_voxel(pos); var b:=get_voxel(pos + (Vector3i.RIGHT if axis==0 else Vector3i.UP if axis==1 else Vector3i.FORWARD))
                    var value:=0
                    if _is_opaque_solid(a) and not _is_opaque_solid(b): value=a
                    elif _is_opaque_solid(b) and not _is_opaque_solid(a): value=-b
                    mask[i+j*dims[u_axis]]=value
            var j:=0
            while j<dims[v_axis]:
                var i:=0
                while i<dims[u_axis]:
                    var value:=int(mask[i+j*dims[u_axis]])
                    if value==0: i+=1; continue
                    var width:=1
                    while i+width<dims[u_axis] and int(mask[i+width+j*dims[u_axis]])==value: width+=1
                    var height_merge:=1; var can_grow:=true
                    while j+height_merge<dims[v_axis] and can_grow:
                        for k in width:
                            if int(mask[i+k+(j+height_merge)*dims[u_axis]])!=value: can_grow=false; break
                        if can_grow: height_merge+=1
                    for yy in height_merge:
                        for xx in width: mask[i+xx+(j+yy)*dims[u_axis]]=0
                    var p:=Vector3.ZERO; p[axis]=slice+1; p[u_axis]=i; p[v_axis]=j
                    var u:=Vector3.ZERO; u[u_axis]=width; var v:=Vector3.ZERO; v[v_axis]=height_merge
                    var positive:=value>0; var block_id:=abs(value); var face_idx:=_face_index(axis,positive)
                    var shade:=_face_shade(face_idx)*_quad_ao(Vector3i(i,slice,j),axis)*(1.0+_emission_factor(block_id)*0.30)
                    _append_quad(vertices,normals,colors,uvs,indices,p,u,v,FACE_NORMALS[face_idx],shade,positive,block_id)
                    i+=width
                j+=1
    var solid_flags:=PackedByteArray(); var block_colors:Array[Color]=[]; solid_flags.resize(BlockRegistry.LAST_BLOCK+1); block_colors.resize(BlockRegistry.LAST_BLOCK+1)
    for block_id in BlockRegistry.LAST_BLOCK+1:
        var info:=BlockRegistry.get_block(block_id); solid_flags[block_id]=1 if bool(info.get("solid",false)) else 0; block_colors[block_id]=info.get("color",Color.WHITE)
    for x in SIZE:
        for z in SIZE:
            for y in height:
                var id:=int(voxels[index_of(Vector3i(x,y,z))])
                if id==BlockRegistry.AIR or _is_opaque_solid(id): continue
                var block_color: Color = block_colors[id] if id < block_colors.size() else Color.WHITE; var base: Vector3 = Vector3(x,y,z); var is_fluid: bool = id in [BlockRegistry.WATER,BlockRegistry.LAVA]
                for face_index in 6:
                    var neighbor:=get_voxel(Vector3i(x,y,z)+FACE_DIRS[face_index])
                    if is_fluid and (neighbor==id or (neighbor<solid_flags.size() and solid_flags[neighbor]==1)): continue
                    if not is_fluid and neighbor<solid_flags.size() and solid_flags[neighbor]==1: continue
                    var start:=fluid_vertices.size() if is_fluid else vertices.size(); var verts:=_legacy_face_verts(face_index)
                    for q in verts:
                        var fq:=q
                        if is_fluid:
                            if face_index==0: fq.y=0.88
                            elif face_index!=1: fq.y*=0.88
                            fluid_vertices.append(base+fq); fluid_normals.append(FACE_NORMALS[face_index]); fluid_colors.append(block_color)
                        else:
                            vertices.append(base+fq); normals.append(FACE_NORMALS[face_index]); colors.append(Color((float(id) + 0.5) / 64.0, _face_shade(face_index), 1.0, 1.0))
                    if not is_fluid:
                        uvs.append(Vector2(0,0)); uvs.append(Vector2(1,0)); uvs.append(Vector2(1,1)); uvs.append(Vector2(0,1))
                    if is_fluid: fluid_indices.append_array(PackedInt32Array([start,start+1,start+2,start,start+2,start+3]))
                    else: indices.append_array(PackedInt32Array([start,start+1,start+2,start,start+2,start+3]))
    var array:=[]; array.resize(Mesh.ARRAY_MAX); array[Mesh.ARRAY_VERTEX]=vertices; array[Mesh.ARRAY_NORMAL]=normals; array[Mesh.ARRAY_COLOR]=colors; array[Mesh.ARRAY_TEX_UV]=uvs; array[Mesh.ARRAY_INDEX]=indices
    var arr_mesh:=ArrayMesh.new()
    if vertices.size()>0:
        arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,array); arr_mesh.surface_set_material(0,_get_minecraft_material())
    mesh_instance.mesh=arr_mesh
    var fluid_array:=[]; fluid_array.resize(Mesh.ARRAY_MAX); fluid_array[Mesh.ARRAY_VERTEX]=fluid_vertices; fluid_array[Mesh.ARRAY_NORMAL]=fluid_normals; fluid_array[Mesh.ARRAY_COLOR]=fluid_colors; fluid_array[Mesh.ARRAY_INDEX]=fluid_indices
    var fluid_arr:=ArrayMesh.new()
    if fluid_vertices.size()>0:
        fluid_arr.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,fluid_array); var fluid_mat:=StandardMaterial3D.new(); fluid_mat.vertex_color_use_as_albedo=true; fluid_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; fluid_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; fluid_mat.albedo_color=Color(1,1,1,0.62); fluid_arr.surface_set_material(0,fluid_mat)
    fluid_mesh.mesh=fluid_arr; dirty=false; collision_dirty=true
    if build_collision and collision_enabled: _rebuild_collision()

func _legacy_face_verts(face_index:int)->PackedVector3Array:
    match face_index:
        0: return PackedVector3Array([Vector3(0,1,0),Vector3(1,1,0),Vector3(1,1,1),Vector3(0,1,1)])
        1: return PackedVector3Array([Vector3(0,0,1),Vector3(1,0,1),Vector3(1,0,0),Vector3(0,0,0)])
        2: return PackedVector3Array([Vector3(0,0,0),Vector3(0,0,1),Vector3(0,1,1),Vector3(0,1,0)])
        3: return PackedVector3Array([Vector3(1,0,1),Vector3(1,0,0),Vector3(1,1,0),Vector3(1,1,1)])
        4: return PackedVector3Array([Vector3(0,0,1),Vector3(0,1,1),Vector3(1,1,1),Vector3(1,0,1)])
        _: return PackedVector3Array([Vector3(1,0,0),Vector3(1,1,0),Vector3(0,1,0),Vector3(0,0,0)])