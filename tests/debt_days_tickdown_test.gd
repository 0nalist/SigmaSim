extends SceneTree

func _ready():
	var bm = Engine.get_singleton("BillManager")
	var tm = Engine.get_singleton("TimeManager")
	bm.reset()
	tm.reset()
	bm.add_debt_resource({
		"name": "Test Debt",
		"balance": 0.0,
		"days_until_due": 5
	})
	tm._advance_time(1440)
	var res = bm.get_debt_resources()[0]
	assert(res.get("days_until_due") == 4)
	print("debt_days_tickdown_test passed")
	quit()

