extends SceneTree

func _ready():
    var bm = Engine.get_singleton("BillManager")
    var tm = Engine.get_singleton("TimeManager")
    bm.reset()
    tm.reset()
    bm.add_debt_resource({
        "name": "Timed Debt",
        "balance": 0.0,
        "compounds_in": 90,
        "compound_interval": 90,
    })
    var res = bm.get_debt_resources()[0]
    assert(res.get("compound_interval") == 90)
    assert(res.get("compounds_in") == 90)
    tm._advance_time(60)
    res = bm.get_debt_resources()[0]
    assert(res.get("compounds_in") == 30)
    tm._advance_time(30)
    res = bm.get_debt_resources()[0]
    assert(res.get("compounds_in") == res.get("compound_interval"))
    print("debt_time_tickdown_test passed")
    quit()
