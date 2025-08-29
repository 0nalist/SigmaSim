extends SceneTree

func _ready():
    var pm = Engine.get_singleton("PortfolioManager")
    var bm = Engine.get_singleton("BillManager")
    var tm = Engine.get_singleton("TimeManager")
    pm.reset()
    bm.reset()
    tm.reset()
    bm.add_debt_resource({
        "name": "Credit Card",
        "balance": 100.0,
        "interest_rate": 0.1,
    })
    var res = bm.get_debt_resources()[0]
    assert(res.get("compounds_in") == 7 * 1440)
    tm._advance_time(6 * 1440)
    res = bm.get_debt_resources()[0]
    assert(res.get("balance") == 100.0)
    assert(res.get("compounds_in") == 1440)
    tm._advance_time(1440)
    res = bm.get_debt_resources()[0]
    assert(res.get("balance") == 110.0)
    assert(res.get("compounds_in") == 7 * 1440)
    print("credit_card_interest_reset_test passed")
    quit()
