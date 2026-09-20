extends Node3D

var player_id := 0
var player_name := "Player"
var character_id := "ranger"
var target_position := Vector3.ZERO
var target_yaw := 0.0

func setup(id: int, display_name: String, character: String) -> void:
    player_id = id
    player_name = display_name
    character_id = character
    target_position = global_position
    _build_visual()

func _build_visual() -> void:
    if get_child_count() > 0:
        return
    var body := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.height = 1.8
    mesh.radius = 0.34
    body.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = _character_color()
    material.roughness = 0.78
    body.material_override = material
    body.position.y = 0.9
    add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := BoxMesh.new()
    head_mesh.size = Vector3(0.62, 0.62, 0.62)
    head.mesh = head_mesh
    head.material_override = material
    head.position.y = 1.9
    add_child(head)

    var label := Label3D.new()
    label.text = player_name
    label.position.y = 2.65
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 32
    label.outline_size = 8
    add_child(label)

func _character_color() -> Color:
    match character_id:
        "engineer": return Color("#e29b52")
        "shadow": return Color("#6e7cff")
        "grove": return Color("#52c98a")
        _: return Color("#a9e7ff")

func apply_state(position: Vector3, yaw: float) -> void:
    target_position = position
    target_yaw = yaw

func _process(delta: float) -> void:
    global_position = global_position.lerp(target_position, minf(1.0, delta * 12.0))
    rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 12.0))
