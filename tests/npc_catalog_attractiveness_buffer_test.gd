extends SceneTree

func _ready() -> void:
        RNGManager.init_seed(0)
        NPCCatalog.generate(20)
        NPCCatalog.extend_threshold = 2
        NPCCatalog.extend_batch_size = 5
        var npc_manager = Engine.get_singleton("NPCManager")
        npc_manager.encountered_npcs = []
        npc_manager.encounter_count = 0

        var attrs: Array[float] = []
        for record in NPCCatalog.npc_catalog:
                attrs.append(record["attractiveness"])
        attrs.sort()
        var threshold: float = attrs[attrs.size() - 2]

        var high_ids: Array[int] = []
        for record in NPCCatalog.npc_catalog:
                var idx: int = int(record["index"])
                if float(record["attractiveness"]) >= threshold:
                        high_ids.append(idx)
        assert(high_ids.size() > 1)
        for i in range(high_ids.size() - 1):
                npc_manager.encountered_npcs.append(high_ids[i])

        var res = await npc_manager.query_npc_indices({
                "count": 1,
                "min_attractiveness": threshold,
        })
        assert(res.size() == 1)
        assert(NPCCatalog.npc_catalog.size() == 25)

        print("npc_catalog_attractiveness_buffer_test passed")
        quit()
