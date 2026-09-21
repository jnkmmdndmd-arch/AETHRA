extends Control

@export var icon_name: String = "person"
@export var icon_color: Color = Color("#78ddff")
@export var line_width: float = 2.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(24, 24)
    queue_redraw()

func set_icon(kind: String) -> void:
    icon_name = kind
    queue_redraw()

func _draw() -> void:
    var side := minf(size.x, size.y)
    if side <= 1.0:
        return
    var c := icon_color
    var w := line_width
    var center := Vector2(size.x * 0.5, size.y * 0.5)

    match icon_name:
        "person", "profile":
            draw_circle(Vector2(center.x, side * 0.30), side * 0.14, c)
            draw_arc(Vector2(center.x, side * 0.78), side * 0.31, PI, TAU, 18, c, w, true)
        "players":
            draw_circle(Vector2(side * 0.34, side * 0.31), side * 0.12, c)
            draw_circle(Vector2(side * 0.66, side * 0.31), side * 0.12, c)
            draw_arc(Vector2(side * 0.34, side * 0.78), side * 0.24, PI, TAU, 16, c, w, true)
            draw_arc(Vector2(side * 0.66, side * 0.78), side * 0.24, PI, TAU, 16, c, w, true)
        "home":
            draw_polyline(PackedVector2Array([
                Vector2(side * 0.12, side * 0.47),
                Vector2(side * 0.50, side * 0.13),
                Vector2(side * 0.88, side * 0.47)
            ]), c, w, true)
            draw_line(Vector2(side * 0.22, side * 0.44), Vector2(side * 0.22, side * 0.88), c, w, true)
            draw_line(Vector2(side * 0.78, side * 0.44), Vector2(side * 0.78, side * 0.88), c, w, true)
            draw_line(Vector2(side * 0.22, side * 0.88), Vector2(side * 0.78, side * 0.88), c, w, true)
            draw_rect(Rect2(side * 0.43, side * 0.64, side * 0.14, side * 0.24), c, false, w)
        "play":
            draw_colored_polygon(PackedVector2Array([
                Vector2(side * 0.34, side * 0.18),
                Vector2(side * 0.78, side * 0.50),
                Vector2(side * 0.34, side * 0.82)
            ]), c)
        "servers":
            for y in [0.24, 0.50, 0.76]:
                draw_rect(Rect2(side * 0.16, side * y - side * 0.08, side * 0.68, side * 0.16), c, false, w)
                draw_circle(Vector2(side * 0.72, side * y), side * 0.025, c)
        "world":
            draw_arc(center, side * 0.38, 0.0, TAU, 32, c, w, true)
            draw_arc(center, side * 0.38, -PI * 0.5, PI * 0.5, 20, c, w, true)
            draw_arc(center, side * 0.23, -PI * 0.5, PI * 0.5, 20, c, w, true)
            draw_line(Vector2(side * 0.12, center.y), Vector2(side * 0.88, center.y), c, w, true)
        "store":
            draw_rect(Rect2(side * 0.18, side * 0.30, side * 0.64, side * 0.56), c, false, w)
            draw_arc(Vector2(center.x, side * 0.30), side * 0.20, PI, TAU, 16, c, w, true)
            draw_line(Vector2(side * 0.27, side * 0.43), Vector2(side * 0.73, side * 0.43), c, w, true)
        "settings":
            draw_circle(center, side * 0.27, c, false, w, true)
            draw_circle(center, side * 0.09, c)
            for i in 8:
                var a := float(i) * TAU / 8.0
                draw_line(center + Vector2.from_angle(a) * side * 0.31, center + Vector2.from_angle(a) * side * 0.43, c, w, true)
        "developer":
            draw_line(Vector2(side * 0.36, side * 0.20), Vector2(side * 0.18, center.y), c, w, true)
            draw_line(Vector2(side * 0.18, center.y), Vector2(side * 0.36, side * 0.80), c, w, true)
            draw_line(Vector2(side * 0.64, side * 0.20), Vector2(side * 0.82, center.y), c, w, true)
            draw_line(Vector2(side * 0.82, center.y), Vector2(side * 0.64, side * 0.80), c, w, true)
            draw_line(Vector2(side * 0.56, side * 0.16), Vector2(side * 0.44, side * 0.84), c, w, true)
        "logout", "join":
            draw_rect(Rect2(side * 0.20, side * 0.16, side * 0.44, side * 0.68), c, false, w)
            draw_line(Vector2(side * 0.48, center.y), Vector2(side * 0.88, center.y), c, w, true)
            draw_line(Vector2(side * 0.68, side * 0.32), Vector2(side * 0.88, center.y), c, w, true)
            draw_line(Vector2(side * 0.68, side * 0.68), Vector2(side * 0.88, center.y), c, w, true)
        "host":
            draw_circle(Vector2(side * 0.40, side * 0.33), side * 0.12, c)
            draw_arc(Vector2(side * 0.40, side * 0.78), side * 0.25, PI, TAU, 16, c, w, true)
            draw_arc(Vector2(side * 0.72, side * 0.50), side * 0.18, -PI * 0.55, PI * 0.55, 14, c, w, true)
            draw_arc(Vector2(side * 0.72, side * 0.50), side * 0.27, -PI * 0.55, PI * 0.55, 14, c, w, true)
        "bell", "notifications":
            draw_arc(Vector2(center.x, side * 0.47), side * 0.27, PI, TAU, 18, c, w, true)
            draw_line(Vector2(side * 0.23, side * 0.47), Vector2(side * 0.23, side * 0.64), c, w, true)
            draw_line(Vector2(side * 0.77, side * 0.47), Vector2(side * 0.77, side * 0.64), c, w, true)
            draw_line(Vector2(side * 0.23, side * 0.64), Vector2(side * 0.77, side * 0.64), c, w, true)
            draw_circle(Vector2(center.x, side * 0.75), side * 0.055, c)
        "minimize":
            draw_line(Vector2(side * 0.20, center.y), Vector2(side * 0.80, center.y), c, w, true)
        "maximize":
            draw_rect(Rect2(side * 0.22, side * 0.22, side * 0.56, side * 0.56), c, false, w)
        "close":
            draw_line(Vector2(side * 0.25, side * 0.25), Vector2(side * 0.75, side * 0.75), c, w, true)
            draw_line(Vector2(side * 0.75, side * 0.25), Vector2(side * 0.25, side * 0.75), c, w, true)
        "add":
            draw_circle(center, side * 0.34, c, false, w, true)
            draw_line(Vector2(side * 0.31, center.y), Vector2(side * 0.69, center.y), c, w, true)
            draw_line(Vector2(center.x, side * 0.31), Vector2(center.x, side * 0.69), c, w, true)
        "badge":
            draw_circle(center, side * 0.34, c, false, w, true)
            draw_polyline(PackedVector2Array([
                Vector2(side * 0.32, side * 0.30),
                Vector2(side * 0.42, side * 0.18),
                Vector2(side * 0.50, side * 0.27),
                Vector2(side * 0.58, side * 0.18),
                Vector2(side * 0.68, side * 0.30)
            ]), c, w, true)
            draw_line(Vector2(side * 0.38, side * 0.49), Vector2(side * 0.62, side * 0.49), c, w, true)
            draw_line(Vector2(side * 0.38, side * 0.59), Vector2(side * 0.62, side * 0.59), c, w, true)
        _:
            draw_circle(center, side * 0.25, c, false, w, true)
