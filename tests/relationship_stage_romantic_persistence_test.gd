extends SceneTree

func _ready() -> void:
    var save_mgr = Engine.get_singleton("SaveManager")
    var npc_mgr = Engine.get_singleton("NPCManager")

    save_mgr.reset_managers()
    save_mgr.current_slot_id = 1

    var npc_id := 5050
    npc_mgr.get_npc_by_index(npc_id)

    npc_mgr.set_relationship_stage(npc_id, NPCManager.RelationshipStage.DATING)

    save_mgr.save_to_slot(save_mgr.current_slot_id)
    save_mgr.reset_managers()
    save_mgr.load_from_slot(save_mgr.current_slot_id)

    assert(npc_mgr.has_romantic_relationship(npc_id))
    print("relationship_stage_romantic_persistence_test passed")
    quit()
