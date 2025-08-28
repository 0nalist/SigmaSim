extends SceneTree

func _ready():
    var bm = Engine.get_singleton("BillManager")
    var tm = Engine.get_singleton("TimeManager")
    bm.reset()
    tm.reset()
    bm.add_debt_resource({
        "name": "Credit Card",
        "balance": 0.0,
        "compound_interval": 7 * 1440,
        "compounds_in": 7 * 1440,
    })
    var res = bm.get_debt_resources()[0]
    assert(res.get("compound_interval") == 7 * 1440)
    assert(res.get("compounds_in") == 7 * 1440)
    var day = tm.current_day
    var month = tm.current_month
    var year = tm.current_year
    var expected := ""
    while true:
        var bills = bm.get_due_bills_for_date(day, month, year)
        if "Credit Card" in bills:
            var weekday = TimeManager.get_weekday_for_date(day, month, year)
            expected = "%s %d/%d/%d" % [TimeManager.day_names[weekday], day, month, year]
            break
        day += 1
        if day > TimeManager.get_days_in_month(month, year):
            day = 1
            month += 1
            if month > 12:
                month = 1
                year += 1
    var summary = bm.get_credit_summary()
    assert(summary.get("next_due") == expected)
    print("credit_card_next_due_test passed")
    quit()

