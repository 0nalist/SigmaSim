extends Node

const NPC := preload("res://components/npc/npc.gd")
const LockedInScene := preload("res://components/apps/app_scenes/locked_in.tscn")

func _ready() -> void:
	var npc_mgr = Engine.get_singleton("NPCManager")
	var db_mgr = Engine.get_singleton("DBManager")
	db_mgr.save_npc = func(_i, _n): pass

	npc_mgr.npcs.clear()
	npc_mgr.persistent_npcs.clear()

	for i in range(5):
		var idx := 1000 + i
		var npc := NPC.new()
		npc.full_name = "NPC %d" % i
		npc_mgr.npcs[idx] = npc
		npc_mgr.persistent_npcs[idx] = {}

        var app = LockedInScene.instantiate()
        add_child(app)
        await get_tree().process_frame
        assert(app.connections_list.buttons_container.get_child_count() == 0)

        NPCManager.set_npc_field(1000, "locked_in_connection", true)
        await get_tree().process_frame
        assert(app.connections_list.buttons_container.get_child_count() == 1)

        NPCManager.set_npc_field(1001, "locked_in_connection", true)
        await get_tree().process_frame
        assert(app.connections_list.buttons_container.get_child_count() == 2)

        NPCManager.set_npc_field(1002, "locked_in_connection", true)
        await get_tree().process_frame
        assert(app.connections_list.buttons_container.get_child_count() == 3)

        var locked := NPCManager.get_locked_in_connection_ids()
        assert(locked.size() == 3)
        print("locked_in_connections_list_test passed")
