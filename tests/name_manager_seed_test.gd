extends SceneTree

func _ready():
	RNGManager.init_seed(100)
	var name1 = NameManager.get_npc_name_by_index(0)["full_name"]
	RNGManager.init_seed(200)
	var name2 = NameManager.get_npc_name_by_index(0)["full_name"]
	assert(name1 != name2)
	print("name_manager_seed_test passed")
	quit()
