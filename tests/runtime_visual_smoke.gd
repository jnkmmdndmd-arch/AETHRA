extends SceneTree

var app_root: Node3D
var menu_button: Button

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://runtime-proof"))
    print("[VISUAL_SMOKE] Launching main.tscn")
    var main_scene := load("res://scenes/main.tscn") as PackedScene
    if main_scene == null:
        push_error("[VISUAL_SMOKE] FATAL: main.tscn could not be loaded.")
        quit(1)
        return
    app_root = main_scene.instantiate() as Node3D
    if app_root == null:
        push_error("[VISUAL_SMOKE] FATAL: scenes/main.tscn could not be instantiated.")
        quit(1)
        return
    root.add_child(app_root)
    await create_timer(1.2).timeout

    if app_root.menu == null or not is_instance_valid(app_root.menu):
        push_error("[VISUAL_SMOKE] FAIL: main menu node was not created.")
        quit(1)
        return
    var alpha: float = float(app_root.menu.modulate.a)
    print("[VISUAL_SMOKE] menu visible=", app_root.menu.visible, " alpha=", alpha)
    if not app_root.menu.visible or alpha < 0.99:
        push_error("[VISUAL_SMOKE] FAIL: main menu is not visibly rendered.")
        quit(1)
        return

    var viewport: Viewport = root.get_viewport()
    _add_runtime_proof_overlay(viewport, "MENU")
    await create_timer(0.05).timeout
    var screenshot: Image = viewport.get_texture().get_image()
    if screenshot != null:
        screenshot.save_png("res://runtime-proof/runtime-menu-proof.png")
        print("[VISUAL_SMOKE] menu screenshot saved")
    if not _copy_boot_log_and_validate():
        quit(1)
        return

    menu_button = _find_button(app_root.menu, "ابدأ اللعب")
    if menu_button == null:
        push_error("[VISUAL_SMOKE] FAIL: start-game button was not found.")
        quit(1)
        return
    print("[VISUAL_SMOKE] Pressing start-game button")
    menu_button.emit_signal("pressed")

    var deadline := Time.get_ticks_msec() + 12000
    while Time.get_ticks_msec() < deadline:
        await create_timer(0.25).timeout
        if app_root.world != null and app_root.player != null:
            var rendered := int(app_root.world.get_rendered_chunk_count()) if app_root.world.has_method("get_rendered_chunk_count") else 0
            var camera_ok: bool = app_root.player.camera != null and app_root.player.camera.current
            print("[VISUAL_SMOKE] world=", app_root.world != null, " player=", app_root.player != null, " rendered_chunks=", rendered, " camera=", camera_ok)
            if rendered > 0 and camera_ok:
                # Proof mode only: move the camera behind the local player so the screenshot visibly proves terrain + player.
                if app_root.player.has_method("get"):
                    app_root.player.camera.position = Vector3(0, 0, 3.8)
                    app_root.player.player_model.visible = true
                _add_runtime_proof_overlay(viewport, "WORLD_THIRD_PERSON_PROOF")
                await create_timer(0.05).timeout
                var world_shot: Image = viewport.get_texture().get_image()
                if world_shot != null:
                    world_shot.save_png("res://runtime-proof/runtime-world-proof.png")
                    print("[VISUAL_SMOKE] world screenshot saved")
                if not _copy_boot_log_and_validate():
                    quit(1)
                    return
                print("[VISUAL_SMOKE] SUCCESS: menu and world rendered")
                quit(0)
                return

    push_error("[VISUAL_SMOKE] FAIL: world/player/camera/rendered chunk did not become ready within 12 seconds.")
    quit(1)

func _add_runtime_proof_overlay(viewport: Viewport, phase: String) -> void:
    var old := viewport.get_node_or_null("RuntimeProofOverlay")
    if old != null:
        old.queue_free()
    var layer := CanvasLayer.new()
    layer.name = "RuntimeProofOverlay"
    layer.layer = 2000
    viewport.add_child(layer)
    var panel := ColorRect.new()
    panel.position = Vector2(14, 12)
    panel.size = Vector2(560, 72)
    panel.color = Color(0.01, 0.02, 0.03, 0.88)
    layer.add_child(panel)
    var label := Label.new()
    label.position = Vector2(10, 7)
    label.size = Vector2(540, 58)
    label.text = "AETHRA runtime proof | %s | %s\nGodot 4.7.2 candidate | system-clock timestamp" % [phase, Time.get_datetime_string_from_system(true)]
    label.add_theme_font_size_override("font_size", 16)
    layer.add_child(label)

func _find_button(node: Node, target_text: String) -> Button:
    for child in node.get_children():
        if child is Button and str(child.text).strip_edges() == target_text:
            return child
        var nested := _find_button(child, target_text)
        if nested != null:
            return nested
    return null

func _copy_boot_log_and_validate() -> bool:
    var required := [
        "boot_start",
        "window_restored",
        "lighting_built",
        "graphics_applied",
        "java_backend_checked",
        "auth_initialized",
        "main_menu_built",
        "network_presence_ready",
        "boot_complete"
    ]
    var source := FileAccess.open("user://boot_log.txt", FileAccess.READ)
    if source == null:
        push_error("[VISUAL_SMOKE] FAIL: user://boot_log.txt does not exist.")
        return false
    var text := source.get_as_text()
    source.close()
    var copy := FileAccess.open("res://runtime-proof/boot_log.txt", FileAccess.WRITE)
    if copy != null:
        copy.store_string(text)
        copy.close()
    for stage in required:
        if stage not in text:
            push_error("[VISUAL_SMOKE] FAIL: boot log missing stage: " + stage)
            return false
    print("[VISUAL_SMOKE] boot log contains all required stages")
    return true
