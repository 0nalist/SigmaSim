extends SceneTree

func _ready():
    var pm = Engine.get_singleton("PortfolioManager")
    var bm = Engine.get_singleton("BillManager")
    pm.reset()
    bm.reset()
    bm.add_debt_resource({
        "name": "Payday Loan",
        "balance": 0.0,
        "has_credit_limit": false,
        "credit_limit": 0.0,
        "interest_rate": 0.8,
        "can_borrow": true,
        "borrow_limit": 1000.0
    })
    bm.take_payday_loan(100.0)
    assert(pm.cash == 100.0)
    var res = bm.get_debt_resources()[0]
    assert(res.get("balance") == 180.0)
    print("payday_loan_interest_test passed")
    quit()
