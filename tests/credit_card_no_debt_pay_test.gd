extends SceneTree

func _ready():
	var pm = Engine.get_singleton("PortfolioManager")
	var bm = Engine.get_singleton("BillManager")
	pm.reset()
	bm.reset()
	bm.add_debt_resource({
		"name": "Credit Card",
		"balance": 0.0,
		"has_credit_limit": true,
		"credit_limit": pm.credit_limit
	})
	pm.credit_used = 0.0
	var card = preload("res://components/apps/ower_view/debt_card_ui.tscn").instantiate()
	add_child(card)
	card.init(bm.get_debt_resources()[0])
	card._on_pay_pressed()
	assert(pm.credit_used == 0.0)
	var res = bm.get_debt_resources()[0]
	assert(res.get("balance") == 0.0)
	print("credit_card_no_debt_pay_test passed")
	quit()

