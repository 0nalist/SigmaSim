extends SceneTree

func _ready() -> void:
    var save_mgr = Engine.get_singleton("SaveManager")
    var npc_mgr = Engine.get_singleton("NPCManager")

    save_mgr.reset_managers()
    save_mgr.current_slot_id = 1

    var npc_id := 4242
    npc_mgr.get_npc_by_index(npc_id)
    npc_mgr.add_romantic_npc(npc_id)

    save_mgr.save_to_slot(save_mgr.current_slot_id)
    save_mgr.reset_managers()
    save_mgr.load_from_slot(save_mgr.current_slot_id)

    assert(npc_mgr.get_romantic_npcs().has(npc_id))
    print("romantic_relationship_persistence_test passed")
    quit()
