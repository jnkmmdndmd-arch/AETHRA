extends Control

@export var avatar_index: int = 0

const SKINS := [Color("#f3c7a6"), Color("#e8b184"), Color("#c98f68"), Color("#a96f4f"), Color("#744c3b")]
const SHIRTS := [Color("#4aa7d8"), Color("#6c75d7"), Color("#4eb47d"), Color("#d28b4f"), Color("#b85c7a"), Color("#9a6dcc")]
const HAIR := [Color("#2f241d"), Color("#5b3c2c"), Color("#1f2b35"), Color("#8a5539"), Color("#5a5340")]

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw() -> void:
    var side := minf(size.x, size.y)
    if side <= 1.0:
        return
    var i := clampi(avatar_index, 0, 29)
    var center := Vector2(size.x * 0.5, size.y * 0.5)
    var skin: Color = SKINS[i % SKINS.size()]
    var shirt: Color = SHIRTS[i % SHIRTS.size()]
    var hair: Color = HAIR[(i / SKINS.size()) % HAIR.size()]
    draw_circle(center, side * 0.47, Color(0.02, 0.06, 0.11, 0.95))
    draw_circle(Vector2(center.x, side * 0.40), side * 0.18, skin)
    draw_rect(Rect2(center.x - side * 0.25, side * 0.56, side * 0.50, side * 0.23), shirt, true)
    match i % 6:
        0: draw_arc(Vector2(center.x, side * 0.38), side * 0.20, PI, TAU, 20, hair, side * 0.08, true)
        1: draw_circle(Vector2(center.x, side * 0.30), side * 0.18, hair)
        2: draw_rect(Rect2(center.x - side * 0.19, side * 0.23, side * 0.38, side * 0.12), hair, true)
        3: draw_arc(Vector2(center.x, side * 0.36), side * 0.21, PI * 0.95, TAU * 0.95, 20, hair, side * 0.07, true)
        4:
            draw_circle(Vector2(center.x - side * 0.10, side * 0.28), side * 0.10, hair)
            draw_circle(Vector2(center.x + side * 0.10, side * 0.28), side * 0.10, hair)
        _:
            draw_line(Vector2(center.x - side * 0.18, side * 0.24), Vector2(center.x + side * 0.18, side * 0.31), hair, side * 0.06, true)
    match i % 5:
        0: draw_rect(Rect2(center.x - side * 0.07, side * 0.62, side * 0.14, side * 0.08), Color("#f2c85b"), true)
        1: draw_circle(Vector2(center.x + side * 0.15, side * 0.41), side * 0.04, Color("#ffdf7d"))
        2:
            draw_rect(Rect2(center.x - side * 0.16, side * 0.37, side * 0.10, side * 0.05), Color("#7ed6ff"), true)
            draw_rect(Rect2(center.x + side * 0.06, side * 0.37, side * 0.10, side * 0.05), Color("#7ed6ff"), true)
        3: draw_line(Vector2(center.x - side * 0.08, side * 0.52), Vector2(center.x + side * 0.08, side * 0.52), Color("#ff6f7e"), side * 0.03, true)
        _:
            draw_circle(Vector2(center.x, side * 0.72), side * 0.045, Color("#78ddff"))
