extends SceneTree

func _ready() -> void:
	NPCCatalog.generate(100)
	var total = min(100, NameManager.get_unique_name_count())
	assert(NPCCatalog.npc_catalog.size() == total)
	var arr := NPCCatalog.index_by_attractiveness
	for i in range(1, arr.size()):
		assert(NPCCatalog.npc_catalog[arr[i-1]]["attractiveness"] <= NPCCatalog.npc_catalog[arr[i]]["attractiveness"])
	var fem = NPCCatalog.index_by_gender["fem"]
	for i in range(1, fem.size()):
		assert(NPCCatalog.npc_catalog[fem[i-1]]["gender_vector"].x <= NPCCatalog.npc_catalog[fem[i]]["gender_vector"].x)
	print("npc_catalog_generation_test passed")
	quit()
