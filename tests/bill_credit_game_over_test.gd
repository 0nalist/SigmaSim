extends SceneTree

func _ready():
    var pm = Engine.get_singleton("PortfolioManager")
    pm.reset()
    pm.credit_used = 0.0
    pm.credit_limit = 100.0
    pm.credit_interest_rate = 0.0
    pm.cash = 50.0
    pm.credit_score = 800

    var bm = Engine.get_singleton("BillManager")
    bm.reset()

    var gm = Engine.get_singleton("GameManager")
    var game_over := false
    gm.game_over_triggered.connect(func(_reason): game_over = true)

    var popup = preload("res://components/popups/bill_popup_ui.tscn").instantiate()
    popup.bill_name = "TestBill"
    popup.amount = 120.0
    popup.date_key = "1/1/2000"
    add_child(popup)
    bm.register_popup(popup, popup.date_key)

    bm.auto_resolve_bills_for_date(popup.date_key)

    assert(pm.cash == 0.0)
    assert(pm.credit_used == 70.0)
    assert(!game_over)
    print("bill_credit_game_over_test passed")
    quit()
