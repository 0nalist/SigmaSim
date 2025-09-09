extends SceneTree

const FlexNumber = preload("res://flex_number.gd")

func _ready() -> void:
    var stat_mgr = Engine.get_singleton("StatManager")
    stat_mgr.reset()
    var fn = FlexNumber.new(1.23e45)
    stat_mgr.set_base_stat("flex_demo_stat", fn)
    var saved = stat_mgr.get_save_data()
    assert(typeof(saved["flex_demo_stat"]) == TYPE_DICTIONARY)
    stat_mgr.set_base_stat("flex_demo_stat", 0.0)
    stat_mgr.load_from_data(saved)
    var loaded = stat_mgr.get_stat("flex_demo_stat")
    assert(typeof(loaded) == TYPE_OBJECT and loaded.get_class() == "FlexNumber")
    assert(is_equal_approx(loaded._mantissa, fn._mantissa))
    assert(loaded._exponent == fn._exponent)
    print("stat_manager_flexnumber_auto_detection_test passed")
    quit()
