extends Node

func _ready():
		var pm = Engine.get_singleton("PortfolioManager")
		pm.credit_used = 0.0
		pm.credit_limit = 1000.0
		pm.credit_interest_rate = 0.0
		pm.cash = 0.0
		var bm = Engine.get_singleton("BillManager")
		bm.reset()
		var popup = preload("res://components/popups/bill_popup_ui.tscn").instantiate()
		popup.bill_name = "TestBill"
		popup.amount = 100.0
		popup.date_key = "1/1/2000"
		add_child(popup)
		popup._on_pay_by_credit_button_pressed()
		assert(pm.credit_used == 100.0)
		print("pay_with_credit_bill_test passed")
