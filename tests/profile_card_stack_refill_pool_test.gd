extends Node

func _ready() -> void:
		RNGManager.init_seed(0)
		NPCCatalog.generate(50)
		var npc_manager = Engine.get_singleton("NPCManager")
		npc_manager.encountered_npcs = []
		npc_manager.encounter_count = 0

		var pcs := ProfileCardStack.new()
		pcs.profile_card_scene = PackedScene.new()
		pcs.swipe_pool_size = 5
		add_child(pcs)

		await pcs._refill_swipe_pool_async()
		assert(pcs.swipe_pool.size() == pcs.swipe_pool_size)

		print("profile_card_stack_refill_pool_test passed")
