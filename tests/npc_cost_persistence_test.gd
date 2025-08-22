extends SceneTree

func _ready() -> void:
    var save_mgr = Engine.get_singleton("SaveManager")
    var db_mgr = Engine.get_singleton("DBManager")
    var npc_mgr = Engine.get_singleton("NPCManager")

    save_mgr.reset_managers()
    save_mgr.current_slot_id = 1

    var npc_id := 9999
    db_mgr.db.query("DELETE FROM npc WHERE id = %d AND slot_id = %d" % [npc_id, save_mgr.current_slot_id])

    var npc := NPC.new()
    npc.gift_cost = 25.0
    npc.date_cost = 200.0
    db_mgr.save_npc(npc_id, npc, save_mgr.current_slot_id)

    npc_mgr.npcs[npc_id] = npc
    npc_mgr.persistent_npcs[npc_id] = {}
    npc_mgr.set_npc_field(npc_id, "gift_cost", 50.0)
    npc_mgr.set_npc_field(npc_id, "date_cost", 400.0)
    npc_mgr._flush_save_queue()

    npc_mgr.npcs.erase(npc_id)
    var loaded := db_mgr.load_npc(npc_id, save_mgr.current_slot_id)
    assert(loaded.gift_cost == 50.0)
    assert(loaded.date_cost == 400.0)
    print("npc_cost_persistence_test passed")
    quit()
