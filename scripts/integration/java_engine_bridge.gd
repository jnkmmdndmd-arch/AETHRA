class_name JavaEngineBridge
extends RefCounted

enum BackendKind {
    UNAVAILABLE,
    JAVA_SOURCE_PROJECT,
    MINECRAFT_RUNTIME_PACKAGE,
}

func inspect(root_path: String) -> Dictionary:
    var root := root_path.strip_edges()
    if root.is_empty():
        return _result(BackendKind.UNAVAILABLE, "No Java backend path configured.")

    if not DirAccess.dir_exists_absolute(root):
        return _result(BackendKind.UNAVAILABLE, "Configured Java backend path does not exist.")

    var source_files := _find_source_files(root)
    var gradle_files := _find_named_files(root, ["build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts"])
    var maven_files := _find_named_files(root, ["pom.xml"])
    var minecraft_jars := _find_named_files_recursive(root, "1.17.1.jar")
    var version_manifests := _find_named_files_recursive(root, "1.17.1.json")

    if not source_files.is_empty() and (not gradle_files.is_empty() or not maven_files.is_empty()):
        return {
            "kind": BackendKind.JAVA_SOURCE_PROJECT,
            "kind_name": "java_source_project",
            "root": root,
            "source_files": source_files.size(),
            "build_files": gradle_files.size() + maven_files.size(),
            "minecraft_runtime_detected": not minecraft_jars.is_empty(),
            "version_manifests": version_manifests,
        }

    if not minecraft_jars.is_empty() or not version_manifests.is_empty():
        return {
            "kind": BackendKind.MINECRAFT_RUNTIME_PACKAGE,
            "kind_name": "minecraft_runtime_package",
            "root": root,
            "source_files": source_files.size(),
            "build_files": gradle_files.size() + maven_files.size(),
            "minecraft_jars": minecraft_jars,
            "version_manifests": version_manifests,
            "message": "Compiled runtime detected; Java source engine was not detected.",
        }

    return _result(BackendKind.UNAVAILABLE, "No supported Java source project or Minecraft runtime package detected.")

func is_source_backend(info: Dictionary) -> bool:
    return int(info.get("kind", BackendKind.UNAVAILABLE)) == BackendKind.JAVA_SOURCE_PROJECT

func kind_name(kind: int) -> String:
    match kind:
        BackendKind.JAVA_SOURCE_PROJECT:
            return "java_source_project"
        BackendKind.MINECRAFT_RUNTIME_PACKAGE:
            return "minecraft_runtime_package"
        _:
            return "unavailable"

func _result(kind: BackendKind, message: String) -> Dictionary:
    return {
        "kind": kind,
        "kind_name": kind_name(kind),
        "message": message,
        "source_files": 0,
        "build_files": 0,
        "minecraft_runtime_detected": false,
    }

func _find_source_files(root: String) -> Array[String]:
    return _find_files_with_extensions(root, [".java", ".kt"])

func _find_named_files(root: String, names: Array[String]) -> Array[String]:
    var found: Array[String] = []
    _walk(root, func(path: String, name: String, is_dir: bool) -> void:
        if not is_dir and name in names:
            found.append(path)
    )
    return found

func _find_named_files_recursive(root: String, target_name: String) -> Array[String]:
    var found: Array[String] = []
    _walk(root, func(path: String, name: String, is_dir: bool) -> void:
        if not is_dir and name == target_name:
            found.append(path)
    )
    return found

func _find_files_with_extensions(root: String, extensions: Array[String]) -> Array[String]:
    var found: Array[String] = []
    _walk(root, func(path: String, name: String, is_dir: bool) -> void:
        if is_dir:
            return
        for ext in extensions:
            if name.to_lower().ends_with(ext):
                found.append(path)
                break
    )
    return found

func _walk(root: String, visitor: Callable) -> void:
    var dir := DirAccess.open(root)
    if dir == null:
        return
    dir.list_dir_begin()
    while true:
        var name := dir.get_next()
        if name.is_empty():
            break
        if name == "." or name == "..":
            continue
        var full := root.path_join(name)
        var is_dir := dir.current_is_dir()
        visitor.call(full, name, is_dir)
        if is_dir:
            _walk(full, visitor)
    dir.list_dir_end()
