extends SceneTree

func _ready() -> void:
    var parsed1 := MarkupParser.parse("Hello {randomfirstname}", null)
    assert(parsed1.find("{randomfirstname}") == -1)
    assert(parsed1 != "Hello FirstName")
    assert(parsed1 != "Hello ?")

    var parsed2 := MarkupParser.parse("Hello {random_first_name}", null)
    assert(parsed2.find("{random_first_name}") == -1)
    assert(parsed2 != "Hello FirstName")
    assert(parsed2 != "Hello ?")
    print("random firstname variants parse test passed")
    quit()
