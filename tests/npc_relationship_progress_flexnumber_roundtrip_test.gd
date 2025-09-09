extends SceneTree

const NPC = preload("res://components/npc/npc.gd")

func _ready() -> void:
	var npc := NPC.new()
	npc.relationship_progress.set_value(1.23e45)
	var saved = npc.to_dict()
	assert(typeof(saved["relationship_progress"]) == TYPE_DICTIONARY)
	var loaded := NPC.from_dict(saved)
	assert(typeof(loaded.relationship_progress) == TYPE_OBJECT and loaded.relationship_progress.get_class() == "FlexNumber")
	assert(is_equal_approx(loaded.relationship_progress._mantissa, npc.relationship_progress._mantissa))
	assert(loaded.relationship_progress._exponent == npc.relationship_progress._exponent)
	print("npc_relationship_progress_flexnumber_roundtrip_test passed")
	quit()
