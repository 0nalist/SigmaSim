extends SceneTree

func _ready():
    var bm = Engine.get_singleton("BillManager")
    bm.reset()
    var tm = Engine.get_singleton("TimeManager")
    tm.reset()
    # Advance one full day to trigger day_passed
    tm._advance_time(24 * 60)
    var date_key = "%d/%d/%d" % [tm.current_day, tm.current_month, tm.current_year]
    assert(bm.active_bills.has(date_key))
    assert(bm.active_bills[date_key].size() > 0)
    print("bill_manager_day_passed_popup_test passed")
    quit()

