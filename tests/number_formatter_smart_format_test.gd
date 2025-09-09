extends SceneTree

func _ready() -> void:
    var small := NumberFormatter.smart_format(999.99)
    assert(small == "999.99")
    var big := NumberFormatter.smart_format(1234000000.0)
    assert(big == "1.23e9")
    var flex := FlexNumber.new(1234000000.0)
    var flex_str := NumberFormatter.smart_format(flex)
    assert(flex_str == "1.23e9")
    var inf := INF
    var inf_str := NumberFormatter.smart_format(inf)
    assert(inf_str == "∞")
    print("number_formatter_smart_format_test passed")
    quit()
