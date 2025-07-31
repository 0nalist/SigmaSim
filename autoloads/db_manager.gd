extends Node
# Autoload: DBManager

var db: SQLite

const SCHEMA := {
	"npc": {
		"id": {"data_type": "int", "primary_key": true},
		"slot_id": {"data_type": "int", "primary_key": true},
		"first_name": {"data_type": "text"},
		"middle_initial": {"data_type": "text"},
		"last_name": {"data_type": "text"},
		"gender_vector": {"data_type": "text"},
		"bio": {"data_type": "text"},
		"occupation": {"data_type": "text"},
		"relationship_status": {"data_type": "text"},
		"affinity": {"data_type": "real"},
		"rizz": {"data_type": "int"},
		"attractiveness": {"data_type": "int"},
		"wealth": {"data_type": "int"},
		"alpha": {"data_type": "real"},
		"beta": {"data_type": "real"},
		"gamma": {"data_type": "real"},
		"delta": {"data_type": "real"},
		"omega": {"data_type": "real"},
		"sigma": {"data_type": "real"},
		"tags": {"data_type": "text"},
		"fumble_bio": {"data_type": "text"}
	},
	"fumble_relationships": {
		"npc_id": {"data_type": "int", "primary_key": true},
		"slot_id": {"data_type": "int", "primary_key": true},
		"status": {"data_type": "text"}
	},
	"fumble_battles": {
		"battle_id": {"data_type": "text", "primary_key": true},
		"slot_id": {"data_type": "int", "primary_key": true},
		"npc_id": {"data_type": "int"},
		"chatlog": {"data_type": "text"},
		"stats": {"data_type": "text"},
		"outcome": {"data_type": "text"}
	}
}

func _ready():
	db = SQLite.new()
	db.path = "user://sigmasim.db"
	db.open_db()
	_init_schema()

func _init_schema():
	for table_name in SCHEMA.keys():
		var fields = SCHEMA[table_name]
		db.create_table(table_name, fields)
		_migrate_table(table_name, fields)
		# Indices
		if table_name == "npc":
			db.query("CREATE INDEX IF NOT EXISTS idx_npc_slot_id ON npc(slot_id)")
		if table_name == "fumble_relationships":
			db.query("CREATE INDEX IF NOT EXISTS idx_rel_slot_id ON fumble_relationships(slot_id)")
		if table_name == "fumble_battles":
			db.query("CREATE INDEX IF NOT EXISTS idx_battle_slot_id ON fumble_battles(slot_id)")

func _migrate_table(table_name: String, fields: Dictionary):
	var column_defs := {}
	for k in fields.keys():
		if k == "primary_key":
			continue
		var def = fields[k]
		if typeof(def) == TYPE_DICTIONARY:
			column_defs[k] = def.get("data_type", "text")
		else:
			column_defs[k] = str(def)
	db.query("PRAGMA table_info(%s)" % table_name)
	var cols = db.query_result
	var existing = []
	for col in cols:
		existing.append(col["name"])
	for cname in column_defs.keys():
		if not existing.has(cname):
			print("DBManager: Adding missing column %s to table %s" % [cname, table_name])
			db.query("ALTER TABLE %s ADD COLUMN %s %s" % [table_name, cname, column_defs[cname]])

# -- NPCs --

func save_npc(idx: int, npc: NPC, slot_id: int = SaveManager.current_slot_id):
	var data = {
		# Used
		"id": idx,
		"slot_id": slot_id,
		"first_name": npc.first_name,
		"middle_initial": npc.middle_initial,
		"last_name": npc.last_name,
		"gender_vector": to_json(npc.gender_vector),
		"bio": npc.fumble_bio,
		"occupation": npc.occupation,
		"relationship_status": npc.relationship_status,
		
		"attractiveness": npc.attractiveness,
		"wealth": npc.wealth,
		"tags": ",".join(npc.tags),
		"fumble_bio": npc.fumble_bio,
		"chat_battle_type": npc.chat_battle_type,
		
		# Not used (yet)
		"affinity": npc.affinity,
		"rizz": npc.rizz,
		
		"alpha": npc.alpha,
		"beta": npc.beta,
		"gamma": npc.gamma,
		"delta": npc.delta,
		"omega": npc.omega,
		"sigma": npc.sigma,

		}

	var update_data = data.duplicate()
	update_data.erase("id")
	update_data.erase("slot_id")

	var rows = db.select_rows("npc", "id = %d AND slot_id = %d" % [idx, slot_id], ["id"])
	if rows.size() > 0:
		db.update_rows(
			"npc",
			"id = %d AND slot_id = %d" % [idx, slot_id],
			update_data
		)
	else:
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

