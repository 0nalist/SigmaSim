extends SceneTree

func _ready() -> void:
    RNGManager.init_seed(0)
    NPCCatalog.generate(20)
    var npc_manager = Engine.get_singleton("NPCManager")
    npc_manager.encountered_npcs = []
    npc_manager.encounter_count = 0
    npc_manager.encountered_npcs_by_app.clear()
    npc_manager.active_npcs_by_app.clear()
    npc_manager.matched_npcs_by_app.clear()
    PlayerManager.set_var("fumble_fugly_filter_threshold", 1.1)
    var stack = ProfileCardStack.new()
    stack.app_name = "fumble"
    stack.swipe_pool_size = 5
    await stack._refill_swipe_pool_async()
    assert(stack.swipe_pool.is_empty())
    print("fugly_filter_next_batch_test passed")
    quit()
