extends SceneTree

func _ready() -> void:
    var save_mgr = Engine.get_singleton("SaveManager")
    var db_mgr = Engine.get_singleton("DBManager")
    var npc_mgr = Engine.get_singleton("NPCManager")

    save_mgr.reset_managers()
    save_mgr.current_slot_id = 1
    # clear existing NPC rows for slot
    db_mgr.db.query("DELETE FROM npc WHERE slot_id = %d" % save_mgr.current_slot_id)

    var npc1 := NPC.new()
    npc1.relationship_stage = NPCManager.RelationshipStage.DATING
    db_mgr.save_npc(1, npc1, save_mgr.current_slot_id)
    var npc2 := NPC.new()
    npc2.relationship_stage = NPCManager.RelationshipStage.DATING
    db_mgr.save_npc(2, npc2, save_mgr.current_slot_id)

    save_mgr.save_to_slot(save_mgr.current_slot_id)
    save_mgr.load_from_slot(save_mgr.current_slot_id)

    var encountered := npc_mgr.encountered_npcs
    assert(encountered.has(1))
    assert(encountered.has(2))
    print("npc_encounter_reload_test passed")
    quit()

