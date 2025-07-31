extends Node
# Autoload: DBManager

var db: SQLite

func _ready():
	db = SQLite.new()
	db.path = "user://sigmasim.db"
	db.open_db()
	# Check if slot_id exists
	db.query("PRAGMA table_info(npc)")
	var columns = db.query_result
	var has_slot_id = false
	for col in columns:
		if col["name"] == "slot_id":
			has_slot_id = true
			break
	if not has_slot_id:
		db.query("ALTER TABLE npc ADD COLUMN slot_id int")
	_create_tables()


func _create_tables():
	var npc_table := {
		"id": { "data_type": "int" },
		"slot_id": { "data_type": "int" },
		"first_name": { "data_type": "text" },
		"middle_initial": { "data_type": "text" },
		"last_name": { "data_type": "text" },
		"gender_vector": { "data_type": "text" },
		"bio": { "data_type": "text" },
		"occupation": { "data_type": "text" },
		"relationship_status": { "data_type": "text" },
		"affinity": { "data_type": "real" },
		"rizz": { "data_type": "int" },
		"attractiveness": { "data_type": "int" },
		"wealth": { "data_type": "int" },
		"alpha": { "data_type": "real" },
		"beta": { "data_type": "real" },
		"gamma": { "data_type": "real" },
		"delta": { "data_type": "real" },
		"omega": { "data_type": "real" },
		"sigma": { "data_type": "real" },
		"tags": { "data_type": "text" },
		"fumble_bio": { "data_type": "text" },
		"primary_key": ["id", "slot_id"]
	}
	db.create_table("npc", npc_table)
	db.query("CREATE INDEX IF NOT EXISTS idx_npc_slot_id ON npc(slot_id)")

	var relationships_table := {
		"npc_id": { "data_type": "int" },
		"slot_id": { "data_type": "int" },
		"status": { "data_type": "text" },
		"primary_key": ["npc_id", "slot_id"]
	}
	db.create_table("fumble_relationships", relationships_table)
	db.query("CREATE INDEX IF NOT EXISTS idx_rel_slot_id ON fumble_relationships(slot_id)")

	var battles_table := {
		"battle_id": { "data_type": "text" },
		"slot_id": { "data_type": "int" },
		"npc_id": { "data_type": "int" },
		"chatlog": { "data_type": "text" },
		"stats": { "data_type": "text" },
		"outcome": { "data_type": "text" },
		"primary_key": ["battle_id", "slot_id"]
	}
	db.create_table("fumble_battles", battles_table)
	db.query("CREATE INDEX IF NOT EXISTS idx_battle_slot_id ON fumble_battles(slot_id)")

# -- NPCs --

func save_npc(idx: int, npc: NPC, slot_id: int = SaveManager.current_slot_id):
	var data = {
		"id": idx,
		"slot_id": slot_id,
		"first_name": npc.first_name,
		"middle_initial": npc.middle_initial,
		"last_name": npc.last_name,
		"gender_vector": to_json(npc.gender_vector),
		"bio": npc.fumble_bio,
		"occupation": npc.occupation,
		"relationship_status": npc.relationship_status,
		"affinity": npc.affinity,
		"rizz": npc.rizz,
		"attractiveness": npc.attractiveness,
		"wealth": npc.wealth,
		"alpha": npc.alpha,
		"beta": npc.beta,
		"gamma": npc.gamma,
		"delta": npc.delta,
		"omega": npc.omega,
		"sigma": npc.sigma,
		"tags": ",".join(npc.tags),
		"fumble_bio": npc.fumble_bio,
	}
	# UPSERT: update first, insert if not updated
	var updated = db.update_rows(
		"npc",
		_make_update_string(data),
		{ "id": idx, "slot_id": slot_id }
	)
	if updated == false:
		db.insert_row("npc", data)

func get_all_npcs_for_slot(slot_id: int = SaveManager.current_slot_id) -> Array:
	return db.select_rows("npc", "slot_id = %d" % slot_id, ["*"])

func load_npc(idx: int, slot_id: int = SaveManager.current_slot_id) -> Dictionary:
	var result = db.select_rows("npc", "id = %d AND slot_id = %d" % [idx, slot_id], ["*"])
	return result[0] if result.size() > 0 else null

