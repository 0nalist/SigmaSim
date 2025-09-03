extends SceneTree

func _ready():
        RNGManager.init_seed(0)
        PlayerManager.reset()
        PlayerManager.generate_friend1()
        var idx = PlayerManager.user_data["friend1_npc_index"]
        var total = NameManager.get_unique_name_count()
        assert(idx < total)
        var full_name: String = NameManager.get_npc_name_by_index(idx)["full_name"]
        var re := RegEx.new()
        re.compile(" [IVXLCDM]+$")
        assert(re.search(full_name) == null)
        print("friend1_name_no_suffix_test passed")
        quit()
