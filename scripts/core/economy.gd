extends Node

signal wallet_changed(coins)
signal stash_changed(items)

const PATH := "user://aethra_wallet.json"
const DEFAULT_COINS := 250
const MAX_COINS := 2000000000
const SHOP := [
    {"name":"Sun Fruit", "item_id":ItemRegistry.HEAL_FOOD, "price":12, "amount":4},
    {"name":"Timber Pick", "item_id":ItemRegistry.WOOD_PICK, "price":80, "amount":1},
    {"name":"Stone Pick", "item_id":ItemRegistry.STONE_PICK, "price":150, "amount":1},
    {"name":"Iron Pick", "item_id":ItemRegistry.IRON_PICK, "price":300, "amount":1},
    {"name":"Torch Bundle", "item_id":BlockRegistry.TORCH, "price":25, "amount":8},
    {"name":"Plank Bundle", "item_id":BlockRegistry.PLANK, "price":20, "amount":16}
]
var coins := DEFAULT_COINS
var stash: Dictionary = {}

func _ready() -> void:
    load_wallet()

func _valid_trade_item(item_id: int) -> bool:
    if item_id > BlockRegistry.AIR and item_id <= BlockRegistry.LAST_BLOCK:
        return item_id not in [BlockRegistry.WATER, BlockRegistry.LAVA, BlockRegistry.BEDROCK]
    var item := ItemRegistry.get_item(item_id)
    return int(item.get("id", ItemRegistry.EMPTY)) == item_id and str(item.get("category", "none")) != "none"

func _sanitize_count(value: int) -> int:
    return clampi(value, 0, 999999)

func load_wallet() -> void:
    coins = DEFAULT_COINS
    stash = {}
    if not FileAccess.file_exists(PATH):
        save_wallet()
        return
    var file := FileAccess.open(PATH, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    if not (data is Dictionary):
        return
    coins = clampi(int(data.get("coins", DEFAULT_COINS)), 0, MAX_COINS)
    var raw = data.get("stash", {})
    if raw is Dictionary:
        for key in raw:
            var item_id := int(key)
            var amount := _sanitize_count(int(raw[key]))
            if amount > 0 and _valid_trade_item(item_id):
                stash[item_id] = amount
    wallet_changed.emit(coins)
    stash_changed.emit(stash.duplicate(true))

func save_wallet() -> void:
    var tmp := PATH + ".tmp"
    var file := FileAccess.open(tmp, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({"coins": coins, "stash": stash}))
    file.flush()
    var err := file.get_error()
    file.close()
    if err != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
        return
    var final_path := ProjectSettings.globalize_path(PATH)
    var tmp_path := ProjectSettings.globalize_path(tmp)
    if FileAccess.file_exists(final_path):
        DirAccess.remove_absolute(final_path)
    DirAccess.rename_absolute(tmp_path, final_path)

func add_coins(amount: int) -> int:
    if amount <= 0:
        return coins
    coins = mini(MAX_COINS, coins + amount)
    save_wallet()
    wallet_changed.emit(coins)
    return coins

func can_spend(amount: int) -> bool:
    return amount >= 0 and amount <= coins

func spend_coins(amount: int) -> bool:
    if amount <= 0 or amount > coins:
        return false
    coins -= amount
    save_wallet()
    wallet_changed.emit(coins)
    return true

func add_to_stash(item_id: int, amount: int) -> bool:
    if amount <= 0 or not _valid_trade_item(item_id):
        return false
    stash[item_id] = _sanitize_count(int(stash.get(item_id, 0)) + amount)
    save_wallet()
    stash_changed.emit(stash.duplicate(true))
    return true

func consume_stash_into_inventory(inventory) -> void:
    var remaining := {}
    for key in stash:
        var item_id := int(key)
        var amount := int(stash[key])
        var left: int = inventory.add_item(item_id, amount)
        if left > 0:
            remaining[item_id] = left
    stash = remaining
    save_wallet()
    stash_changed.emit(stash.duplicate(true))

func total_stash_items() -> int:
    var total := 0
    for key in stash:
        total += int(stash[key])
    return total

func purchase(item_id: int, amount: int, price: int) -> bool:
    if amount <= 0 or price <= 0 or not _valid_trade_item(item_id):
        return false
    if price > coins or amount > 999999:
        return false
    var previous := int(stash.get(item_id, 0))
    var new_count := previous + amount
    if new_count > 999999:
        return false
    coins -= price
    stash[item_id] = new_count
    save_wallet()
    wallet_changed.emit(coins)
    stash_changed.emit(stash.duplicate(true))
    return true

func shop_catalog() -> Array:
    return SHOP.duplicate(true)