extends SceneTree

func _ready():
    var tm_script = load("res://autoloads/time_manager.gd")
    var tm = tm_script.new()
    tm.day_of_week = 1  # intentionally incorrect
    var formatted = tm.get_formatted_date()
    var expected_weekday = tm.day_names[tm.get_weekday_for_date(tm.current_day, tm.current_month, tm.current_year)]
    var expected = "%s %d/%d/%d" % [expected_weekday, tm.current_day, tm.current_month, tm.current_year]
    assert(formatted == expected)
    print("time_manager_formatted_date_sync_test passed")
    quit()
