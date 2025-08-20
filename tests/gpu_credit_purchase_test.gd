extends SceneTree

func _ready():
	var pm = Engine.get_singleton("PortfolioManager")
	var gm = Engine.get_singleton("GPUManager")
	pm.cash = 400.0
	pm.credit_used = 0.0
	pm.credit_limit = 700.0
	pm.credit_interest_rate = 0.0
	pm.credit_score = 700
	gm.current_gpu_price = 600.0
	gm.gpu_credit_requirement = 700
	var result = gm.buy_gpu()
	assert(result)
	print("gpu_credit_purchase_test passed")
	quit()
