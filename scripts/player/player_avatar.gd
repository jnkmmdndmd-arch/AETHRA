extends CharacterBody3D

signal block_mined
signal block_placed

var inventory = preload("res://scripts/gameplay/inventory.gd").new()
var survival = preload("res://scripts/gameplay/survival.gd").new()
var crafting = preload("res://scripts/gameplay/crafting.gd").new()

var world
var camera: Camera3D
var head: Node3D
var pitch := 0.0
var walk_speed := 5.0
var sprint_speed := 8.0
var jump_velocity := 8.5
var mine_target := Vector3i.ZERO
var mining_started := 0.0
var mining_duration := 0.0
var mining_active := false
var is_local := true
var peer_id := 1
var attack_cooldown := 0.0
var footstep_timer := 0.0

func setup(voxel_world, local_player: bool = true, id: int = 1) -> void:
    world = voxel_world
    if survival.has_method("configure"):
        survival.configure(AppState.game_mode)
    is_local = local_player
    peer_id = id
    _build_body()

func _build_body() -> void:
    var capsule := CapsuleMesh.new()
    capsule.height = 1.8
    capsule.radius = 0.34
    var body := MeshInstance3D.new()
    body.mesh = capsule
    var mat := StandardMaterial3D.new()
    mat.albedo_color = _character_color(AppState.character_id if is_local else "ranger")
    mat.roughness = 0.75
    body.material_override = mat
    body.position.y = 0.9
    add_child(body)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.height = 1.8
    shape.radius = 0.34
    collision.shape = shape
    collision.position.y = 0.9
    add_child(collision)
    head = Node3D.new()
    head.position.y = 1.55
    add_child(head)
    camera = Camera3D.new()
    camera.current = is_local
    camera.fov = float(Settings.get_value("fov", 75.0))
    head.add_child(camera)

func _character_color(id: String) -> Color:
    match id:
        "engineer": return Color("#e29b52")
        "shadow": return Color("#6e7cff")
        "grove": return Color("#52c98a")
        _: return Color("#a9e7ff")

func _physics_process(delta: float) -> void:
    if not is_local:
        return
    _update_camera()
    _update_movement(delta)
    survival.tick(delta, _is_underwater(), Input.is_action_pressed("sprint"))
    attack_cooldown = maxf(0.0, attack_cooldown - delta)

func apply_damage(amount: float) -> void:
    survival.apply_damage(amount)

func _update_camera() -> void:
    var sensitivity := float(Settings.get_value("mouse_sensitivity", 0.15))
    var target_y := -pitch if bool(Settings.get_value("invert_y", false)) else pitch
    head.rotation.x = clampf(target_y, -1.5, 1.5)
    camera.fov = lerpf(camera.fov, float(Settings.get_value("fov", 75.0)), 0.15)

