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


func save_npc(idx: int, npc: NPC):
	var data = {
		"id": idx,
		"first_name": npc.first_name,
		"middle_initial": npc.middle_initial,
		"last_name": npc.last_name,
		"gender_vector": to_json(npc.gender_vector),
		"bio": npc.bio,
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
