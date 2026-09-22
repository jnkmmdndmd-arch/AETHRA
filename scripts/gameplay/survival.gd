extends RefCounted

signal health_changed(health, max_health)
signal died
signal stats_changed

var max_health := 20.0
var health := 20.0
var hunger := 20.0
var stamina := 20.0
var air := 20.0
var armor := 0
var xp := 0
var game_mode := "survival"

func configure(mode: String) -> void:
    game_mode = mode.to_lower()
    if game_mode == "creative":
        hunger = 20.0
        stamina = 20.0
        air = 20.0


func tick(delta: float, underwater: bool, sprinting: bool) -> void:
    if game_mode == "creative":
        stamina = 20.0
        hunger = 20.0
        air = 20.0
        stats_changed.emit()
        return
    if sprinting:
        stamina = maxf(0.0, stamina - delta * 3.0)
    else:
        stamina = minf(20.0, stamina + delta * 1.5)
    hunger = maxf(0.0, hunger - delta * 0.05)
    if underwater:
        air = maxf(0.0, air - delta)
        if air <= 0.0:
            apply_damage(2.0 * delta)
    else:
        air = minf(20.0, air + delta * 2.0)
    if hunger > 16.0 and health < max_health:
        health = minf(max_health, health + delta * 0.3)
    stats_changed.emit()

func apply_damage(amount: float) -> void:
    if game_mode == "creative" or amount <= 0.0:
        return
    var reduced := maxf(0.0, amount - armor * 0.05)
    if reduced <= 0.0:
        return
    health = maxf(0.0, health - reduced)
    health_changed.emit(health, max_health)
    if health <= 0.0:
        died.emit()

func is_food(item_id: int) -> bool:
    return item_id in [
        ItemRegistry.HEAL_FOOD,
        ItemRegistry.MC_APPLE, ItemRegistry.MC_BREAD, ItemRegistry.MC_CARROT, ItemRegistry.MC_POTATO,
        ItemRegistry.MC_BAKED_POTATO, ItemRegistry.MC_BEETROOT, ItemRegistry.MC_MELON_SLICE,
        ItemRegistry.MC_PUMPKIN_PIE, ItemRegistry.MC_COOKIE, ItemRegistry.MC_CAKE,
        ItemRegistry.MC_BEEF, ItemRegistry.MC_COOKED_BEEF, ItemRegistry.MC_CHICKEN,
        ItemRegistry.MC_COOKED_CHICKEN, ItemRegistry.MC_PORKCHOP, ItemRegistry.MC_COOKED_PORKCHOP,
        ItemRegistry.MC_MUTTON, ItemRegistry.MC_COOKED_MUTTON, ItemRegistry.MC_RABBIT,
        ItemRegistry.MC_COOKED_RABBIT, ItemRegistry.MC_COD, ItemRegistry.MC_COOKED_COD,
        ItemRegistry.MC_SALMON, ItemRegistry.MC_COOKED_SALMON
    ]

func consume_food(item_id: int) -> bool:
    if game_mode == "creative" or not is_food(item_id):
        return false
    var values := {
        ItemRegistry.HEAL_FOOD: Vector2(6.0, 3.0),
        ItemRegistry.MC_APPLE: Vector2(4.0, 2.0), ItemRegistry.MC_BREAD: Vector2(5.0, 2.0),
        ItemRegistry.MC_CARROT: Vector2(3.0, 1.0), ItemRegistry.MC_POTATO: Vector2(1.0, 0.0),
        ItemRegistry.MC_BAKED_POTATO: Vector2(5.0, 3.0), ItemRegistry.MC_BEETROOT: Vector2(1.0, 0.0),
        ItemRegistry.MC_MELON_SLICE: Vector2(2.0, 0.0), ItemRegistry.MC_PUMPKIN_PIE: Vector2(8.0, 4.0),
        ItemRegistry.MC_COOKIE: Vector2(2.0, 0.0), ItemRegistry.MC_CAKE: Vector2(7.0, 3.0),
        ItemRegistry.MC_BEEF: Vector2(3.0, 1.0), ItemRegistry.MC_COOKED_BEEF: Vector2(8.0, 4.0),
        ItemRegistry.MC_CHICKEN: Vector2(2.0, 0.0), ItemRegistry.MC_COOKED_CHICKEN: Vector2(6.0, 3.0),
        ItemRegistry.MC_PORKCHOP: Vector2(3.0, 1.0), ItemRegistry.MC_COOKED_PORKCHOP: Vector2(8.0, 4.0),
        ItemRegistry.MC_MUTTON: Vector2(2.0, 1.0), ItemRegistry.MC_COOKED_MUTTON: Vector2(6.0, 3.0),
        ItemRegistry.MC_RABBIT: Vector2(3.0, 1.0), ItemRegistry.MC_COOKED_RABBIT: Vector2(5.0, 3.0),
        ItemRegistry.MC_COD: Vector2(2.0, 0.0), ItemRegistry.MC_COOKED_COD: Vector2(5.0, 2.0),
        ItemRegistry.MC_SALMON: Vector2(2.0, 0.0), ItemRegistry.MC_COOKED_SALMON: Vector2(6.0, 3.0)
    }
    var value: Vector2 = values.get(item_id, Vector2.ZERO)
    if value == Vector2.ZERO:
        return false
    hunger = minf(20.0, hunger + value.x)
    health = minf(max_health, health + value.y)
    health_changed.emit(health, max_health)
    stats_changed.emit()
    return true

func reset_after_death() -> void:
    health = max_health; hunger = 20.0; stamina = 20.0; air = 20.0
    health_changed.emit(health, max_health)
    stats_changed.emit()

func heal(amount: float) -> void:
    health = minf(max_health, health + amount)
    health_changed.emit(health, max_health)

func add_xp(amount: int) -> void:
    xp += maxi(0, amount)
    stats_changed.emit()