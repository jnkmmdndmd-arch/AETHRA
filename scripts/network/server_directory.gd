extends Node

signal servers_changed(servers)

var favorites: Array[Dictionary] = []

func load_favorites() -> void:
    if FileAccess.file_exists("user://server_favorites.json"):
        var f := FileAccess.open("user://server_favorites.json", FileAccess.READ)
        var data = JSON.parse_string(f.get_as_text()); f.close()
        if data is Array:
            favorites.assign(data)
    servers_changed.emit(favorites)

func add_favorite(address: String, name: String = "Favorite") -> void:
    for server in favorites:
        if server.get("address", "") == address:
            return
    favorites.append({"name": name, "address": address, "last_seen": Time.get_datetime_string_from_system(true)})
    _save()

func remove_favorite(address: String) -> void:
    favorites = favorites.filter(func(s): return s.get("address", "") != address)
    _save()

func recent() -> Array[Dictionary]:
    return favorites.duplicate(true)

func _save() -> void:
    var f := FileAccess.open("user://server_favorites.json", FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(favorites)); f.close()
    servers_changed.emit(favorites)
