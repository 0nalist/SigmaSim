extends Node

func _init():
        var indices = [0, 1, 123, 4567]
        for idx in indices:
                var name = NameManager.get_npc_name_by_index(idx)["full_name"]
                var recovered = NameManager.get_index_from_full_name(name)
                assert(recovered == idx)
        print("name_index_lookup_test passed")

