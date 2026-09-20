extends RefCounted

signal changed
const SLOTS := 36
var slots: Array[Dictionary] = []
var selected := 0

func _init() -> void:
    for _i in SLOTS:
        slots.append({"item": ItemRegistry.EMPTY, "count": 0, "durability": 0})


func _item_info(item_id: int) -> Dictionary:
    var info := ItemRegistry.get_item(item_id)
    if int(info.get("id", ItemRegistry.EMPTY)) == item_id:
        return info
    return info

func _is_valid_item_id(item_id: int) -> bool:
    if item_id == ItemRegistry.EMPTY:
        return true
    if item_id > BlockRegistry.AIR and item_id <= BlockRegistry.SNOW:
        return item_id not in [BlockRegistry.WATER, BlockRegistry.LAVA, BlockRegistry.BEDROCK]
    var info := ItemRegistry.get_item(item_id)
    return int(info.get("id", ItemRegistry.EMPTY)) == item_id and str(info.get("category", "none")) != "none"

func _stack_size_for(item_id: int) -> int:
    if item_id > BlockRegistry.AIR and item_id <= BlockRegistry.SNOW and _is_valid_item_id(item_id):
        return 64
    var info := ItemRegistry.get_item(item_id)
    if int(info.get("id", ItemRegistry.EMPTY)) == item_id and str(info.get("category", "none")) != "none":
        return maxi(1, int(info.get("stack", 1)))
    return 1

func can_add_item(item_id: int, amount: int) -> bool:
    if amount == 0:
        return true
    if amount < 0 or not _is_valid_item_id(item_id):
        return false
    var remaining := amount
    var stack_size := _stack_size_for(item_id)
    for slot in slots:
        if int(slot.item) == item_id:
            remaining -= mini(remaining, stack_size - int(slot.count))
            if remaining <= 0:
                return true
    for slot in slots:
        if int(slot.item) == ItemRegistry.EMPTY or int(slot.count) <= 0:
            remaining -= mini(remaining, stack_size)
            if remaining <= 0:
                return true
    return false

func can_add_items(items: Dictionary) -> bool:
    var simulated := slots.duplicate(true)
    for item_id_key in items:
        var item_id := int(item_id_key)
        var amount := int(items[item_id_key])
        if amount <= 0:
            continue
        if not _can_add_to_slots(simulated, item_id, amount):
            return false
    return true

func _can_add_to_slots(simulated: Array, item_id: int, amount: int) -> bool:
    if amount <= 0 or not _is_valid_item_id(item_id):
        return amount == 0
    var remaining := amount
    var stack_size := _stack_size_for(item_id)
    for slot in simulated:
        if int(slot.item) == item_id and int(slot.count) < stack_size:
            var moved := mini(remaining, stack_size - int(slot.count))
            slot.count += moved
            remaining -= moved
            if remaining <= 0:
                return true
    for slot in simulated:
        if int(slot.item) == ItemRegistry.EMPTY or int(slot.count) <= 0:
            var moved := mini(remaining, stack_size)
            slot.item = item_id
            slot.count = moved
            slot.durability = int(ItemRegistry.get_item(item_id).get("durability", 0))
            remaining -= moved
            if remaining <= 0:
                return true
    return false

func add_item(item_id: int, amount: int = 1) -> int:
    if amount < 0 or not _is_valid_item_id(item_id):
        return 0
    if amount == 0:
        return 0
    var remaining := amount
    var info := ItemRegistry.get_item(item_id)
    var stack_size := _stack_size_for(item_id)
    for slot in slots:
        if int(slot.item) == item_id and int(slot.count) < stack_size:
            var moved := mini(remaining, stack_size - int(slot.count))
            slot.count += moved
            remaining -= moved
            if remaining <= 0:
                changed.emit()
                return 0
    for slot in slots:
        if int(slot.item) == ItemRegistry.EMPTY or int(slot.count) <= 0:
            var moved := mini(remaining, stack_size)
            slot.item = item_id
            slot.count = moved
            slot.durability = int(info.get("durability", 0))
            remaining -= moved
            if remaining <= 0:
                changed.emit()
                return 0
    changed.emit()
    return remaining

func remove_item(item_id: int, amount: int) -> bool:
    if amount < 0 or not _is_valid_item_id(item_id):
        return false
    if amount == 0:
        return true
    if count_item(item_id) < amount:
        return false
    var remaining := amount
    for slot in slots:
        if int(slot.item) != item_id:
            continue
        var used := mini(remaining, int(slot.count))
        slot.count -= used
        remaining -= used
        if slot.count <= 0:
            slot.item = ItemRegistry.EMPTY
            slot.count = 0
            slot.durability = 0
        if remaining <= 0:
            changed.emit()
            return true
    return false

func count_item(item_id: int) -> int:
    var total := 0
    for slot in slots:
        if int(slot.item) == item_id:
            total += int(slot.count)
    return total

func get_hotbar() -> Array[Dictionary]:
    return slots.slice(0, 9)

func serialize() -> Array:
    return slots.duplicate(true)

func deserialize(data: Array) -> void:
    slots.clear()
    for item in data:
        if not (item is Dictionary):
            continue
        var item_id := int(item.get("item", ItemRegistry.EMPTY))
        var valid_item: bool = _is_valid_item_id(item_id)
        if not valid_item:
            item_id = ItemRegistry.EMPTY
        var count := clampi(int(item.get("count", 0)), 0, _stack_size_for(item_id))
        if item_id == ItemRegistry.EMPTY:
            count = 0
        slots.append({"item": item_id, "count": count, "durability": maxi(0, int(item.get("durability", 0)))})
        if slots.size() >= SLOTS:
            break
    while slots.size() < SLOTS:
        slots.append({"item": ItemRegistry.EMPTY, "count": 0, "durability": 0})
    changed.emit()
