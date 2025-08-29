extends SceneTree

func _ready():
    var bm = Engine.get_singleton("BillManager")
    var tm = Engine.get_singleton("TimeManager")
    bm.reset()
    tm.reset()
    bm.add_debt_resource({
        "name": "Test Debt",
        "balance": 0.0,
        "compounds_in": 5 * 1440,
        "compound_interval": 5 * 1440,
    })
    var res = bm.get_debt_resources()[0]
    assert(res.get("compound_interval") == 5 * 1440)
    assert(res.get("compounds_in") == 5 * 1440)
    tm._advance_time(1440)
    res = bm.get_debt_resources()[0]
    assert(res.get("compounds_in") == 4 * 1440)
    tm._advance_time(4 * 1440)
    res = bm.get_debt_resources()[0]
    assert(res.get("compounds_in") == res.get("compound_interval"))
    print("debt_days_tickdown_test passed")
    quit()

