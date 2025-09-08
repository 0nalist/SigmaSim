extends SceneTree

func _ready() -> void:
        RNGManager.init_seed(0)
        NPCCatalog.generate(20)
        NPCCatalog.extend_threshold = 2
        NPCCatalog.extend_batch_size = 5
        var npc_manager = Engine.get_singleton("NPCManager")
        npc_manager.encountered_npcs = []
        npc_manager.encounter_count = 0

        var fem_ids: Array[int] = []
        for record in NPCCatalog.npc_catalog:
                var idx: int = int(record["index"])
                var gv: Vector3 = record["gender_vector"]
                if gv.x >= 0.7:
                        fem_ids.append(idx)
        assert(fem_ids.size() > 1)
        for i in range(fem_ids.size() - 1):
                npc_manager.encountered_npcs.append(fem_ids[i])

        var res = npc_manager.query_npc_indices({
                "count": 1,
                "gender_similarity_vector": Vector3(1,0,0),
                "min_gender_similarity": 0.7,
        })
        assert(res.size() == 1)
        assert(NPCCatalog.npc_catalog.size() == 25)

        print("npc_catalog_gender_buffer_test passed")
        quit()
