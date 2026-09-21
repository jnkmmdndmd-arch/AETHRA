extends RefCounted

func craft(inventory, recipe_id: String) -> bool:
    var recipe := RecipeRegistry.find_recipe(recipe_id)
    if recipe.is_empty():
        return false
    for key in recipe.inputs:
        var item_id := int(key)
        if inventory.count_item(item_id) < int(recipe.inputs[key]):
            return false
    var output: Dictionary = recipe.output
    if not inventory.can_add_items(output):
        return false
    var before := inventory.serialize()
    for key in recipe.inputs:
        if not inventory.remove_item(int(key), int(recipe.inputs[key])):
            inventory.deserialize(before)
            return false
    for key in output:
        var remaining: int = inventory.add_item(int(key), int(output[key]))
        if remaining > 0:
            inventory.deserialize(before)
            return false
    return true