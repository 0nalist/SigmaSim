extends SceneTree

const NPC = preload("res://components/npc/npc.gd")

func _ready() -> void:
    var npc_mgr = Engine.get_singleton("NPCManager")
    var db_mgr = Engine.get_singleton("DBManager")

    var npc1_idx := 10101
    var npc2_idx := 20202

    # Stub out database writes
    db_mgr.save_npc = func(_i, _n): pass

    var npc1 := NPC.new()
    npc1.relationship_stage = NPCManager.RelationshipStage.TALKING
    npc1.exclusivity_core = NPCManager.ExclusivityCore.MONOG

    var npc2 := NPC.new()
    npc2.relationship_stage = NPCManager.RelationshipStage.DATING
    npc2.exclusivity_core = NPCManager.ExclusivityCore.MONOG

    npc_mgr.npcs[npc1_idx] = npc1
    npc_mgr.persistent_npcs[npc1_idx] = {}
    npc_mgr.npcs[npc2_idx] = npc2
    npc_mgr.persistent_npcs[npc2_idx] = {}
    npc_mgr.daterbase_npcs = [npc2_idx]

    npc_mgr.set_relationship_stage(npc1_idx, NPCManager.RelationshipStage.DATING)

    assert(npc2.exclusivity_core == NPCManager.ExclusivityCore.CHEATING)
    print("dating_stage_signal_test passed")
    quit()

