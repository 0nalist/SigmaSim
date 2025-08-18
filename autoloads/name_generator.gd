##
# DEPRECATED !!!!!!!!!!!!!!!!!!!!
## Old Work_Force is dependent on this, delete after completing WorkForce redesign

extends Node
# Autoload name: NameGenerator

# Vector3(x = femininity, y = masculinity, z = enbygyny)
class NameEntry:
	var name: String
	var gender_vector: Vector3
	
	func _init(_name: String, _vector: Vector3):
		name = _name
		gender_vector = _vector

# --- Config and State ---
var name_pool: Array[NameEntry] = []
var recent_names: Array[String] = []
const RECENT_NAME_LIMIT := 50

# --- Init ---
func _ready():
	# Optional manual entries
	#_add_name("Jack", Vector3(0.0, 1.0, 0.0))
	#_add_name("Sophia", Vector3(1.0, 0.0, 0.0))
	#_add_name("Xylo", Vector3(0.0, 0.0, 0.1))

	load_from_json("res://data/names.json")
	print("✅ NameGenerator loaded %d names" % name_pool.size())

# --- Public API ---
func get_random_name(fem: float = 0.0, masc: float = 0.0, enby: float = 0.0, top_n: int = 1) -> String:
if name_pool.is_empty():
printerr("⚠️ Name pool is empty!")
return "Unnamed"

var rng = RNGManager.get_rng()

if fem + masc + enby == 0.0:
# Choose random name when called without arguments
var available := name_pool.map(func(e): return e.name)
_shuffle_array(available, rng)
var new_name = available[0]
_add_to_recent(new_name)
return new_name

var target_vector := Vector3(fem, masc, enby).normalized()
var scored_names: Array = []

	# Score all names
	for entry in name_pool:
		var score := entry.gender_vector.dot(target_vector)
		scored_names.append({ "name": entry.name, "score": score })

	if scored_names.is_empty():
		printerr("⚠️ No names could be scored.")
		return "Unnamed"

	# --- TOP N MODE ---
if top_n > 0:
scored_names.sort_custom(func(a, b): return b["score"] < a["score"])
var top_candidates := scored_names.slice(0, min(top_n, scored_names.size()))
_shuffle_array(top_candidates, rng)
var name = top_candidates[0]["name"]
_add_to_recent(name)
return name

	# --- WEIGHTED RANDOMNESS ---
	var weighted_pool: Array[String] = []
	for entry in scored_names:
		var base_weight := pow(entry["score"], 2)
		var recency_weight := _recency_weight(entry["name"])
		var final_weight := base_weight * recency_weight
		for _i in range(int(final_weight * 10)):
			weighted_pool.append(entry["name"])

	# Fallback: use unweighted full pool if weighting failed
	if weighted_pool.is_empty():
		printerr("🟡 Weighted pool empty, using full fallback.")
		for entry in name_pool:
			weighted_pool.append(entry.name)

	if weighted_pool.is_empty():
		printerr("❌ All fallback methods failed.")
		return "Unnamed"

var name := weighted_pool[rng.randi() % weighted_pool.size()]
	_add_to_recent(name)
	return name

# --- Recency dampening (1.0 = fresh, 0.1 = just used) ---
func _recency_weight(name: String) -> float:
	var index := recent_names.find(name)
	if index == -1:
		return 1.0  # Not recent
	return clamp(1.0 - float(index) / RECENT_NAME_LIMIT, 0.1, 1.0)

# --- Track used names ---
func _add_to_recent(name: String):
recent_names.push_front(name)
if recent_names.size() > RECENT_NAME_LIMIT:
recent_names.pop_back()

func _shuffle_array(arr: Array, rng: RandomNumberGenerator) -> void:
for i in range(arr.size() - 1, 0, -1):
var j = rng.randi_range(0, i)
arr.swap(i, j)

# --- Add a name to the pool ---
func _add_name(name: String, gender_vector: Vector3):
	name_pool.append(NameEntry.new(name, gender_vector))

# --- Load from JSON ---
func load_from_json(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("❌ Failed to open name JSON: ", path)
		return

	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_ARRAY:
		printerr("❌ Invalid name data — expected array.")
		return

	for entry in data:
		var name = entry.get("name", "")
		var vector := Vector3(entry.get("fem", 0.0), entry.get("masc", 0.0), entry.get("enby", 0.0))
		_add_name(name, vector)
