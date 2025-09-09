extends SceneTree

const FlexNumber = preload("res://flex_number.gd")

func _ready() -> void:
    var fn = FlexNumber.new(1.23e45)
    var pm = Engine.get_singleton("PlayerManager")
    pm.set_var("ex", fn)
    var saved = pm.get_save_data()
    assert(typeof(saved["ex"]) == TYPE_DICTIONARY)
    pm.set_var("ex", 0)
    pm.load_from_data(saved)
    var loaded = pm.get_var("ex")
    assert(typeof(loaded) == TYPE_OBJECT and loaded.get_class() == "FlexNumber")
    assert(is_equal_approx(loaded._mantissa, fn._mantissa))
    assert(loaded._exponent == fn._exponent)
    print("player_manager_flexnumber_roundtrip_test passed")
    quit()
