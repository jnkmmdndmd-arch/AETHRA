extends Node

var recipes: Array[Dictionary] = [
    {"id":"plank_from_log","inputs":{"6":1},"output":{"8":4}},
    {"id":"workbench","inputs":{"8":4},"output":{"18":1}},
    {"id":"wood_pick","inputs":{"8":3,"6":2},"output":{"100":1}},
    {"id":"stone_pick","inputs":{"8":3,"2":3},"output":{"101":1}},
    {"id":"iron_pick","inputs":{"8":3,"12":3},"output":{"102":1}},
    {"id":"torch","inputs":{"6":1,"13":1},"output":{"22":4}},
    {"id":"stone_sword","inputs":{"8":2,"2":2},"output":{"131":1}},
    {"id":"iron_sword","inputs":{"8":2,"12":3},"output":{"132":1}},
    {"id":"camp_food","inputs":{"3":2,"50":1},"output":{"200":2}},
    {"id":"chest","inputs":{"8":8},"output":{"20":1}},
    {"id":"lantern","inputs":{"22":2,"13":1},"output":{"144":2}},

    {"id":"minecraft_sticks","inputs":{"8":2},"output":{"183":4}},
    {"id":"minecraft_wooden_pickaxe","inputs":{"8":3,"183":2},"output":{"100":1}},
    {"id":"minecraft_stone_pickaxe","inputs":{"2":3,"183":2},"output":{"101":1}},
    {"id":"minecraft_iron_pickaxe","inputs":{"176":3,"183":2},"output":{"102":1}},
    {"id":"minecraft_wooden_axe","inputs":{"8":3,"183":2},"output":{"110":1}},
    {"id":"minecraft_stone_axe","inputs":{"2":3,"183":2},"output":{"111":1}},
    {"id":"minecraft_iron_axe","inputs":{"176":3,"183":2},"output":{"112":1}},
    {"id":"minecraft_wooden_shovel","inputs":{"8":1,"183":2},"output":{"120":1}},
    {"id":"minecraft_stone_shovel","inputs":{"2":1,"183":2},"output":{"121":1}},
    {"id":"minecraft_iron_shovel","inputs":{"176":1,"183":2},"output":{"122":1}},
    {"id":"minecraft_wooden_sword","inputs":{"8":2,"183":1},"output":{"130":1}},
    {"id":"minecraft_stone_sword","inputs":{"2":2,"183":1},"output":{"131":1}},
    {"id":"minecraft_iron_sword","inputs":{"176":2,"183":1},"output":{"132":1}},
    {"id":"minecraft_bow","inputs":{"183":3,"184":3},"output":{"140":1}},
    {"id":"minecraft_arrow","inputs":{"187":1,"183":1,"185":1},"output":{"141":4}},
    {"id":"minecraft_bucket","inputs":{"176":3},"output":{"143":1}},
    {"id":"minecraft_shield","inputs":{"8":6,"176":1},"output":{"189":1}},
    {"id":"minecraft_flint_and_steel","inputs":{"176":1,"187":1},"output":{"191":1}},
    {"id":"minecraft_furnace","inputs":{"2":8},"output":{"19":1}},
    {"id":"minecraft_chest","inputs":{"8":8},"output":{"20":1}},
    {"id":"minecraft_crafting_table","inputs":{"8":4},"output":{"18":1}},
    {"id":"minecraft_torch","inputs":{"174":1,"183":1},"output":{"22":4}},
    {"id":"minecraft_coal_torch_from_charcoal","inputs":{"175":1,"183":1},"output":{"22":4}}
]
func find_recipe(recipe_id:String)->Dictionary:
    for recipe in recipes:
        if recipe.id==recipe_id: return recipe
    return {}
func can_craft(recipe_id:String, counts:Dictionary)->bool:
    var recipe:=find_recipe(recipe_id)
    if recipe.is_empty(): return false
    for key in recipe.inputs:
        if int(counts.get(int(key),0)) < int(recipe.inputs[key]): return false
    return true