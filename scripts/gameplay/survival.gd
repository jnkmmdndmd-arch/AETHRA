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

func consume_food(item_id: int) -> bool:
    if item_id != ItemRegistry.HEAL_FOOD or game_mode == "creative":
        return false
    hunger = minf(20.0, hunger + 6.0)
    health = minf(max_health, health + 3.0)
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