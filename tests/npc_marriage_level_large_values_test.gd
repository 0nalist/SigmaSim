extends SceneTree

func _ready() -> void:
	load("res://flex_number.gd")
	load("res://resources/portraits/portrait_config.gd")
	var npc_script = load("res://components/npc/npc.gd")
	var npc = npc_script.new()
	npc.relationship_progress.set_value(1e20)
	assert(npc.get_marriage_level() == 16)
	npc.relationship_progress.set_value(1e40)
	assert(npc.get_marriage_level() == 36)
	print("npc_marriage_level_large_values_test passed")
	quit()
