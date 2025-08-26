extends SceneTree

func _ready() -> void:
    var save_mgr = Engine.get_singleton("SaveManager")
    var player_mgr = Engine.get_singleton("PlayerManager")
    save_mgr.reset_managers()
    save_mgr.current_slot_id = 1
    assert(player_mgr.get_var("hh_open_fumble_cost", 0) == 10)
    player_mgr.set_var("hh_open_fumble_cost", 40)
    save_mgr.save_to_slot(save_mgr.current_slot_id)
    save_mgr.reset_managers()
    save_mgr.load_from_slot(save_mgr.current_slot_id)
    assert(player_mgr.get_var("hh_open_fumble_cost", 0) == 40)
    print("hh_open_fumble_cost_persistence_test passed")
    quit()
