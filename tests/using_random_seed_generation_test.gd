extends SceneTree

func _ready():
    var stat_mgr = Engine.get_singleton("StatManager")
    var player_mgr = Engine.get_singleton("PlayerManager")
    var save_mgr = Engine.get_singleton("SaveManager")

    stat_mgr.reset()
    player_mgr.reset()

    var user_data = player_mgr.user_data.duplicate(true)
    user_data["name"] = "Test"
    user_data["username"] = "testuser"
    user_data["password"] = ""

    save_mgr.initialize_new_profile(1, user_data)

    assert(player_mgr.user_data.get("using_random_seed", false))
    assert(player_mgr.user_data.get("global_rng_seed", 0) != 0)
    print("using_random_seed_generation_test passed")
    quit()
