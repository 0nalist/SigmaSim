extends SceneTree

func _ready() -> void:
    RNGManager.init_seed(0)
    NPCCatalog.generate(20)
    var npc_manager = Engine.get_singleton("NPCManager")
    npc_manager.encountered_npcs = []
    npc_manager.encounter_count = 0

    var exclude_idx = NPCCatalog.npc_catalog[0]["index"]
    var res = npc_manager.query_npc_indices({"count": 2, "exclude": [exclude_idx]})
    assert(res.size() == 2)
    assert(not res.has(exclude_idx))
    for idx in res:
        assert(npc_manager.encountered_npcs.has(idx))

    var fem_result = npc_manager.query_npc_indices({
        "count": 1,
        "gender_similarity_vector": Vector3(1,0,0),
        "min_gender_similarity": 0.99
    })
    assert(fem_result.size() == 1)
    var gv = NPCCatalog.npc_catalog[fem_result[0]]["gender_vector"]
    var sim = npc_manager.gender_dot_similarity(Vector3(1,0,0), gv)
    assert(sim >= 0.99)
    assert(npc_manager.encountered_npcs.has(fem_result[0]))
    print("query_npc_indices_test passed")
    quit()
