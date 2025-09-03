extends SceneTree

func _ready():
    # Simulate uninitialised NameManager pools
    NameManager.first_names.clear()
    NameManager.last_names.clear()
    NameManager.middle_initials.clear()
    var data = NameManager.get_npc_name_by_index(0)
    var full_name: String = data["full_name"]
    var re := RegEx.new()
    re.compile(" [IVXLCDM]+$")
    assert(re.search(full_name) == null)
    print("name_manager_roman_suffix_test passed")
    quit()
