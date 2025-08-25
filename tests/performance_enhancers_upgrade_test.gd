extends SceneTree

func _ready() -> void:
		var prev_level := UpgradeManager.get_level("ex_factor_performance_enhancers")
		UpgradeManager.player_levels["ex_factor_performance_enhancers"] = 2
		StatManager.recalculate_all_stats_once()
		var npc := NPC.new()
		npc.affinity = 0.0
		var logic := ExFactorLogic.new()
		#logic.setup(npc)
		#logic.apply_love()
		assert(npc.affinity == 7.0)
		UpgradeManager.player_levels["ex_factor_performance_enhancers"] = prev_level
		StatManager.recalculate_all_stats_once()
		print("performance_enhancers_upgrade_test passed")
		quit()
