extends SceneTree

func _ready():
	var pm = Engine.get_singleton("PortfolioManager")
	pm.reset()
	pm.credit_limit = 1000.0
	pm.credit_used = 0.0

	var bar = preload("res://components/apps/ower_view/credit_score_bar.gd").new()
	add_child(bar)
	await get_tree().process_frame

	pm.credit_used = 950.0
	await get_tree().process_frame

	assert(bar.current_score == pm.get_credit_score())
	print("credit_score_bar_updates_test passed")
	quit()
