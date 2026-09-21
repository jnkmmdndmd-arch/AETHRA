extends CharacterBody3D

var creature_type := "goat"
var health := 12.0
var target: Node3D
var state := "idle"
var think_timer := 0.0
var move_target := Vector3.ZERO
var speed := 2.2
var attack_cooldown := 0.0

func setup(kind: String, origin: Vector3) -> void:
    creature_type = kind
    global_position = origin
    _build_visual()

func _build_visual() -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = _size_for_type()
    body.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = _color_for_type()
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
        "brute", "drake", "sand_wyrm", "stone_golem", "marsh_lurker": return Vector3(1.5, 1.1, 2.1)
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
        _: return Color("#cbb58a")

func _physics_process(delta: float) -> void:
    think_timer -= delta
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    if think_timer <= 0.0:
        _think()
        think_timer = 0.6
    _move(delta)

func _think() -> void:
    var players := get_tree().get_nodes_in_group("players")
    if creature_type in ["brute", "spider", "wraith", "drake", "wolf", "sand_wyrm", "stone_golem", "marsh_lurker"] and not players.is_empty():
        target = players[0]
        state = "attack"
        return
    if randf() < 0.35 or target == null:
        target = null
        state = "explore"
        move_target = global_position + Vector3(randf_range(-8,8), 0, randf_range(-8,8))
    elif global_position.distance_to(target.global_position) < 10.0:
        state = "approach"

func _move(delta: float) -> void:
    if state == "attack" and target:
        move_target = target.global_position
        if global_position.distance_to(move_target) < 1.8 and attack_cooldown <= 0.0:
            if target.has_method("apply_damage"):
                target.apply_damage(4.0 if creature_type in ["brute", "drake", "sand_wyrm", "stone_golem"] else 2.0 if creature_type in ["spider", "wraith", "wolf", "marsh_lurker"] else 1.0)
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
    move_and_slide()

func apply_damage(amount: float) -> void:
    health -= amount
    if health <= 0.0:
        queue_free()
