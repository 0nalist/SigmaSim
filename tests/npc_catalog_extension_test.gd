extends SceneTree

func _ready() -> void:
	RNGManager.init_seed(0)
	NPCCatalog.generate(5)
	NPCCatalog.extend_threshold = 2
	NPCCatalog.extend_batch_size = 5
	var npc_manager = Engine.get_singleton("NPCManager")
	npc_manager.encountered_npcs = []
	npc_manager.encounter_count = 0

        var first = await npc_manager.query_npc_indices({"count": 4})
	assert(first.size() == 4)

        var second = await npc_manager.query_npc_indices({"count": 1})
	assert(second.size() == 1)
	assert(NPCCatalog.npc_catalog.size() == 10)

	var idx = NPCCatalog.npc_catalog.size() - 1
	var name_data = NameManager.get_npc_name_by_index(idx)
	var record = NPCCatalog.npc_catalog[idx]
	assert(record["gender_vector"] == name_data["gender_vector"])
	var expected_att = NPCFactory.attractiveness_from_name(name_data["full_name"])
	assert(record["attractiveness"] == expected_att)
	var expected_tags = NPCFactory.generate_npc_tags(name_data["full_name"], NPCFactory.TAG_DATA, 3)
	assert(record["tags"] == expected_tags)

	print("npc_catalog_extension_test passed")
	quit()
