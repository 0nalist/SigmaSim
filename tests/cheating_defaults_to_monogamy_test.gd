extends SceneTree

const NPC = preload("res://components/npc/npc.gd")

func _ready() -> void:
    var npc_mgr = Engine.get_singleton("NPCManager")
    var db_mgr = Engine.get_singleton("DBManager")
    db_mgr.save_npc = func(_i, _n): pass
    npc_mgr.npcs = {}
    npc_mgr.persistent_npcs = {}
    npc_mgr.encountered_npcs = []

    var npc1_idx := 10101
    var npc2_idx := 20202

    var npc1 := NPC.new()
    npc1.relationship_stage = NPCManager.RelationshipStage.DATING
    npc1.exclusivity_core = NPCManager.ExclusivityCore.MONOG

    var npc2 := NPC.new()
    npc2.relationship_stage = NPCManager.RelationshipStage.DATING
    npc2.exclusivity_core = NPCManager.ExclusivityCore.MONOG

    npc_mgr.npcs[npc1_idx] = npc1
    npc_mgr.persistent_npcs[npc1_idx] = {}
    npc_mgr.npcs[npc2_idx] = npc2
    npc_mgr.persistent_npcs[npc2_idx] = {}
    npc_mgr.encountered_npcs = [npc1_idx, npc2_idx]

    npc_mgr.notify_player_advanced_someone_to_dating(npc2_idx)
    await get_tree().process_frame
    assert(npc1.exclusivity_core == NPCManager.ExclusivityCore.CHEATING)

    npc2.relationship_stage = NPCManager.RelationshipStage.EX
    npc_mgr._check_cheating_after_breakup()
    await get_tree().process_frame
    assert(npc1.exclusivity_core == NPCManager.ExclusivityCore.MONOG)
    print("cheating_defaults_to_monogamy_test passed")
    quit()
