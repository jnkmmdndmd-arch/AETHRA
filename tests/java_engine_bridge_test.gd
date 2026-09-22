extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    var bridge := JavaEngineBridge.new()
    var empty := bridge.inspect("")
    _expect(int(empty.get("kind", -1)) == JavaEngineBridge.BackendKind.UNAVAILABLE, "Empty path must be unavailable")

    var temp_root := "user://java_bridge_test"
    DirAccess.make_dir_recursive_absolute(temp_root)
    var source_file := FileAccess.open(temp_root.path_join("Example.java"), FileAccess.WRITE)
    if source_file != null:
        source_file.store_string("class Example {}")
        source_file.close()
    var build_file := FileAccess.open(temp_root.path_join("build.gradle"), FileAccess.WRITE)
    if build_file != null:
        build_file.store_string("plugins { }")
        build_file.close()

    var result := bridge.inspect(ProjectSettings.globalize_path(temp_root))
    _expect(bridge.is_source_backend(result), "Java source + build files should be detected as source backend")

    _finish()

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("JAVA_ENGINE_BRIDGE_TEST: PASS")
        quit(0)
    else:
        for failure in failures:
            push_error("JAVA_ENGINE_BRIDGE_TEST: " + failure)
        quit(1)
