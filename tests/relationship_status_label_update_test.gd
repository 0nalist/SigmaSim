extends Node

const NPC = preload("res://components/npc/npc.gd")
const ExFactorViewScene = preload("res://components/popups/ex_factor_view.tscn")

func _ready() -> void:
	var npc_mgr = Engine.get_singleton("NPCManager")
	var db_mgr = Engine.get_singleton("DBManager")
	db_mgr.save_npc = func(_i, _n): pass
	npc_mgr.npcs = {}
	npc_mgr.persistent_npcs = {}
	npc_mgr.encountered_npcs = []

	var cases = [
		{
			"stage": NPCManager.RelationshipStage.TALKING,
			"core": NPCManager.ExclusivityCore.POLY,
			"expected": "You are TALKING to"
		},
		{
			"stage": NPCManager.RelationshipStage.DATING,
			"core": NPCManager.ExclusivityCore.POLY,
			"expected": "You are DATING"
		},
		{
			"stage": NPCManager.RelationshipStage.DATING,
			"core": NPCManager.ExclusivityCore.MONOG,
			"expected": "You are DATING EXCLUSIVELY"
		},
		{
			"stage": NPCManager.RelationshipStage.DATING,
			"core": NPCManager.ExclusivityCore.CHEATING,
			"expected": "You are DATING and CHEATING ON"
		},
		{
			"stage": NPCManager.RelationshipStage.SERIOUS,
			"core": NPCManager.ExclusivityCore.POLY,
			"expected": "You are SERIOUSLY DATING, POLYAMOROUSLY"
		},
		{
			"stage": NPCManager.RelationshipStage.SERIOUS,
			"core": NPCManager.ExclusivityCore.MONOG,
			"expected": "You are SERIOUSLY DATING, EXCLUSIVELY"
		},
		{
			"stage": NPCManager.RelationshipStage.SERIOUS,
			"core": NPCManager.ExclusivityCore.CHEATING,
			"expected": "You are SERIOUSLY DATING, and CHEATING ON"
		},
		{
			"stage": NPCManager.RelationshipStage.ENGAGED,
			"core": NPCManager.ExclusivityCore.POLY,
			"expected": "You are ENGAGED, and POLY with"
		},
		{
			"stage": NPCManager.RelationshipStage.ENGAGED,
			"core": NPCManager.ExclusivityCore.MONOG,
			"expected": "You are ENGAGED to"
		},
		{
			"stage": NPCManager.RelationshipStage.ENGAGED,
			"core": NPCManager.ExclusivityCore.CHEATING,
			"expected": "You are ENGAGED and CHEATING ON"
		},
		{
			"stage": NPCManager.RelationshipStage.MARRIED,
			"core": NPCManager.ExclusivityCore.POLY,
			"expected": "You are MARRIED, and POLY with"
		},
		{
			"stage": NPCManager.RelationshipStage.MARRIED,
			"core": NPCManager.ExclusivityCore.MONOG,
			"expected": "You are MARRIED to"
		},
		{
			"stage": NPCManager.RelationshipStage.MARRIED,
			"core": NPCManager.ExclusivityCore.CHEATING,
			"expected": "You are MARRIED and CHEATING ON"
		},
		{
			"stage": NPCManager.RelationshipStage.EX,
			"core": NPCManager.ExclusivityCore.POLY,
			"expected": "Your EX:"
		}
	]

	var idx := 1
	for c in cases:
		var npc := NPC.new()
		npc.relationship_stage = c.stage
		npc.exclusivity_core = c.core
		var npc_idx := 1000 + idx
		npc_mgr.npcs[npc_idx] = npc
		npc_mgr.persistent_npcs[npc_idx] = {}
		npc_mgr.encountered_npcs.append(npc_idx)
		var view := ExFactorViewScene.instantiate()
		add_child(view)
		view.setup_custom({"npc": npc, "npc_idx": npc_idx})
		await get_tree().process_frame
		assert(view.relationship_status_label.text == c.expected)
		view.queue_free()
		await get_tree().process_frame
		idx += 1
	print("relationship_status_label_update_test passed")
