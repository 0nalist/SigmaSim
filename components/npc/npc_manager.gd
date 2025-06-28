extends Node
# Autoload: NPCManager

var encounter_count: int = 0
var encountered_npcs: Array[int] = []
var encountered_npcs_by_app: Dictionary = {}
var active_npcs_by_app: Dictionary = {}

var relationship_status: Dictionary = {}
var persistent_npcs: Dictionary = {}
var npc_overrides: Dictionary = {}
var npcs: Dictionary = {}

var persistent_by_gender: Dictionary = {}
var persistent_by_wealth: Dictionary = {}

# === MAIN API ===

func get_npc_by_index(idx: int) -> NPC:
	if npcs.has(idx):
		return npcs[idx]

	var npc: NPC

	if DBManager.has_npc(idx):
		npc = _load_npc_from_db(idx)
	else:
		npc = NPCFactory.create_npc(idx)

	# Apply persistent or override data
	var data: Dictionary = persistent_npcs.get(idx, npc_overrides.get(idx, {}))
	for key in data.keys():
		npc.set(key, data[key])

	npcs[idx] = npc
	return npc

func set_npc_field(idx: int, field: String, value) -> void:
	if not npcs.has(idx):
		push_error("Tried to set a field on a non-existent NPC!")
		return
	npcs[idx].set(field, value)
	if persistent_npcs.has(idx):
		persistent_npcs[idx][field] = value
		DBManager.save_npc(idx, npcs[idx])
	else:
		if not npc_overrides.has(idx):
			npc_overrides[idx] = {}
		npc_overrides[idx][field] = value

func promote_to_persistent(idx: int) -> void:
	if not persistent_npcs.has(idx):
		var npc = get_npc_by_index(idx)
		persistent_npcs[idx] = npc_overrides.get(idx, {}).duplicate()
		npc_overrides.erase(idx)
		_index_persistent_npc(idx)
		DBManager.save_npc(idx, npc)

# Returns NPC indices matching a dot product similarity threshold with preferred_gender
func get_npcs_by_gender_dot(app_name: String, preferred_gender: Vector3, min_similarity: float, count: int, exclude: Array[int]=[]) -> Array[int]:
	var matches: Array[int] = []
	for idx in encountered_npcs_by_app.get(app_name, []):
		if exclude.has(idx):
			continue
		var npc = get_npc_by_index(idx)
		var sim = gender_dot_similarity(preferred_gender, npc.gender_vector)
		if sim >= min_similarity:
			matches.append(idx)
	matches.shuffle()
	return matches.slice(0, count)

func gender_dot_similarity(a: Vector3, b: Vector3) -> float:
	if a.length() == 0 or b.length() == 0:
		return 0.0
	return a.dot(b) / (a.length() * b.length()) # [0,1]





func _index_persistent_npc(idx: int) -> void:
	var npc = get_npc_by_index(idx)
	# Gender bucket
	var g := "nb"
	if npc.gender_vector.x > 0.5:
		g = "f"
	if npc.gender_vector.y > 0.5:
		g = "m"
	if not persistent_by_gender.has(g):
		persistent_by_gender[g] = []
	persistent_by_gender[g].append(idx)
	# Wealth bucket
	var w := "middle"
	if npc.wealth < 0:
		w = "poor"
	elif npc.wealth > 1_000_000:
		w = "rich"
	if not persistent_by_wealth.has(w):
		persistent_by_wealth[w] = []
	persistent_by_wealth[w].append(idx)

func _load_npc_from_db(idx: int) -> NPC:
	var data: Dictionary = DBManager.load_npc(idx)
	if data == null:
		push_error("Tried to load NPC index %d but not found in DB!" % idx)
		return NPCFactory.create_npc(idx)

	var npc = NPC.new()
	npc.first_name = data.get("first_name", "")
	npc.middle_initial = data.get("middle_initial", "")
	npc.last_name = data.get("last_name", "")
	npc.full_name = "%s %s. %s" % [npc.first_name, npc.middle_initial, npc.last_name]
	# Rebuild gender_vector from JSON string
	var gv = JSON.parse_string(data.get("gender_vector", "{\"x\":0,\"y\":0,\"z\":1}"))
	if typeof(gv) == TYPE_DICTIONARY and gv.has("x") and gv.has("y") and gv.has("z"):
		npc.gender_vector = Vector3(gv.x, gv.y, gv.z)
	else:
		npc.gender_vector = Vector3(0,0,1)
	npc.bio = data.get("bio", "")
	npc.occupation = data.get("occupation", "")
	npc.relationship_status = data.get("relationship_status", "")
	npc.affinity = data.get("affinity", 0.0)
	npc.rizz = data.get("rizz", 0)
	npc.attractiveness = data.get("attractiveness", 0)
	npc.wealth = data.get("wealth", 0)
	npc.alpha = data.get("alpha", 0.0)
	npc.beta = data.get("beta", 0.0)
	npc.gamma = data.get("gamma", 0.0)
	npc.delta = data.get("delta", 0.0)
	npc.omega = data.get("omega", 0.0)
	npc.sigma = data.get("sigma", 0.0)
	var tags_str: String = data.get("tags", "")
	npc.tags = tags_str.split(",") if tags_str.length() > 0 else []
	npc.fumble_bio = data.get("fumble_bio", "")
	return npc

# === BATCH HELPERS ===

func get_batch_of_new_npc_indices(app_name: String, count: int) -> Array[int]:
	var result: Array[int] = []
	for i in range(count):
		var idx = get_recyclable_npc_index_for_app(app_name)
		if idx == -1:
			idx = encounter_count
			encounter_count += 1
		if not encountered_npcs_by_app.has(app_name):
			encountered_npcs_by_app[app_name] = []
		if not encountered_npcs_by_app[app_name].has(idx):
			encountered_npcs_by_app[app_name].append(idx)
		if not active_npcs_by_app.has(app_name):
			active_npcs_by_app[app_name] = []
		if not active_npcs_by_app[app_name].has(idx):
			active_npcs_by_app[app_name].append(idx)
		if not encountered_npcs.has(idx):
			encountered_npcs.append(idx)
		result.append(idx)
	return result

func get_batch_of_recycled_npc_indices(app_name: String, count: int) -> Array[int]:
	var pool: Array[int] = []
	var encountered = encountered_npcs_by_app.get(app_name, [])
	var active = active_npcs_by_app.get(app_name, [])
	for idx in encountered:
		if not active.has(idx) and not persistent_npcs.has(idx):
			pool.append(idx)
	pool.shuffle()
	var result: Array[int] = []
	for idx in pool.slice(0, count):
		result.append(idx)
	return result

func get_recyclable_npc_index_for_app(app_name: String) -> int:
	var encountered = encountered_npcs_by_app.get(app_name, [])
	var active = active_npcs_by_app.get(app_name, [])
	for idx in encountered:
		if not active.has(idx) and not persistent_npcs.has(idx):
			return idx
	return -1

func mark_npc_inactive_in_app(idx: int, app_name: String) -> void:
	if active_npcs_by_app.has(app_name):
		active_npcs_by_app[app_name].erase(idx)

func set_relationship_status(idx: int, app_name: String, status: String) -> void:
	if not relationship_status.has(idx):
		relationship_status[idx] = {}
	relationship_status[idx][app_name] = status
