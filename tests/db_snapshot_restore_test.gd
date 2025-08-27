extends SceneTree

func _ready() -> void:
	var save_mgr = Engine.get_singleton("SaveManager")
	var db_mgr = Engine.get_singleton("DBManager")

	save_mgr.reset_managers()
	save_mgr.current_slot_id = 1

	var npc_id := 4242
	db_mgr.db.query("DELETE FROM npc WHERE id = %d AND slot_id = %d" % [npc_id, save_mgr.current_slot_id])

	db_mgr.db.query("INSERT OR REPLACE INTO npc (id, slot_id, full_name) VALUES (%d, %d, 'Snapshot Test')" % [npc_id, save_mgr.current_slot_id])

	save_mgr.save_to_slot(save_mgr.current_slot_id)

	db_mgr.db.query("UPDATE npc SET full_name = 'Changed' WHERE id = %d AND slot_id = %d" % [npc_id, save_mgr.current_slot_id])

	save_mgr.load_from_slot(save_mgr.current_slot_id)

	var rows = db_mgr.db.select_rows("npc", "id = %d AND slot_id = %d" % [npc_id, save_mgr.current_slot_id], ["full_name"])
	assert(rows.size() > 0)
	assert(rows[0].full_name == "Snapshot Test")
	print("db_snapshot_restore_test passed")
	quit()

