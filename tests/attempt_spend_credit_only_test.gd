extends Node

func _ready():
	var pm = Engine.get_singleton("PortfolioManager")
	pm.reset()
	pm.cash = 100.0
	pm.credit_limit = 1000.0
	pm.credit_used = 0.0
	pm.credit_interest_rate = 0.0
	var ok = pm.attempt_spend(50.0, 0, true, true)
	assert(ok)
	assert(pm.cash == 100.0)
	assert(pm.credit_used == 50.0)
	print("attempt_spend_credit_only_test passed")
