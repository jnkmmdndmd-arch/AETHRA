extends CharacterBody3D

var creature_type := "goat"
var health := 12.0
var target: Node3D
var state := "idle"
var think_timer := 0.0
var move_target := Vector3.ZERO
var speed := 2.2
var attack_cooldown := 0.0
var detection_range := 18.0
var attack_range := 1.8
var life_time := 0.0
const MAX_LIFE_TIME := 900.0
const HOSTILES := ["brute","spider","wraith","drake","wolf","sand_wyrm","stone_golem","marsh_lurker","scorpion","slime","bat","crystal_mite","creeper","zombie","skeleton","enderman","witch","guardian","blaze","ghast","endermite","silverfish","piglin","hoglin","ravager","wither","phantom"]
const LOOT_TABLE := {"rabbit":[200,2],"chicken":[200,1],"boar":[200,2],"deer":[6,1],"wolf":[145,1],"brute":[12,1],"spider":[22,1],"drake":[13,1],"scorpion":[52,1],"crystal_mite":[59,1]}

func setup(kind: String, origin: Vector3) -> void:
    creature_type = kind.to_lower()
    global_position = origin
    var health_table := {
        "cow": 10.0, "pig": 10.0, "sheep": 8.0, "chicken": 4.0, "horse": 15.0,
        "wolf": 12.0, "fox": 10.0, "goat": 10.0, "rabbit": 3.0, "bee": 10.0,
        "bat": 6.0, "spider": 16.0, "creeper": 20.0, "zombie": 20.0, "skeleton": 20.0,
        "enderman": 40.0, "witch": 26.0, "guardian": 30.0, "blaze": 20.0, "ghast": 10.0,
        "endermite": 8.0, "silverfish": 8.0, "piglin": 16.0, "hoglin": 40.0,
        "ravager": 100.0, "phantom": 20.0, "wither": 300.0,
    }
    health = float(health_table.get(creature_type, 18.0 if creature_type in HOSTILES else 10.0))
    detection_range = 22.0 if creature_type in HOSTILES else 0.0
    _build_visual()
    add_to_group("creatures")

func _build_visual() -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = _size_for_type()
    body.mesh = mesh
    var mat: Material = MinecraftCompat.get_entity_material(creature_type)
    if mat == null:
        var fallback := StandardMaterial3D.new()
        fallback.albedo_color = _color_for_type()
        mat = fallback
    body.material_override = mat
    body.position.y = 0.65
    add_child(body)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.height = 1.2
    shape.radius = 0.55
    collision.shape = shape
    collision.position.y = 0.65
    add_child(collision)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.38
    head_mesh.height = 0.75
    head.mesh = head_mesh
    head.material_override = mat
    head.position = Vector3(0, 1.1, 0.9)
    add_child(head)

func _size_for_type() -> Vector3:
    match creature_type:
        "rabbit", "firefly", "fennec", "lizard", "snake", "bat", "crystal_mite": return Vector3(0.7, 0.5, 1.0)
        "spider": return Vector3(1.5, 0.45, 1.5)
        "beetle", "moth", "scorpion", "bee", "butterfly", "dragonfly": return Vector3(0.9, 0.35, 1.2)
        "brute", "drake", "sand_wyrm", "stone_golem", "marsh_lurker", "ravager", "wither": return Vector3(1.7, 1.2, 2.2)
        "creeper", "zombie", "skeleton", "enderman", "witch", "piglin", "hoglin": return Vector3(1.0, 1.8, 1.0)
        "guardian", "blaze", "ghast", "phantom": return Vector3(1.5, 1.4, 1.5)
        "endermite", "silverfish": return Vector3(0.8, 0.45, 1.1)
        _: return Vector3(1.2, 0.8, 1.8)

func _color_for_type() -> Color:
    match creature_type:
        "wolf": return Color("#778596")
        "brute": return Color("#7d4e51")
        "deer": return Color("#9c704f")
        "boar": return Color("#704f43")
        "fox": return Color("#c66e3d")
        "rabbit": return Color("#b8a79a")
        "spider": return Color("#433a52")
        "slime": return Color("#58bf7a")
        "wraith": return Color("#6d8fff")
        "drake": return Color("#9a4c64")
        "beetle": return Color("#365c57")
        "moth": return Color("#c4a4d9")
        "firefly": return Color("#a6d85b")
        "camel": return Color("#c79f72")
        "vulture": return Color("#5f5a56")
        "fennec": return Color("#d98c55")
        "lizard": return Color("#698e55")
        "snake": return Color("#4f6d45")
        "scorpion": return Color("#6d4f3c")
        "bee": return Color("#d8b63f")
        "butterfly": return Color("#7fa3d8")
        "dragonfly": return Color("#5a98a9")
        "horse": return Color("#75563f")
        "chicken": return Color("#d8d2c5")
        "bat": return Color("#4a4259")
        "sand_wyrm": return Color("#9c6a4a")
        "stone_golem": return Color("#7a7b78")
        "marsh_lurker": return Color("#466d5a")
        "crystal_mite": return Color("#8e83d1")
        "creeper": return Color("#4d8d50")
        "zombie": return Color("#5b8b72")
        "skeleton": return Color("#c7c7c7")
        "enderman": return Color("#2e213f")
        "witch": return Color("#5b3c59")
        "guardian": return Color("#6f9c9c")
        "blaze": return Color("#e1a03a")
        "ghast": return Color("#e8e8e8")
        "endermite": return Color("#6c8fb3")
        "silverfish": return Color("#7d7d7d")
        "piglin", "hoglin": return Color("#a6654e")
        "ravager": return Color("#666a62")
        "wither": return Color("#303033")
        "phantom": return Color("#4a5d7a")
        _: return Color("#cbb58a")

