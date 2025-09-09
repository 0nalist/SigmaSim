extends SceneTree

func _ready() -> void:
    var below := NumberFormatter.smart_format(500_000_000)
    assert(below == "500,000,000")
    var above := NumberFormatter.smart_format(1_234_567_890)
    assert(above == "1.23e9")
    print("number_formatter_smart_format_test passed")
    quit()
