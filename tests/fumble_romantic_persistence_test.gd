extends SceneTree

func _ready() -> void:
    var save_mgr = Engine.get_singleton("SaveManager")
    var npc_mgr = Engine.get_singleton("NPCManager")
    var db_mgr = Engine.get_singleton("DBManager")
    var fumble_mgr = Engine.get_singleton("FumbleManager")

    save_mgr.reset_managers()
    save_mgr.current_slot_id = 1

    var npc_id := 6060
    npc_mgr.get_npc_by_index(npc_id)
    db_mgr.save_fumble_battle("battle_test", npc_id, [], {}, {}, "active")

    fumble_mgr.save_battle_state("battle_test", [], {}, {}, "victory")

    save_mgr.save_to_slot(save_mgr.current_slot_id)
    save_mgr.reset_managers()
    save_mgr.load_from_slot(save_mgr.current_slot_id)

    assert(npc_mgr.has_romantic_relationship(npc_id))
    print("fumble_romantic_persistence_test passed")
    quit()
