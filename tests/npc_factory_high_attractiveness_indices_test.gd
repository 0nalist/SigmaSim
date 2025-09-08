extends SceneTree
const NPCFactory = preload("res://components/npc/npc_factory.gd")

func _ready() -> void:
	RNGManager.init_seed(0)
	var start_frame := Engine.get_frames_drawn()
	var res: Dictionary = await NPCFactory.find_high_attractiveness_indices(90.0, 0, 50, 0)
	var end_frame := Engine.get_frames_drawn()
	assert(res.get("indices", []).size() > 0)
	assert(end_frame > start_frame)
	print("npc_factory_high_attractiveness_indices_test passed")
	quit()
