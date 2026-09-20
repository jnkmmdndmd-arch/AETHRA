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
    mesh.size = Vector3(1.2, 0.8, 1.8)
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

func _color_for_type() -> Color:
    match creature_type:
        "wolf": return Color("#778596")
        "brute": return Color("#7d4e51")
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
    if creature_type == "brute" and not players.is_empty():
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
                target.apply_damage(2.0 if creature_type == "brute" else 1.0)
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
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    move_and_slide()

func apply_damage(amount: float) -> void:
    health -= amount
    if health <= 0.0:
        queue_free()