func save_fumble_relationship(npc_id: int, status: FumbleManager.FumbleStatus, slot_id: int = SaveManager.current_slot_id) -> void:
	# Convert enum to string for DB storage
	var status_str = FumbleManager.FUMBLE_STATUS_STRINGS[status]
	var data = {
		"npc_id": npc_id,
		"slot_id": slot_id,
		"status": status_str
	}
	print("Saving relationship: npc_id =", npc_id, "status =", status_str, "slot_id =", slot_id)
	var rows = db.select_rows(
		"fumble_relationships",
		"npc_id = %d AND slot_id = %d" % [npc_id, slot_id],
		["npc_id"]
	)
	if rows.size() > 0:
		db.update_rows(
			"fumble_relationships",
			"npc_id = %d AND slot_id = %d" % [npc_id, slot_id],
			{ "status": status_str }
		)
	else:
			db.insert_row("fumble_relationships", data)

func get_fumble_relationship(npc_id: int, slot_id: int = SaveManager.current_slot_id) -> FumbleManager.FumbleStatus:
		var rows = db.select_rows("fumble_relationships", "npc_id = %d AND slot_id = %d" % [npc_id, slot_id], ["status"])
		var status_str = rows[0].status if rows.size() > 0 else ""
		return FumbleManager.FUMBLE_STATUS_LOOKUP.get(status_str, FumbleManager.FumbleStatus.LIKED)


func get_all_fumble_relationships(slot_id: int = SaveManager.current_slot_id) -> Dictionary:
	var rows = db.select_rows("fumble_relationships", "slot_id = %d" % slot_id, ["npc_id", "status"])
	print("Queried fumble_relationships for slot_id =", slot_id, "| Rows:", rows.size())
	var out := {}
	for r in rows:
			out[r.npc_id] = FumbleManager.FUMBLE_STATUS_LOOKUP.get(r.status, FumbleManager.FumbleStatus.LIKED)
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
	if outcome.strip_edges() == "" or not FumbleManager.VALID_OUTCOMES.has(outcome):
		push_warning("save_fumble_battle received invalid outcome '%s'" % outcome)

	print("DB save_fumble_battle: id=", battle_id, "slot=", slot_id, "outcome=", outcome)
	var data = {
		"battle_id": battle_id,
		"slot_id": slot_id,
		"npc_id": npc_id,
		"chatlog": to_json(chatlog),
		"stats": to_json(stats),
		"outcome": outcome
	}
	var update_data = data.duplicate()
	update_data.erase("battle_id")
	update_data.erase("slot_id")

	var rows = db.select_rows(
		"fumble_battles",
		"battle_id = '%s' AND slot_id = %d" % [battle_id, slot_id],
		["battle_id"]
	)
	if rows.size() > 0:
		db.update_rows(
			"fumble_battles",
			"battle_id = '%s' AND slot_id = %d" % [battle_id, slot_id],
			update_data
		)
	else:
		db.insert_row("fumble_battles", data)

func load_fumble_battle(battle_id: String, slot_id: int = SaveManager.current_slot_id) -> Dictionary:
	var rows = db.select_rows("fumble_battles", "battle_id = '%s' AND slot_id = %d" % [battle_id, slot_id], ["*"])
	return rows[0] if rows.size() > 0 else {}

func get_active_fumble_battles(slot_id: int = SaveManager.current_slot_id) -> Array:
	print("DB get_active_fumble_battles slot=", slot_id)
	var rows = db.select_rows("fumble_battles", "slot_id = %d AND outcome = 'active'" % slot_id, ["battle_id", "npc_id", "chatlog", "stats", "outcome"])
	var out := []
	for r in rows:
		print(" -> battle", r.battle_id, "outcome", r.outcome)
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
