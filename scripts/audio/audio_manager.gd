extends Node

var players: Dictionary = {}
var stream_cache: Dictionary = {}
var sounds: Dictionary = {
    "ui_click": "res://assets/audio/ui_click.wav",
    "dig": "res://assets/audio/dig.wav",
    "place": "res://assets/audio/place.wav",
    "footstep": "res://assets/audio/footstep.wav",
    "jump": "res://assets/audio/jump.wav",
    "goat": "res://assets/audio/goat.wav",
    "wolf": "res://assets/audio/wolf.wav",
    "brute": "res://assets/audio/brute.wav",
    "ambient": "res://assets/audio/ambient.wav",
}

func play(name: String, volume_db: float = 0.0) -> void:
    var path: String = sounds.get(name, "")
    if path.is_empty() or not ResourceLoader.exists(path):
        return
    var stream: AudioStream = null
    var cached = stream_cache.get(name)
    if cached is AudioStream:
        stream = cached
    if stream == null:
        stream = ResourceLoader.load(path, "AudioStream") as AudioStream
        if stream != null:
            stream_cache[name] = stream
    var p := AudioStreamPlayer.new()
    p.stream = stream
    p.volume_db = volume_db + linear_to_db(float(Settings.get_value("sfx_volume", 0.85)))
    add_child(p)
    p.play()
    p.finished.connect(p.queue_free)

func apply_settings() -> void:
    var master := AudioServer.get_bus_index("Master")
    if master >= 0:
        AudioServer.set_bus_volume_db(master, linear_to_db(clampf(float(Settings.get_value("master_volume", 0.8)), 0.0001, 1.0)))
