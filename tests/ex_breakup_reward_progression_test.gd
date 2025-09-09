extends Node

const NPC = preload("res://components/npc/npc.gd")
const ExFactorLogic = preload("res://components/popups/ex_factor_logic.gd")

# RelationshipStage.MARRIED = 5 to avoid loading NPCManager in test
const MARRIED_STAGE: int = 5

func _ready() -> void:
        var npc := NPC.new()
        npc.relationship_stage = MARRIED_STAGE
        npc.relationship_progress.set_value(999999.0)
        var logic := ExFactorLogic.new()
        logic.npc = npc
        var reward_before := logic.preview_breakup_reward()
        npc.relationship_progress.set_value(1000000.0)
        var reward_after := logic.preview_breakup_reward()
        assert(reward_after >= reward_before)
        npc.relationship_progress.set_value(10000000.0)
        var reward_level3 := logic.preview_breakup_reward()
        assert(reward_level3 >= reward_after)
        print("ex_breakup_reward_progression_test passed")
