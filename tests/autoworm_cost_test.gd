extends SceneTree

func _ready() -> void:
    var id := "earlybird_autoworm"
    var prev_level := UpgradeManager.get_level(id)
    UpgradeManager.player_levels[id] = 0
    var cost1 := UpgradeManager.get_cost_for_next_level(id).get("ex", -1)
    UpgradeManager.player_levels[id] = 1
    var cost2 := UpgradeManager.get_cost_for_next_level(id).get("ex", -1)
    UpgradeManager.player_levels[id] = 2
    var cost3 := UpgradeManager.get_cost_for_next_level(id).get("ex", -1)
    assert(cost1 == 100)
    assert(cost2 == 200)
    assert(cost3 == 400)
    UpgradeManager.player_levels[id] = prev_level
    print("autoworm_cost_test passed")
    quit()
