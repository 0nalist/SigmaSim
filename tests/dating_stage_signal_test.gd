extends SceneTree

const NPC = preload("res://components/npc/npc.gd")

func _ready() -> void:
    var save_mgr = Engine.get_singleton("SaveManager")
    save_mgr.reset_managers()
    save_mgr.current_slot_id = 1
    var npc_mgr = Engine.get_singleton("NPCManager")

    var a_idx := 1
    var b_idx := 2
    var npc_a := NPC.new()
    npc_a.relationship_stage = NPCManager.RelationshipStage.TALKING
    var npc_b := NPC.new()
    npc_b.relationship_stage = NPCManager.RelationshipStage.DATING
    npc_b.exclusivity_core = NPCManager.ExclusivityCore.MONOG
    npc_mgr.npcs[a_idx] = npc_a
    npc_mgr.persistent_npcs[a_idx] = {}
    npc_mgr.npcs[b_idx] = npc_b
    npc_mgr.persistent_npcs[b_idx] = {}
    npc_mgr.daterbase_npcs = [b_idx]
    npc_mgr.encountered_npcs = [a_idx, b_idx]

    var triggered := false
    npc_mgr.player_started_dating.connect(func(idx):
        if idx == a_idx:
            triggered = true
    )

    npc_mgr.set_relationship_stage(a_idx, NPCManager.RelationshipStage.DATING)
    assert(triggered)
    var other_npc: NPC = npc_mgr.get_npc_by_index(b_idx)
    assert(other_npc.exclusivity_core == NPCManager.ExclusivityCore.CHEATING)
    print("dating_stage_signal_test passed")
    quit()
