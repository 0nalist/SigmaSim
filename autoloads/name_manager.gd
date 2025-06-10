# NameManager.gd
extends Node
class_name NameManager

# Type for gendered names (replace with actual Resource or Dictionary if needed)
class GenderedName:
	var name: String
	var fem: float
	var masc: float
	var andro: float

var global_seed: int = 1337  # Assign on new game
var rounds: int = 4  # Feistel shuffle rounds

# Load your custom gendered first names here (replace with your data loading)
var gendered_first_names: Array[GenderedName] = []
var last_names: Array[String] = []
var middle_initials: Array[String] = []

var n_first: int
var n_last: int
var n_mid: int
var N: int

func _ready():
	n_first = gendered_first_names.size()
	n_last = last_names.size()
	n_mid = middle_initials.size() + 1 # +1 for no middle
	N = n_first * n_last * n_mid

# -- Feistel Shuffle for deterministic random order --
func feistel_shuffle(i: int, seed: int, rounds: int = 4) -> int:
	var l = i >> 16
	var r = i & 0xFFFF
	for _ in range(rounds):
		var new_l = r
		var hash_input = str(r) + str(seed)
		var new_r = l ^ hash_string(hash_input)
		l = new_l
		r = new_r
	return ((l << 16) | r) % N

# -- Deterministically get the nth name (shuffled by global_seed) --
func get_name_by_index(i: int) -> Dictionary:
	var shuffled = feistel_shuffle(i, global_seed, rounds)
	var first_idx = shuffled / (n_last * n_mid)
	var last_idx = (shuffled / n_mid) % n_last
	var mid_idx = shuffled % n_mid

	var first_entry = gendered_first_names[first_idx]
	var last = last_names[last_idx]
	var middle = "" if mid_idx == 0 else "%s." % middle_initials[mid_idx - 1]
	return {
		"full_name": ("%s %s %s" % [first_entry.name, middle, last]).strip_edges(),
		"first": first_entry,
		"last": last,
		"middle": middle,
	}

# -- Find a first name matching a gender vector (within a tolerance) --
func find_first_name_by_vector(target: Vector3, tolerance: float = 0.1) -> Array[GenderedName]:
	var results := []
	for n in gendered_first_names:
		var diff = Vector3(n.fem, n.masc, n.andro) - target
		if diff.length() <= tolerance:
			results.append(n)
	return results

# -- Get a random (deterministic) first name by gender vector (best match) --
func get_random_first_name_by_vector(target: Vector3, salt: String = "") -> GenderedName:
	var candidates = find_first_name_by_vector(target)
	if candidates.is_empty():
		return null
	# Deterministic pick: hash salt+target to index
	var pick_rng = RandomNumberGenerator.new()
	pick_rng.seed = hash_string(str(target) + salt)
	return candidates[pick_rng.randi_range(0, candidates.size() - 1)]

# -- Hash function (simple DJB2) --
func hash_string(s: String) -> int:
	var h: int = 5381
	for c in s:
		h = ((h << 5) + h) + c.ord()
	return h & 0x7FFFFFFF

# -- Utility: get all gendered names --
func get_all_first_names() -> Array[GenderedName]:
	return gendered_first_names.duplicate()