func has_npc(idx: int, slot_id: int = SaveManager.current_slot_id) -> bool:
	var rows = db.select_rows("npc", "id = %d AND slot_id = %d" % [idx, slot_id], ["id"])
	return rows.size() > 0

# -- Relationships --

func save_fumble_relationship(npc_id: int, status: String, slot_id: int = SaveManager.current_slot_id) -> void:
	var data = {
		"npc_id": npc_id,
		"slot_id": slot_id,
		"status": status
	}
	print("Saving relationship: npc_id =", npc_id, "status =", status, "slot_id =", slot_id)
	var updated = db.update_rows(
		"fumble_relationships",
		"status = '%s'" % status.replace("'", "''"),
		{ "npc_id": npc_id, "slot_id": slot_id }
	)
	if updated == false:
		db.insert_row("fumble_relationships", data)

func get_fumble_relationship(npc_id: int, slot_id: int = SaveManager.current_slot_id) -> String:
	var rows = db.select_rows("fumble_relationships", "npc_id = %d AND slot_id = %d" % [npc_id, slot_id], ["status"])
	return rows[0].status if rows.size() > 0 else ""

func get_all_fumble_relationships(slot_id: int = SaveManager.current_slot_id) -> Dictionary:
	var rows = db.select_rows("fumble_relationships", "slot_id = %d" % slot_id, ["npc_id", "status"])
	print("Queried fumble_relationships for slot_id =", slot_id, "| Rows:", rows.size())
	var out := {}
	for r in rows:
		out[r.npc_id] = r.status
	print("Loaded relationships:", out)
	return out


# -- Battles --

func save_fumble_battle(
	battle_id: String,
	npc_id: int,
	chatlog: Array,
	stats: Dictionary,
	outcome: String,
	slot_id: int = SaveManager.current_slot_id
) -> void:
	var data = {
		"battle_id": battle_id,
		"slot_id": slot_id,
		"npc_id": npc_id,
		"chatlog": to_json(chatlog),
		"stats": to_json(stats),
		"outcome": outcome
	}
	var updated = db.update_rows(
		"fumble_battles",
		"npc_id = %d, chatlog = '%s', stats = '%s', outcome = '%s'" % [
			npc_id,
			data.chatlog.replace("'", "''"),
			data.stats.replace("'", "''"),
			outcome.replace("'", "''")
		],
		{ "battle_id": battle_id, "slot_id": slot_id }
	)
	if updated == 0:
		db.insert_row("fumble_battles", data)

func load_fumble_battle(battle_id: String, slot_id: int = SaveManager.current_slot_id) -> Dictionary:
	var rows = db.select_rows("fumble_battles", "battle_id = '%s' AND slot_id = %d" % [battle_id, slot_id], ["*"])
	return rows[0] if rows.size() > 0 else {}

func get_active_fumble_battles(slot_id: int = SaveManager.current_slot_id) -> Array:
	var rows = db.select_rows("fumble_battles", "slot_id = %d AND outcome = 'active'" % slot_id, ["battle_id", "npc_id", "chatlog", "stats"])
	var out := []
	for r in rows:
		out.append({
			"battle_id": r.battle_id,
			"npc_idx": int(r.npc_id),
			"chatlog": from_json(r.chatlog),
			"stats": from_json(r.stats)
		})
	return out

# -- Utilities --

func _make_update_string(data: Dictionary) -> String:
	var out := []
	for k in data.keys():
		if k in ["id", "slot_id"]:
			continue
		var v = data[k]
		if typeof(v) == TYPE_STRING:
			out.append("%s = '%s'" % [k, v.replace("'", "''")])
		else:
			out.append("%s = %s" % [k, str(v)])
	return ", ".join(out)

func to_json(value: Variant) -> String:
	match typeof(value):
		TYPE_VECTOR3:
			return JSON.stringify({ "x": value.x, "y": value.y, "z": value.z })
		TYPE_DICTIONARY, TYPE_ARRAY:
			return JSON.stringify(value)
		_:
			return str(value)

func from_json(json_str: String) -> Variant:
	var result = JSON.parse_string(json_str)
	return result if result != null else null
