extends Node

var recipes: Array[Dictionary] = [
    {"id": "plank_from_log", "inputs": {"6": 1}, "output": {"8": 4}},
    {"id": "workbench", "inputs": {"8": 4}, "output": {"18": 1}},
    {"id": "wood_pick", "inputs": {"8": 3, "6": 2}, "output": {"100": 1}},
    {"id": "stone_pick", "inputs": {"8": 3, "2": 3}, "output": {"101": 1}},
    {"id": "iron_pick", "inputs": {"8": 3, "12": 3}, "output": {"102": 1}},
    {"id": "torch", "inputs": {"6": 1, "13": 1}, "output": {"22": 4}},
]

func find_recipe(recipe_id: String) -> Dictionary:
    for recipe in recipes:
        if recipe.id == recipe_id:
            return recipe
    return {}

func can_craft(recipe_id: String, counts: Dictionary) -> bool:
    var recipe := find_recipe(recipe_id)
    if recipe.is_empty():
        return false
    for key in recipe.inputs:
        if int(counts.get(int(key), 0)) < int(recipe.inputs[key]):
            return false
    return true
