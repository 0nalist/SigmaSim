extends SceneTree

func _ready() -> void:
    var below := NumberFormatter.format_commas(999.99, 2)
    assert(below == "999.99")
    var above := NumberFormatter.format_commas(1000.12, 2)
    assert(above == "1,000")
    print("number_formatter_format_commas_test passed")
    quit()
