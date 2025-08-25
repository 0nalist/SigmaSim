extends SceneTree

func _ready() -> void:
    var save_mgr = Engine.get_singleton("SaveManager")
    var db_mgr = Engine.get_singleton("DBManager")
    var npc_mgr = Engine.get_singleton("NPCManager")

    save_mgr.reset_managers()
    save_mgr.current_slot_id = 1

    var npc_id := 4242
    db_mgr.db.query("DELETE FROM fumble_battles WHERE npc_id = %d AND slot_id = %d" % [npc_id, save_mgr.current_slot_id])
    db_mgr.save_fumble_battle("test_%s" % str(Time.get_unix_time_from_system()), npc_id, [], {}, {}, "victory", save_mgr.current_slot_id)

    npc_mgr.load_daterbase_cache()
    assert(npc_mgr.get_daterbase_npcs().has(npc_id))

    save_mgr.save_to_slot(save_mgr.current_slot_id)
    save_mgr.reset_managers()
    save_mgr.load_from_slot(save_mgr.current_slot_id)

    assert(npc_mgr.get_daterbase_npcs().has(npc_id))
    print("daterbase_persistence_test passed")
    quit()
