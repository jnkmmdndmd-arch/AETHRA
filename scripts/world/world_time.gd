extends Node

signal lighting_changed(sun_angle, is_night)
signal weather_changed(kind)

var day_length_seconds := 1200.0
var world_time := 0.0
var weather := "clear"
var weather_timer := 90.0
var sun: DirectionalLight3D
var environment: Environment
var weather_enabled := true

func setup(light: DirectionalLight3D, env: Environment, enable_weather: bool = true) -> void:
    sun = light
    environment = env
    weather_enabled = enable_weather
    if environment:
        environment.fog_enabled = true
        environment.fog_light_color = Color("#6f8da8")
        environment.fog_light_energy = 0.55

func _process(delta: float) -> void:
    world_time = fmod(world_time + delta, day_length_seconds)
    var phase := world_time / day_length_seconds
    var angle := phase * TAU - PI * 0.5
    if sun:
        sun.rotation_degrees.x = rad_to_deg(angle)
        sun.light_energy = lerpf(0.18, 1.3, clampf(sin(angle) * 0.5 + 0.5, 0.0, 1.0))
    if environment:
        var daylight := clampf(sin(angle) * 0.5 + 0.5, 0.0, 1.0)
        environment.ambient_light_energy = lerpf(0.15, 1.0, daylight)
        environment.background_energy_multiplier = lerpf(0.18, 1.0, daylight)
    if not weather_enabled:
        weather = "clear"
        weather_timer = 999999.0
    weather_timer -= delta
    if weather_enabled and weather_timer <= 0.0:
        weather_timer = randf_range(60.0, 180.0)
        weather = ["clear", "clear", "rain", "fog"][randi() % 4]
        weather_changed.emit(weather)
    if environment:
        match weather:
            "fog":
                environment.fog_density = 0.055
                environment.fog_light_energy = 0.35
            "rain":
                environment.fog_density = 0.02
                environment.fog_light_energy = 0.45
            _:
                environment.fog_density = 0.008
                environment.fog_light_energy = 0.55
    lighting_changed.emit(angle, sin(angle) < -0.2)

func serialize() -> Dictionary:
    return {"world_time": world_time, "day_length": day_length_seconds, "weather": weather, "weather_timer": weather_timer, "weather_enabled": weather_enabled}

func deserialize(data: Dictionary) -> void:
    if data.is_empty():
        return
    world_time = fmod(float(data.get("world_time", world_time)), maxf(1.0, day_length_seconds))
    day_length_seconds = maxf(60.0, float(data.get("day_length", day_length_seconds)))
    weather = str(data.get("weather", weather))
    weather_enabled = bool(data.get("weather_enabled", weather_enabled))
    weather_timer = maxf(1.0, float(data.get("weather_timer", weather_timer)))
