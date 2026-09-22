extends Node

const ROOT := "user://worlds"
const FORMAT_VERSION := 2
const MAX_BACKUPS := 5
const WORLD_ID_PATTERN := "^[A-Za-z0-9_-]{1,80}$"
var save_in_progress := false
var save_mutex := Mutex.new()

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))

func _valid_world_id(world_id: String) -> bool:
    if world_id.is_empty() or world_id.length() > 80:
        return false
    for i in world_id.length():
        var code := world_id.unicode_at(i)
        var allowed := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 95 or code == 45
        if not allowed:
            return false
    return true

func world_path(world_id: String) -> String:
    if not _valid_world_id(world_id):
        return ""
    return "%s/%s" % [ROOT, world_id]

func save_world(world_id: String, metadata: Dictionary, blocks: Dictionary, player_state: Dictionary) -> Error:
    if not _valid_world_id(world_id):
        return ERR_INVALID_PARAMETER
    save_mutex.lock()
    if save_in_progress:
        save_mutex.unlock()
        return ERR_BUSY
    save_in_progress = true

    var result: Error = OK
    var dir_path := world_path(world_id)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
    var payload := {
        "format_version": FORMAT_VERSION,
        "metadata": metadata,
        "blocks": blocks,
        "player": player_state,
        "saved_at": Time.get_datetime_string_from_system(true)
    }
    var tmp := dir_path + ".tmp"
    var file := FileAccess.open(tmp, FileAccess.WRITE)
    if file == null:
        result = FileAccess.get_open_error()
    else:
        file.store_string(JSON.stringify(payload))
        file.flush()
        var write_error: Error = file.get_error()
        file.close()
        if write_error != OK:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
            result = write_error

    if result == OK:
        var final_path := ProjectSettings.globalize_path(dir_path + "/world.json")
        var previous := ProjectSettings.globalize_path(dir_path + "/world.prev.json")
        if FileAccess.file_exists(final_path):
            if FileAccess.file_exists(previous):
                DirAccess.remove_absolute(previous)
            DirAccess.rename_absolute(final_path, previous)
        result = DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), final_path)
        if result != OK and FileAccess.file_exists(previous) and not FileAccess.file_exists(final_path):
            DirAccess.rename_absolute(previous, final_path)

    _finish_save()
    return result

func _finish_save() -> void:
    save_in_progress=false
    save_mutex.unlock()

func _read_valid_save(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    if not (data is Dictionary):
        return {}
    var version := int(data.get("format_version", 0))
    if version < 1 or version > FORMAT_VERSION:
        return {}
    if not (data.get("metadata", {}) is Dictionary) or not (data.get("blocks", {}) is Dictionary) or not (data.get("player", {}) is Dictionary):
        return {}
    var blocks:Dictionary=data.get("blocks", {})
    for key in blocks:
        var parts:=str(key).split(",")
        if parts.size()!=3 or not str(parts[0]).is_valid_int() or not str(parts[1]).is_valid_int() or not str(parts[2]).is_valid_int():
            return {}
        var id:=int(blocks[key])
        if id < BlockRegistry.AIR or id > BlockRegistry.LAST_BLOCK:
            return {}
    return data

func load_world(world_id: String) -> Dictionary:
    if not _valid_world_id(world_id):
        return {}
    var dir:=world_path(world_id)
    var primary:=_read_valid_save(dir+"/world.json")
    if not primary.is_empty():
        return primary
    return _read_valid_save(dir+"/world.prev.json")

func list_worlds() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var base := DirAccess.open(ROOT)
    if base == null:
        return result
    for name in base.get_directories():
        var data := load_world(name)
        if not data.is_empty():
            var metadata: Dictionary = data.get("metadata", {}).duplicate(true)
            metadata["saved_at"] = data.get("saved_at", metadata.get("saved_at", ""))
            result.append({"id": name, "metadata": metadata})
    return result

func rename_world(world_id: String, new_name: String) -> Error:
    if not _valid_world_id(world_id):
        return ERR_INVALID_PARAMETER
    var safe_name := new_name.strip_edges()
    if safe_name.is_empty() or safe_name.length() > 80:
        return ERR_INVALID_PARAMETER
    var data := load_world(world_id)
    if data.is_empty():
        return ERR_DOES_NOT_EXIST
    var metadata: Dictionary = data.get("metadata", {}).duplicate(true)
    metadata["name"] = safe_name
    return save_world(world_id, metadata, data.get("blocks", {}), data.get("player", {}))

func duplicate_world(world_id: String, new_name: String) -> String:
    if not _valid_world_id(world_id):
        return ""
    var data := load_world(world_id)
    if data.is_empty():
        return ""
    var new_id := "%s-copy-%d" % [world_id, Time.get_ticks_msec()]
    var metadata: Dictionary = data.get("metadata", {}).duplicate(true)
    var safe_name := new_name.strip_edges()
    metadata["name"] = safe_name if not safe_name.is_empty() else "%s Copy" % metadata.get("name", "World")
    if save_world(new_id, metadata, data.get("blocks", {}), data.get("player", {})) != OK:
        return ""
    return new_id

func backup_world(world_id: String) -> String:
    if not _valid_world_id(world_id):
        return ""
    var source := world_path(world_id) + "/world.json"
    if not FileAccess.file_exists(source):
        return ""
    var backup_dir := world_path(world_id) + "/backups"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(backup_dir))
    var stamp := str(Time.get_unix_time_from_system()) + "-" + str(Time.get_ticks_msec())
    var target := "%s/%s.json" % [backup_dir, stamp]
    var in_file := FileAccess.open(source, FileAccess.READ)
    var out_file := FileAccess.open(target, FileAccess.WRITE)
    if in_file == null or out_file == null:
        return ""
    out_file.store_string(in_file.get_as_text())
    out_file.flush()
    out_file.close(); in_file.close()
    var dir := DirAccess.open(backup_dir)
    if dir != null:
        var files: Array = []
        for file_name in dir.get_files():
            if str(file_name).ends_with(".json"):
                files.append(str(file_name))
        files.sort()
        while files.size() > MAX_BACKUPS:
            var old_name := str(files.pop_front())
            DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_dir + "/" + old_name))
    return target

func delete_world(world_id: String) -> Error:
    if not _valid_world_id(world_id):
        return ERR_INVALID_PARAMETER
    var dir_path := ProjectSettings.globalize_path(world_path(world_id))
    if not DirAccess.dir_exists_absolute(dir_path):
        return ERR_DOES_NOT_EXIST
    var dir := DirAccess.open(world_path(world_id))
    if dir == null:
        return ERR_CANT_OPEN
    for file_name in dir.get_files():
        DirAccess.remove_absolute(ProjectSettings.globalize_path(world_path(world_id) + "/" + file_name))
    for subdir_name in dir.get_directories():
        var subdir := DirAccess.open(world_path(world_id) + "/" + subdir_name)
        if subdir != null:
            for file_name in subdir.get_files():
                DirAccess.remove_absolute(ProjectSettings.globalize_path(world_path(world_id) + "/" + subdir_name + "/" + file_name))
        DirAccess.remove_absolute(ProjectSettings.globalize_path(world_path(world_id) + "/" + subdir_name))
    return DirAccess.remove_absolute(dir_path)