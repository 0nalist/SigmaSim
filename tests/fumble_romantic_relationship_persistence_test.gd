extends SceneTree

func _ready() -> void:
    var save_mgr = Engine.get_singleton("SaveManager")
    var npc_mgr = Engine.get_singleton("NPCManager")
    var fumble_mgr = Engine.get_singleton("FumbleManager")

    save_mgr.reset_managers()
    save_mgr.current_slot_id = 1

    var npc_id := 4343
    var battle_id := fumble_mgr.start_battle(npc_id)
    npc_mgr.npcs = {}

    fumble_mgr.save_battle_state(battle_id, [], {}, {}, "victory")

    save_mgr.save_to_slot(save_mgr.current_slot_id)
    save_mgr.reset_managers()
    save_mgr.load_from_slot(save_mgr.current_slot_id)

    assert(npc_mgr.get_romantic_npcs().has(npc_id))
    print("fumble_romantic_relationship_persistence_test passed")
    quit()
