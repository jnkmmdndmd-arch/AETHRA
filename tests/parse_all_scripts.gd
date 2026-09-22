extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _scan("res://scripts")
    _scan("res://server")
    if failures.is_empty():
        print("[PARSE] All GDScript files loaded successfully.")
        quit(0)
        return
    print("[PARSE] GDScript parse failures:")
    for path in failures:
        print("[PARSE] FAIL: " + path)
    quit(1)

func _scan(path: String) -> void:
    var dir := DirAccess.open(path)
    if dir == null:
        failures.append(path + " (directory unavailable)")
        return
    for file_name in dir.get_files():
        var file := str(file_name)
        if not file.ends_with(".gd"):
            continue
        var script: GDScript = load(path + "/" + file) as GDScript
        if script == null or not script.can_instantiate():
            failures.append(path + "/" + file)
            continue
    for dir_name in dir.get_directories():
        _scan(path + "/" + str(dir_name))