func _physics_process(delta: float) -> void:
    life_time += delta
    if life_time > MAX_LIFE_TIME:
        queue_free(); return
    var nearest_player:=_nearest_player_distance()
    if nearest_player > 64.0 and nearest_player > 0.0:
        queue_free(); return
    think_timer -= delta
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    if think_timer <= 0.0:
        _think()
        think_timer = 0.6
    _move(delta)

func _think() -> void:
    if target != null and (not is_instance_valid(target) or global_position.distance_to(target.global_position) > detection_range):
        target = null
    var players := get_tree().get_nodes_in_group("players")
    if creature_type in HOSTILES:
        var nearest: Node3D = null
        var nearest_distance := detection_range
        for candidate in players:
            var player_node := candidate as Node3D
            if player_node == null or not is_instance_valid(player_node):
                continue
            var distance := global_position.distance_to(player_node.global_position)
            if distance < nearest_distance and _has_line_of_sight(player_node):
                nearest = player_node
                nearest_distance = distance
        target = nearest
        state = "attack" if target != null else "idle"
        if target == null:
            move_target = global_position
        return

    if randf() < 0.35 or target == null or not is_instance_valid(target):
        target = null
        state = "explore"
        move_target = global_position + Vector3(randf_range(-8,8), 0, randf_range(-8,8))
    elif global_position.distance_to(target.global_position) < 10.0:
        state = "approach"
    else:
        state = "idle"

func _has_line_of_sight(player_node: Node3D) -> bool:
    var space_state := get_world_3d().direct_space_state
    var from := global_position + Vector3.UP * 0.8
    var to := player_node.global_position + Vector3.UP * 0.8
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    query.collision_mask = 1
    var hit := space_state.intersect_ray(query)
    return hit.is_empty() or hit.get("collider") == player_node

func _move(delta: float) -> void:
    if state == "attack" and target:
        move_target = target.global_position
        if global_position.distance_to(move_target) < attack_range and attack_cooldown <= 0.0 and _has_line_of_sight(target):
            if target.has_method("apply_damage"):
                target.apply_damage(_attack_damage())
            attack_cooldown = 1.4
    var flat := Vector3(move_target.x - global_position.x, 0, move_target.z - global_position.z)
    if flat.length() > 0.5:
        flat = flat.normalized()
        velocity.x = flat.x * speed
        velocity.z = flat.z * speed
        look_at(global_position + Vector3(flat.x, 0, flat.z), Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 7.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 7.0 * delta)
    if creature_type in ["beetle", "moth", "firefly"] and target == null:
        global_position.y += sin(Time.get_ticks_msec() * 0.004 + global_position.x) * 0.002
    if not is_on_floor() and creature_type not in ["beetle", "moth", "firefly"]:
        velocity.y -= 24.0 * delta
    if flat.length() > 0.1:
        var probe := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.6, global_position + Vector3.UP * 0.6 + flat.normalized() * 1.2)
        probe.exclude=[self]; probe.collision_mask=1
        if not get_world_3d().direct_space_state.intersect_ray(probe).is_empty():
            velocity.x=-flat.z*speed*0.5; velocity.z=flat.x*speed*0.5
    move_and_slide()

func _attack_damage() -> float:
    var damage_table := {
        "creeper": 6.0, "zombie": 3.0, "skeleton": 3.0, "enderman": 7.0,
        "witch": 3.0, "guardian": 4.0, "blaze": 5.0, "ghast": 6.0,
        "piglin": 4.0, "hoglin": 6.0, "ravager": 8.0, "phantom": 5.0,
        "wither": 10.0, "brute": 5.0, "drake": 5.0, "sand_wyrm": 5.0,
        "stone_golem": 6.0, "marsh_lurker": 3.0, "spider": 2.0, "wolf": 2.0, "wraith": 2.0,
        "scorpion": 2.0, "slime": 1.0, "bat": 1.0, "crystal_mite": 1.0
    }
    return float(damage_table.get(creature_type, 1.0))

func _nearest_player_distance() -> float:
    var best:=0.0
    for node in get_tree().get_nodes_in_group("players"):
        var p:=node as Node3D
        if p==null or not is_instance_valid(p): continue
        var d:=global_position.distance_to(p.global_position)
        if best==0.0 or d<best: best=d
    return best

func apply_damage(amount: float) -> void:
    if amount<=0.0: return
    health=maxf(0.0,health-amount)
    if health>0.0: return
    _grant_loot(); queue_free()

func _grant_loot() -> void:
    var entry=LOOT_TABLE.get(creature_type,[])
    if not (entry is Array) or entry.size()<2: return
    var item_id:=int(entry[0]); var amount:=maxi(1,int(entry[1]))
    for player_node in get_tree().get_nodes_in_group("players"):
        var p:=player_node as Node3D
        if p!=null and p.has_method("_use_selected_item") and global_position.distance_to(p.global_position)<=3.5:
            if p.inventory.add_item(item_id,amount)==0: break
    Economy.add_coins(1+int(randf()*4))