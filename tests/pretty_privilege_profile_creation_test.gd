extends SceneTree

func _ready():
	var stat_mgr = Engine.get_singleton("StatManager")
	var player_mgr = Engine.get_singleton("PlayerManager")
	var save_mgr = Engine.get_singleton("SaveManager")

	stat_mgr.reset()
	player_mgr.reset()

	var user_data = player_mgr.user_data.duplicate(true)
	user_data["background"] = "Pretty Privilege"
	save_mgr.initialize_new_profile(1, user_data)
	save_mgr.load_from_slot(1)
	assert(stat_mgr.get_stat("attractiveness") == 60.0)
	print("pretty_privilege_profile_creation_test passed")
	quit()