func _unhandled_input(event: InputEvent) -> void:
    if not is_local:
        return
    if event is InputEventKey and event.pressed:
        var slot := _hotbar_slot_from_key(event.physical_keycode)
        if slot >= 0:
            inventory.selected = slot
            _refresh_hotbar_ui()
            return
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            inventory.selected = posmod(inventory.selected - 1, 9)
            _refresh_hotbar_ui()
            return
        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            inventory.selected = posmod(inventory.selected + 1, 9)
            _refresh_hotbar_ui()
            return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * float(Settings.get_value("mouse_sensitivity", 0.15)) * 0.01)
        pitch = clampf(pitch - event.relative.y * float(Settings.get_value("mouse_sensitivity", 0.15)) * 0.01, -1.5, 1.5)
    elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_V:
        var third_person := not bool(Settings.get_value("first_person", true))
        Settings.values["first_person"] = third_person
        if camera:
            camera.position = Vector3(0, 0, 3.8) if third_person else Vector3.ZERO
    elif event.is_action_pressed("pause"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event.is_action_pressed("attack"):
        _attack()
    elif event.is_action_pressed("mine"):
        _start_mining()
    elif event.is_action_released("mine"):
        mining_active = false
    elif event.is_action_pressed("place"):
        _place_block()

func _update_movement(delta: float) -> void:
    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var basis := global_transform.basis
    var direction := (basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
    var speed := sprint_speed if Input.is_action_pressed("sprint") and survival.stamina > 0.5 else walk_speed
    velocity.x = move_toward(velocity.x, direction.x * speed, 24.0 * delta)
    velocity.z = move_toward(velocity.z, direction.z * speed, 24.0 * delta)
    if not is_on_floor():
        velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity", 24.0) * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity
        AudioManager.play("jump", -4.0)
    if is_on_floor() and direction.length() > 0.1:
        footstep_timer -= delta
        if footstep_timer <= 0.0:
            footstep_timer = 0.42 if not Input.is_action_pressed("sprint") else 0.30
            AudioManager.play("footstep", -8.0)
    else:
        footstep_timer = 0.0
    if Input.is_action_just_pressed("crouch"):
        scale.y = 0.8 if is_equal_approx(scale.y, 1.0) else 1.0
    move_and_slide()

func _start_mining() -> void:
    if world == null or AppState.game_mode == "adventure":
        return
    var result := _raycast_voxel()
    if result.is_empty():
        return
    var pos: Vector3i = result["block"]
    var id: int = int(world.get_block(pos))
    var block := BlockRegistry.get_block(id)
    if int(block.hardness) < 0:
        return
    mine_target = pos
    var held: Dictionary = inventory.slots[inventory.selected]
    var tool_bonus := 1.0
    var tool_id := int(held.item)
    if tool_id in [ItemRegistry.WOOD_PICK, ItemRegistry.STONE_PICK, ItemRegistry.IRON_PICK] and str(block.tool) == "pickaxe":
        tool_bonus = 1.0 + float(ItemRegistry.get_item(tool_id).power) * 0.45
    if tool_id in [ItemRegistry.WOOD_AXE, ItemRegistry.STONE_AXE, ItemRegistry.IRON_AXE] and str(block.tool) == "axe":
        tool_bonus = 1.0 + float(ItemRegistry.get_item(tool_id).power) * 0.45
    mining_duration = maxf(0.08, float(block.hardness) / tool_bonus)
    mining_started = Time.get_ticks_msec() / 1000.0
    mining_active = true
    _finish_mining()

func _finish_mining() -> void:
    if not mining_active:
        return
    await get_tree().create_timer(maxf(0.0, mining_duration - (Time.get_ticks_msec() / 1000.0 - mining_started))).timeout
    if not mining_active or world == null:
        mining_active = false
        return
    var id: int = int(world.get_block(mine_target))
    if id == BlockRegistry.AIR or id == BlockRegistry.BEDROCK:
        mining_active = false
        return
    if not is_local:
        mining_active = false
        return
    var held: Dictionary = inventory.slots[inventory.selected]
    var held_id := int(held.item)
    if held_id == ItemRegistry.EMPTY:
        held_id = ItemRegistry.HAND
    var block := BlockRegistry.get_block(id)
    if not _tool_matches(held_id, str(block.tool)) and str(block.tool) != "":
        mining_active = false
        return
    AudioManager.play("dig", -3.0)
    if NetworkManager.server_started or multiplayer.multiplayer_peer == null:
        if world.set_block(mine_target, BlockRegistry.AIR):
            inventory.add_item(BlockRegistry.get_drop(id), 1)
            survival.add_xp(1 if id in [BlockRegistry.COPPER_ORE, BlockRegistry.IRON_ORE, BlockRegistry.CRYSTAL_ORE] else 0)
            block_mined.emit()
            NetworkManager.apply_host_block_change(mine_target, BlockRegistry.AIR)
    else:
        NetworkManager.request_block_change.rpc_id(1, mine_target, BlockRegistry.AIR, held_id)
    mining_active = false

func _place_block() -> void:
    if world == null or AppState.game_mode == "adventure":
        return
    var result := _raycast_voxel()
    if result.is_empty():
        return
    var hit: Vector3i = result["block"]
    var normal: Vector3i = result["normal"]
    var target := hit + normal
    if world.get_block(target) != BlockRegistry.AIR:
        return
    var held: Dictionary = inventory.slots[inventory.selected]
    var id: int = _held_block_id(int(held.item))
    if id == BlockRegistry.AIR:
        return
    if inventory.count_item(int(held.item)) <= 0:
        return
    if _would_intersect_player(target):
        return
    var changed := false
    if NetworkManager.server_started or multiplayer.multiplayer_peer == null:
        if inventory.count_item(int(held.item)) <= 0:
            return
        changed = world.set_block(target, id)
        if changed:
            inventory.remove_item(int(held.item), 1)
            AudioManager.play("place", -3.0)
            NetworkManager.apply_host_block_change(target, id)
    else:
        NetworkManager.request_block_change.rpc_id(1, target, id, int(held.item))
        changed = false
    if changed:
        block_placed.emit()

func _held_block_id(item_id: int) -> int:
    if item_id >= 1 and item_id <= BlockRegistry.LAST_BLOCK:
        return item_id
    match item_id:
        8: return BlockRegistry.PLANK
        18: return BlockRegistry.CRAFTING
        _: return BlockRegistry.AIR

func _tool_matches(item_id: int, required_tool: String) -> bool:
    if required_tool.is_empty():
        return true
    var tool := ItemRegistry.get_item(item_id)
    if str(tool.get("category", "")) != "tool":
        return false
    var name := str(tool.get("name", "")).to_lower()
    return (required_tool == "pickaxe" and "pick" in name) or (required_tool == "axe" and "axe" in name) or (required_tool == "shovel" and "shovel" in name) or required_tool == "shears"

func _raycast_voxel() -> Dictionary:
    var origin := camera.global_position
    var direction := -camera.global_transform.basis.z
    var pos := origin
    var step := 0.08
    var last := Vector3i(floori(pos.x), floori(pos.y), floori(pos.z))
    for _i in 90:
        pos += direction * step
        var cell := Vector3i(floori(pos.x), floori(pos.y), floori(pos.z))
        if cell == last:
            continue
        var id: int = int(world.get_block(cell))
        if id != BlockRegistry.AIR and id != BlockRegistry.WATER and id != BlockRegistry.LAVA:
            return {"block": cell, "normal": cell - last}
        last = cell
    return {}

func _would_intersect_player(block: Vector3i) -> bool:
    return global_position.distance_to(Vector3(block) + Vector3.ONE * 0.5) < 1.15

func _is_underwater() -> bool:
    return world != null and world.get_block(Vector3i(floori(global_position.x), floori(global_position.y + 1.3), floori(global_position.z))) == BlockRegistry.WATER

func _hotbar_slot_from_key(keycode: Key) -> int:
    match keycode:
        KEY_1: return 0
        KEY_2: return 1
        KEY_3: return 2
        KEY_4: return 3
        KEY_5: return 4
        KEY_6: return 5
        KEY_7: return 6
        KEY_8: return 7
        KEY_9: return 8
        _: return -1

func _refresh_hotbar_ui() -> void:
    var hud_node := get_tree().get_first_node_in_group("aethra_hud")
    if hud_node != null and hud_node.has_method("set_selected"):
        hud_node.set_selected(inventory.selected)

func _attack() -> void:
    if attack_cooldown > 0.0:
        return
    attack_cooldown = 0.45
    var best: Node3D = null
    var best_distance := 3.2
    var forward := -camera.global_transform.basis.z
    for node in get_tree().get_nodes_in_group("creatures"):
        var target := node as Node3D
        if target == null:
            continue
        var offset := target.global_position - global_position
        var distance := offset.length()
        if distance > 0.1 and distance <= 3.2 and distance < best_distance and forward.dot(offset.normalized()) > 0.35:
            best = target
            best_distance = distance
    if best != null and best.has_method("apply_damage"):
        var held: Dictionary = inventory.slots[inventory.selected]
        var item_id := int(held.get("item", ItemRegistry.HAND))
        var weapon: Dictionary = ItemRegistry.get_item(item_id)
        var damage := float(weapon.get("power", 1))
        if str(weapon.get("category", "")) != "weapon":
            damage = 1.0
        best.apply_damage(damage + 2.0)
        AudioManager.play("dig", -7.0)
