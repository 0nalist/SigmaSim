extends Node
# Autoload: DBManager

var db: SQLite

const SCHEMA := {
	"npc": {
		"id": {"data_type": "int", "primary_key": true},
		"slot_id": {"data_type": "int", "primary_key": true},
		"full_name": {"data_type": "text"},
		"first_name": {"data_type": "text"},
		"middle_initial": {"data_type": "text"},
		"last_name": {"data_type": "text"},
		"gender_vector": {"data_type": "text"},
		"username": {"data_type": "text"},
		"occupation": {"data_type": "text"},
		"relationship_status": {"data_type": "text"},
		"relationship_stage": {"data_type": "int"},
				"relationship_progress": {"data_type": "real"},
		"affinity": {"data_type": "real"},
		"rizz": {"data_type": "int"},
		"attractiveness": {"data_type": "int"},
		"income": {"data_type": "int"},
		"wealth": {"data_type": "int"},
		"preferred_pet_names": {"data_type": "text"},
		"player_pet_names": {"data_type": "text"},
		"alpha": {"data_type": "real"},
		"beta": {"data_type": "real"},
		"gamma": {"data_type": "real"},
		"delta": {"data_type": "real"},
		"omega": {"data_type": "real"},
		"sigma": {"data_type": "real"},
		"tags": {"data_type": "text"},
		"likes": {"data_type": "text"},
		"fumble_bio": {"data_type": "text"},
		"self_esteem": {"data_type": "int"},
		"apprehension": {"data_type": "int"},
		"chemistry": {"data_type": "int"},
		"chat_battle_type": {"data_type": "text"},
		"ocean": {"data_type": "text"},
		"openness": {"data_type": "real"},
		"conscientiousness": {"data_type": "real"},
		"extraversion": {"data_type": "real"},
		"agreeableness": {"data_type": "real"},
		"neuroticism": {"data_type": "real"},
		"mbti": {"data_type": "text"},
		"zodiac": {"data_type": "text"},
		"wall_posts": {"data_type": "text"},
		"portrait_config": {"data_type": "text"}
},
	"fumble_relationships": {
		"npc_id": {"data_type": "int", "primary_key": true},
		"slot_id": {"data_type": "int", "primary_key": true},
		"status": {"data_type": "text"},
		"created_at": {"data_type": "int"},
		"updated_at": {"data_type": "int"}
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
	var dict = npc.to_dict()
	dict["id"] = idx
	dict["slot_id"] = slot_id
	# Serialize all complex fields as JSON
	dict["gender_vector"] = to_json(dict.get("gender_vector", {"x":0,"y":0,"z":1}))
	dict["tags"] = to_json(dict.get("tags", []))
	dict["likes"] = to_json(dict.get("likes", []))
	dict["preferred_pet_names"] = to_json(dict.get("preferred_pet_names", []))
	dict["player_pet_names"] = to_json(dict.get("player_pet_names", []))
	dict["ocean"] = to_json(dict.get("ocean", {}))
	dict["wall_posts"] = to_json(dict.get("wall_posts", []))
	var pc = dict.get("portrait_config", null)
	dict["portrait_config"] = to_json(pc) if pc != null else ""
	# Profile pic is not natively serializable; see below

	var update_data = dict.duplicate()
	update_data.erase("id")
	update_data.erase("slot_id")

	var rows = db.select_rows("npc", "id = %d AND slot_id = %d" % [idx, slot_id], ["id"])
	if rows.size() > 0:
		db.update_rows("npc", "id = %d AND slot_id = %d" % [idx, slot_id], update_data)
	else:
		db.insert_row("npc", dict)

func load_npc(idx: int, slot_id: int = SaveManager.current_slot_id) -> NPC:
	var result = db.select_rows("npc", "id = %d AND slot_id = %d" % [idx, slot_id], ["*"])
	if result.size() == 0:
		return null
	var row = result[0]
	# Deserialize JSON fields safely
	row["gender_vector"] = _safe_from_json(row.get("gender_vector", null), '{"x":0,"y":0,"z":1}')
	row["tags"] = _safe_from_json(row.get("tags", null), "[]")
	row["likes"] = _safe_from_json(row.get("likes", null), "[]")
	row["preferred_pet_names"] = _safe_from_json(row.get("preferred_pet_names", null), "[]")
	row["player_pet_names"] = _safe_from_json(row.get("player_pet_names", null), "[]")
	row["ocean"] = _safe_from_json(row.get("ocean", null), "{}")
	row["wall_posts"] = _safe_from_json(row.get("wall_posts", null), "[]")
	row["portrait_config"] = _safe_from_json(row.get("portrait_config", null), "{}")
	return NPC.from_dict(row)

func get_all_npcs_for_slot(slot_id: int = SaveManager.current_slot_id) -> Array:
	var raw_rows = db.select_rows("npc", "slot_id = %d" % slot_id, ["*"])
	var out: Array = []
	for row in raw_rows:
		row["gender_vector"] = _safe_from_json(row.get("gender_vector", null), '{"x":0,"y":0,"z":1}')
		row["tags"] = _safe_from_json(row.get("tags", null), "[]")
		row["likes"] = _safe_from_json(row.get("likes", null), "[]")
		row["preferred_pet_names"] = _safe_from_json(row.get("preferred_pet_names", null), "[]")
		row["player_pet_names"] = _safe_from_json(row.get("player_pet_names", null), "[]")
		row["ocean"] = _safe_from_json(row.get("ocean", null), "{}")
		row["wall_posts"] = _safe_from_json(row.get("wall_posts", null), "[]")
		row["portrait_config"] = _safe_from_json(row.get("portrait_config", null), "{}")
		out.append(NPC.from_dict(row))
	return out

func _safe_from_json(value, fallback: String) -> Variant:
	if value == null:
		return JSON.parse_string(fallback)
	if typeof(value) in [TYPE_ARRAY, TYPE_DICTIONARY]:
		return value
	if typeof(value) == TYPE_STRING:
		var parsed = from_json(value)
		if parsed != null:
				return parsed
		if fallback.begins_with("["):
				return _csv_to_array(value)
		return JSON.parse_string(fallback)
	return JSON.parse_string(fallback)

func _csv_to_array(str_val: String) -> Array:
	var arr: Array = []
	if str_val == null:
		return arr
	for part in str_val.split(","):
		var s = String(part).strip_edges()
		if s != "":
			arr.append(s)
	return arr

func has_npc(idx: int, slot_id: int = SaveManager.current_slot_id) -> bool:
	var rows = db.select_rows("npc", "id = %d AND slot_id = %d" % [idx, slot_id], ["id"])
	return rows.size() > 0


# -- Relationships --

func save_fumble_relationship(npc_id: int, status: FumbleManager.FumbleStatus, slot_id: int = SaveManager.current_slot_id) -> void:
	var status_str = FumbleManager.FUMBLE_STATUS_STRINGS[status]
	var now := int(Time.get_unix_time_from_system())
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
			{
				"status": status_str,
				"updated_at": now
			}
		)
	else:
		db.insert_row(
			"fumble_relationships",
			{
				"npc_id": npc_id,
				"slot_id": slot_id,
				"status": status_str,
				"created_at": now,
				"updated_at": now
			}
		)

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

func get_all_fumble_relationship_rows(slot_id: int = SaveManager.current_slot_id) -> Array:
	var rows = db.select_rows(
		"fumble_relationships",
		"slot_id = %d" % slot_id,
		["npc_id", "status", "created_at", "updated_at"]
	)
	var out: Array = []
	for r in rows:
		var c = r.get("created_at", 0)
		if c == null:
			c = 0
		var u = r.get("updated_at", 0)
		if u == null:
			u = 0
		out.append({
			"npc_id": int(r.npc_id),
			"status": str(r.status),
			"created_at": int(c),
			"updated_at": int(u)
		})
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
	# Note: despite the name, this now returns all battles regardless of outcome
	# so that the UI can show results such as victories or blocks.
	print("DB get_fumble_battles slot=", slot_id)
	var rows = db.select_rows(
		"fumble_battles",
		"slot_id = %d" % slot_id,
		["battle_id", "npc_id", "chatlog", "stats", "outcome"]
	)
	var out := []
	for r in rows:
		print(" -> battle", r.battle_id, "outcome", r.outcome)
		out.append({
			"battle_id": r.battle_id,
			"npc_idx": int(r.npc_id),
			"chatlog": from_json(r.chatlog),
			"stats": from_json(r.stats),
			"outcome": r.outcome,
		})
	return out


# -- Slot Maintenance --
func delete_slot_data(slot_id: int) -> void:
	db.delete_rows("npc", "slot_id = %d" % slot_id)
	db.delete_rows("fumble_relationships", "slot_id = %d" % slot_id)
	db.delete_rows("fumble_battles", "slot_id = %d" % slot_id)



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
	if typeof(json_str) != TYPE_STRING:
			return null
	var json := JSON.new()
	var err = json.parse(json_str)
	if err == OK:
		return json.data
	return null


# -- Daterbase Helpers --

func get_daterbase_entries(slot_id: int = SaveManager.current_slot_id) -> Array:
	var q = "SELECT npc_id, battle_id FROM fumble_battles WHERE slot_id = %d AND outcome = 'victory'" % slot_id
	db.query(q)
	var rows = db.query_result
	var latest := {}
	for r in rows:
		var npc_id = int(r.npc_id)
		var b_id = str(r.battle_id)
		var t = int(b_id.split("_")[0]) if "_" in b_id else 0
		if not latest.has(npc_id) or t > latest[npc_id]:
			latest[npc_id] = t
	var out: Array = []
	for n in latest.keys():
		out.append({"npc_id": n, "timestamp": latest[n]})
	return out

func execute_select(query: String) -> Array:
	var trimmed = query.strip_edges()
	var lower = trimmed.to_lower()
	if not lower.begins_with("select"):
		push_warning("execute_select only allows SELECT statements")
		return []
	for bad in ["drop", "delete", "update", "insert", "alter", "pragma"]:
		if bad in lower:
			push_warning("Unsafe keyword detected in query: %s" % bad)
			return []
	db.query(trimmed)
	return db.query_result
