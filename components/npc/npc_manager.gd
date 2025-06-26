#Autoload NPCManager
extends Node

# === Index and Tracking ===
var encounter_count: int = 0                              # Next available NPC index
var encountered_npcs: Array[int] = []                     # All NPCs ever generated
var encountered_npcs_by_app: Dictionary = {}              # { "fumble": [idx1, ...], "hiring": [idxN, ...] }
var active_npcs_by_app: Dictionary = {}                   # { "fumble": [idxA, ...], ... }

# === Relationships/State ===
var relationship_status: Dictionary = {}                  # idx -> { "fumble": "liked", ... }
var persistent_npcs: Dictionary = {}                      # idx -> override dict (permanent)
var npc_overrides: Dictionary = {}                        # idx -> override dict (ephemeral)
var npcs: Dictionary = {}                                 # idx -> live NPC cache (not saved)

# === Buckets/Groups for persistent NPCs ===
var persistent_by_gender: Dictionary = {}                 # e.g. { "f": [idx, ...] }
var persistent_by_wealth: Dictionary = {}

# === Swipe Pool Helpers ===

# Fetches a batch of new NPC indices (prioritizes never-before-seen or unused/recyclable, marks as encountered/active)
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

# Fetches a batch of recycled (previously-seen but currently inactive) NPC indices for this app
func get_batch_of_recycled_npc_indices(app_name: String, count: int) -> Array[int]:
	var pool = []
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



# (Optional: Exclude recent IDs, see last message if you want this)

# === Main API ===

# Get (or create) an NPC index for the app, returning the NPC object
func encounter_new_npc_for_app(app_name: String) -> int:
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
	# (You do not need to create/store the NPC object here)
	return idx


# Mark this NPC as inactive in a given app (slot is recyclable for that app)
func mark_npc_inactive_in_app(idx: int, app_name: String) -> void:
	if active_npcs_by_app.has(app_name):
		active_npcs_by_app[app_name].erase(idx)

# Get an unused (recyclable) NPC index for the given app
func get_recyclable_npc_index_for_app(app_name: String) -> int:
	var encountered = encountered_npcs_by_app.get(app_name, [])
	var active = active_npcs_by_app.get(app_name, [])
	for idx in encountered:
		if not active.has(idx) and not persistent_npcs.has(idx):
			return idx
	return -1

# Lookup by index (applies overrides if any)
func get_npc_by_index(idx: int) -> NPC:
	if npcs.has(idx):
		return npcs[idx]
	var npc = NPCFactory.create_npc(idx)
	var data = persistent_npcs.get(idx, npc_overrides.get(idx, {}))
	for key in data.keys():
		npc.set(key, data[key])
	npcs[idx] = npc
	return npc

# Set a field (writes to persistent dict if needed)
func set_npc_field(idx: int, field: String, value) -> void:
	if not npcs.has(idx):
		push_error("Tried to set a field on a non-existent NPC!")
		return
	npcs[idx].set(field, value)
	if persistent_npcs.has(idx):
		persistent_npcs[idx][field] = value
	else:
		if not npc_overrides.has(idx):
			npc_overrides[idx] = {}
		npc_overrides[idx][field] = value

# Promote NPC to persistent status, index in relevant buckets
func promote_to_persistent(idx: int) -> void:
	if not persistent_npcs.has(idx):
		persistent_npcs[idx] = npc_overrides.get(idx, {}).duplicate()
		npc_overrides.erase(idx)
		_index_persistent_npc(idx)

# Helper: get index from NPC object (used in FumbleUI)
func get_npc_index(npc: NPC) -> int:
	for idx in npcs.keys():
		if npcs[idx] == npc:
			return idx
	return -1

# Relationship status (liked, matched, etc)
func set_relationship_status(idx: int, app_name: String, status: String) -> void:
	if not relationship_status.has(idx):
		relationship_status[idx] = {}
	relationship_status[idx][app_name] = status

# === Bucket Management ===

# Index persistent NPC in buckets for fast lookups
func _index_persistent_npc(idx: int) -> void:
	var npc = get_npc_by_index(idx)
	# Gender bucket (very basic, adapt as needed)
	var g = "nb"
	if npc.gender_vector.x > 0.5: g = "f"
	if npc.gender_vector.y > 0.5: g = "m"
	if not persistent_by_gender.has(g):
		persistent_by_gender[g] = []
	persistent_by_gender[g].append(idx)
	# Wealth bucket
	var w = "middle"
	if npc.wealth < 0: w = "poor"
	elif npc.wealth > 1_000_000: w = "rich"
	if not persistent_by_wealth.has(w):
		persistent_by_wealth[w] = []
	persistent_by_wealth[w].append(idx)

# Utility: get random persistent NPCs by bucket
func get_random_persistent_indices(bucket_dict: Dictionary, count: int) -> Array[int]:
	var indices = []
	for arr in bucket_dict.values():
		indices += arr
	indices.shuffle()
	return indices.slice(0, count)

# Utility: composable filter (pass a lambda)
func get_random_npcs(filter_func: Callable, count: int) -> Array[int]:
	var pool = []
	for idx in persistent_npcs.keys():
		var npc = get_npc_by_index(idx)
		if filter_func.call(npc):
			pool.append(idx)
	pool.shuffle()
	return pool.slice(0, count)

# ----------------------------------------
# Save / Load (unchanged from earlier, just add new buckets if you serialize them)
# ----------------------------------------

func to_dict() -> Dictionary:
	return {
		"encounter_count": encounter_count,
		"encountered_npcs": encountered_npcs,
		"encountered_npcs_by_app": encountered_npcs_by_app,
		"active_npcs_by_app": active_npcs_by_app,
		"relationship_status": relationship_status,
		"persistent_npcs": persistent_npcs,
		"npc_overrides": npc_overrides,
		# Add any new buckets if you want
	}

func from_dict(data: Dictionary):
	encounter_count = data.get("encounter_count", 0)
	encountered_npcs = data.get("encountered_npcs", [])
	encountered_npcs_by_app = data.get("encountered_npcs_by_app", {})
	active_npcs_by_app = data.get("active_npcs_by_app", {})
	relationship_status = data.get("relationship_status", {})
	persistent_npcs = data.get("persistent_npcs", {})
	npc_overrides = data.get("npc_overrides", {})
	npcs.clear()
	persistent_by_gender.clear()
	persistent_by_wealth.clear()
	for idx in persistent_npcs.keys():
		_index_persistent_npc(idx)
