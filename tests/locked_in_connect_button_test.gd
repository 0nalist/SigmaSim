extends Node

const NPC = preload("res://components/npc/npc.gd")
const ExFactorViewScene = preload("res://components/popups/ex_factor_view.tscn")

func _ready() -> void:
        var npc_mgr = Engine.get_singleton("NPCManager")
        var db_mgr = Engine.get_singleton("DBManager")
        db_mgr.save_npc = func(_i, _n): pass
        npc_mgr.npcs = {}
        npc_mgr.persistent_npcs = {}
        npc_mgr.encountered_npcs = []

        var npc := NPC.new()
        var npc_idx := 1
        npc_mgr.npcs[npc_idx] = npc
        npc_mgr.persistent_npcs[npc_idx] = {}
        npc_mgr.encountered_npcs.append(npc_idx)

        var view := ExFactorViewScene.instantiate()
        add_child(view)
        view.setup_custom({"npc": npc, "npc_idx": npc_idx})
        await get_tree().process_frame
        assert(is_instance_valid(view.locked_in_button))
        view._on_locked_in_button_pressed()
        await get_tree().process_frame
        assert(npc.locked_in_connection)
        assert(not is_instance_valid(view.locked_in_button))
        print("locked_in_connect_button_test passed")
