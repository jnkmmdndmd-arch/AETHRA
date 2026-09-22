extends Node3D

var player: Node3D
var time_system: Node
var particles: CPUParticles3D
var rain_mesh: QuadMesh
var last_weather := "clear"

func setup(local_player: Node3D, world_time: Node) -> void:
    player = local_player
    time_system = world_time
    particles = CPUParticles3D.new()
    particles.amount = 700
    particles.lifetime = 1.4
    particles.local_coords = true
    particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    particles.emission_box_extents = Vector3(18, 2, 18)
    particles.direction = Vector3(0, -1, 0)
    particles.spread = 8.0
    particles.initial_velocity_min = 16.0
    particles.initial_velocity_max = 24.0
    particles.gravity = Vector3(0, -2, 0)
    rain_mesh = QuadMesh.new()
    rain_mesh.size = Vector2(0.025, 0.7)
    particles.mesh = rain_mesh
    particles.visible = false
    add_child(particles)

func _process(_delta: float) -> void:
    if particles == null or player == null or time_system == null:
        return
    global_position = player.global_position + Vector3(0, 10, 0)
    var weather := str(time_system.get("weather"))
    var active := weather == "rain"
    particles.visible = active
    if active and last_weather != weather:
        particles.restart()
    last_weather = weather