extends Node
#Autoload: DBManager

var db: SQLite

func _ready():
	db = SQLite.new()
	db.path = "user://sigmasim.db"
	db.open_db()
	_create_tables()

func _create_tables():
	var npc_table := {
		"id": { "data_type": "int", "primary_key": true },
		"first_name": { "data_type": "text" },
		"middle_initial": { "data_type": "text" },
		"last_name": { "data_type": "text" },
		"gender_vector": { "data_type": "text" }, # Store as comma-separated string or JSON
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
		"tags": { "data_type": "text" }, # comma-separated
		"likes": { "data_type": "text" }, # comma-separated
		"fumble_bio": { "data_type": "text" }
	}
	db.create_table("npc", npc_table)

	# -- Fumble Tables --
	var relationships_table := {
			"npc_id": { "data_type": "int", "primary_key": true },
			"status": { "data_type": "text" }
	}
	db.create_table("fumble_relationships", relationships_table)

	var battles_table := {
			"battle_id": { "data_type": "text", "primary_key": true },
			"npc_id": { "data_type": "int" },
			"chatlog": { "data_type": "text" },
			"stats": { "data_type": "text" },
			"outcome": { "data_type": "text" }
	}
	db.create_table("fumble_battles", battles_table)


func save_npc(idx: int, npc: NPC):
	var data = {
		"id": idx,
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
	db.insert_row("npc", data)

func load_npc(idx: int) -> Dictionary:
	var result = db.select_rows("npc", "id = %d" % idx, ["*"])
	return result[0] if result.size() > 0 else null

func has_npc(idx: int) -> bool:
		var rows = db.select_rows("npc", "id = %d" % idx, ["id"])
		return rows.size() > 0

func save_fumble_relationship(npc_id: int, status: String) -> void:
	db.insert_row("fumble_relationships", {
			"npc_id": npc_id,
			"status": status
	})

func get_fumble_relationship(npc_id: int) -> String:
	var rows = db.select_rows("fumble_relationships", "npc_id = %d" % npc_id, ["status"])
	return rows[0].status if rows.size() > 0 else ""

func get_all_fumble_relationships() -> Dictionary:
	var rows = db.select_rows("fumble_relationships", "", ["npc_id", "status"])
	var out := {}
	for r in rows:
			out[r.npc_id] = r.status
	return out

func save_fumble_battle(battle_id: String, npc_id: int, chatlog: Array, stats: Dictionary, outcome: String) -> void:
	db.insert_row("fumble_battles", {
			"battle_id": battle_id,
			"npc_id": npc_id,
			"chatlog": to_json(chatlog),
			"stats": to_json(stats),
			"outcome": outcome
	})

func load_fumble_battle(battle_id: String) -> Dictionary:
	var rows = db.select_rows("fumble_battles", "battle_id = '%s'" % battle_id, ["*"])
	return rows[0] if rows.size() > 0 else {}

func get_active_fumble_battles() -> Array:
	var rows = db.select_rows("fumble_battles", "outcome = 'active'", ["battle_id", "npc_id", "chatlog", "stats"])
	var out := []
	for r in rows:
			out.append({
					"battle_id": r.battle_id,
					"npc_idx": int(r.npc_id),
					"chatlog": from_json(r.chatlog),
					"stats": from_json(r.stats)
			})
	return out

func to_json(value: Variant) -> String:
	match typeof(value):
		TYPE_VECTOR3:
			return JSON.stringify({
				"x": value.x,
				"y": value.y,
				"z": value.z
			})
		TYPE_DICTIONARY, TYPE_ARRAY:
			return JSON.stringify(value)
		_:
			return str(value)

func from_json(json_str: String) -> Variant:
	var result = JSON.parse_string(json_str)
	return result if result != null else null
