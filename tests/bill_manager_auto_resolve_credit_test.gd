extends SceneTree

func _ready():
    var pm = Engine.get_singleton("PortfolioManager")
    var bm = Engine.get_singleton("BillManager")
    pm.reset()
    bm.reset()
    pm.credit_interest_rate = 0.0
    pm.cash = 0.0
    var popup = preload("res://components/popups/bill_popup_ui.tscn").instantiate()
    popup.bill_name = "TestBill"
    popup.amount = 100.0
    popup.date_key = "1/1/2000"
    add_child(popup)
    bm.register_popup(popup, "1/1/2000")
    bm.auto_resolve_bills_for_date("1/1/2000")
    assert(pm.credit_used == 100.0)
    print("bill_manager_auto_resolve_credit_test passed")
    quit()
