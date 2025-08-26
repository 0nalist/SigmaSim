extends SceneTree

func _ready() -> void:
    var parsed := MarkupParser.parse("Hello {randomfirstname}", null)
    assert(parsed.find("{randomfirstname}") == -1)
    assert(parsed != "Hello FirstName")
    assert(parsed != "Hello ?")
    print("randomfirstname_parse_test passed")
    quit()
