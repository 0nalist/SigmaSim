extends SceneTree

func _ready() -> void:
        var save_mgr = Engine.get_singleton("SaveManager")
        var db_mgr = Engine.get_singleton("DBManager")

        # Setup slot 1 with one NPC
        save_mgr.reset_managers()
        save_mgr.current_slot_id = 1
        db_mgr.db.query("DELETE FROM npc WHERE slot_id = 1")
        db_mgr.db.query("INSERT OR REPLACE INTO npc (id, slot_id, full_name) VALUES (101, 1, 'Slot1 NPC')")
        save_mgr.save_to_slot(1)

        # Setup slot 2 with a different NPC
        save_mgr.reset_managers()
        save_mgr.current_slot_id = 2
        db_mgr.db.query("DELETE FROM npc WHERE slot_id = 2")
        db_mgr.db.query("INSERT OR REPLACE INTO npc (id, slot_id, full_name) VALUES (202, 2, 'Slot2 NPC')")
        save_mgr.save_to_slot(2)

        # Load slot 1 and verify data
        save_mgr.load_from_slot(1)
        var rows = db_mgr.db.select_rows("npc", "slot_id = 1", ["full_name"])
        assert(rows.size() == 1)
        assert(rows[0].full_name == "Slot1 NPC")

        # Load slot 2 and verify data
        save_mgr.load_from_slot(2)
        rows = db_mgr.db.select_rows("npc", "slot_id = 2", ["full_name"])
        assert(rows.size() == 1)
        assert(rows[0].full_name == "Slot2 NPC")

        # Load slot 1 again to ensure it still restores correctly
        save_mgr.load_from_slot(1)
        rows = db_mgr.db.select_rows("npc", "slot_id = 1", ["full_name"])
        assert(rows.size() == 1)
        assert(rows[0].full_name == "Slot1 NPC")

        print("db_slot_switch_restore_test passed")
        quit()
