extends RefCounted

static func make_icon(kind: String, color: Color = Color("#78ddff"), minimum_size: Vector2 = Vector2(24, 24)) -> Control:
    var script := load("res://scripts/ui/vector_icon.gd") as GDScript
    if script == null or not script.can_instantiate():
        push_error("[UI] vector_icon.gd failed to load; using safe placeholder for icon: " + kind)
        var fallback := Control.new()
        fallback.custom_minimum_size = minimum_size
        return fallback
    var icon: Control = script.new()
    icon.custom_minimum_size = minimum_size
    icon.icon_name = kind
    icon.icon_color = color
    return icon

static func make_avatar(index: int = 0, minimum_size: Vector2 = Vector2(38, 38)) -> Control:
    var script := load("res://scripts/ui/avatar_renderer.gd") as GDScript
    if script == null or not script.can_instantiate():
        push_error("[UI] avatar_renderer.gd failed to load; using safe placeholder avatar.")
        var fallback := Control.new()
        fallback.custom_minimum_size = minimum_size
        return fallback
    var avatar: Control = script.new()
    avatar.custom_minimum_size = minimum_size
    avatar.avatar_index = clampi(index, 0, 29)
    return avatar
