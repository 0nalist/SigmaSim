extends SceneTree

func _ready():
    var pm = Engine.get_singleton("PortfolioManager")
    var bm = Engine.get_singleton("BillManager")
    var tm = Engine.get_singleton("TimeManager")
    pm.reset()
    bm.reset()
    tm.reset()
    pm.credit_limit = 1000.0
    pm.credit_used = 0.0
    pm.credit_interest_rate = 0.0
    bm.add_debt_resource({
        "name": "Payday Loan",
        "balance": 0.0,
        "interest_rate": 0.0,
        "compound_interval": 1440,
        "compounds_in": 1440,
        "can_borrow": true,
        "borrow_limit": 1000.0
    })
    bm.take_payday_loan(100.0)
    tm._advance_time(1440)
    assert(bm.static_bill_amounts.get("Payday Loan", 0.0) == 100.0)
    var popup = preload("res://components/popups/bill_popup_ui.tscn").instantiate()
    popup.bill_name = "Payday Loan"
    popup.amount = bm.get_bill_amount("Payday Loan")
    popup.date_key = "%d/%d/%d" % [tm.current_day, tm.current_month, tm.current_year]
    add_child(popup)
    popup._on_pay_by_credit_button_pressed()
    var res = bm.get_debt_resources()[0]
    assert(res.get("balance") == 0.0)
    assert(pm.credit_used == 100.0)
    print("payday_loan_bill_credit_pay_test passed")
    quit()
