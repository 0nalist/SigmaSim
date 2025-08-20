extends SceneTree

func _ready():
	var stat_mgr = Engine.get_singleton("StatManager")
	var player_mgr = Engine.get_singleton("PlayerManager")
	stat_mgr.reset()
	player_mgr.reset()
	player_mgr.apply_background_effects("Pretty Privilege")
	assert(stat_mgr.get_stat("attractiveness") == 60.0)
	print("pretty_privilege_background_test passed")
	quit()
