extends SceneTree

func _ready() -> void:
	var pm = Engine.get_singleton("PortfolioManager")
	var prev_level := UpgradeManager.get_level("owerview_credit_up")
	pm.credit_used = 0.0
	pm.credit_limit = 1000.0
	pm.credit_score = 700
	UpgradeManager.player_levels["owerview_credit_up"] = 1
	StatManager.recalculate_all_stats_once()
	pm._recalculate_credit_score()
	assert(pm.credit_score == 710)
	UpgradeManager.player_levels["owerview_credit_up"] = prev_level
	StatManager.recalculate_all_stats_once()
	pm._recalculate_credit_score()
	assert(pm.credit_score == 700)
	print("owerview_credit_up_upgrade_test passed")
	quit()
