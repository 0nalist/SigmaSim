#class_name NameManager
extends Node

var first_names_json_path: String = "res://data/npc_data/names/first_names.json"
var last_names_json_path: String = "res://data/npc_data/names/last_names.json"
var use_json_for_last_names: bool = true # Set false if you want to load from a .txt

var first_names: Array[GenderedFirstName] = []
var last_names: Array[String] = []
var middle_initials: Array[String] = []
var name_seed: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func set_name_seed(seed: int) -> void:
	name_seed = seed
	_rng.seed = seed

func _ready() -> void:
	# Load names
	_load_first_names()
	_load_last_names()

	# Generate A-Z middle initials
	for ascii in range(65, 91):
		middle_initials.append(String.chr(ascii))
	_rng.seed = name_seed

func _load_first_names() -> void:
	first_names.clear()
	var file = FileAccess.open(first_names_json_path, FileAccess.READ)
	if not file:
		push_error("Couldn't load first names JSON: %s" % first_names_json_path)
		return
	var data = JSON.parse_string(file.get_as_text())
	for entry in data:
		var name: String = entry.get("Name", entry.get("name", ""))
		var fem: float = float(entry.get("Femme", entry.get("fem", "0")))
		var masc: float = float(entry.get("Masc", entry.get("masc", "0")))
		var nb: float = float(entry.get("Enby", entry.get("enby", "0")))
		first_names.append(GenderedFirstName.new(name, Vector3(fem, masc, nb)))

func _load_last_names() -> void:
	last_names.clear()
	if use_json_for_last_names:
		var file = FileAccess.open(last_names_json_path, FileAccess.READ)
		if not file:
			push_error("Couldn't load last names JSON: %s" % last_names_json_path)
			return
		var data = JSON.parse_string(file.get_as_text())
		# Supports both [ {"LastName":"Smith"}, ... ] and [ "Smith", ... ]
		for entry in data:
			if typeof(entry) == TYPE_DICTIONARY:
				last_names.append(entry.values()[0]) # Takes the value if dictionary
			elif typeof(entry) == TYPE_STRING:
				last_names.append(entry)
	else:
		# If using .txt, one last name per line
		var file2 = FileAccess.open(last_names_json_path, FileAccess.READ)
		if not file2:
			push_error("Couldn't load last names TXT: %s" % last_names_json_path)
			return
		last_names = file2.get_as_text().split("\n", false)

func get_random_first_name() -> String:
	if first_names.size() == 0:
		return "FirstName"
	var idx: int = _rng.randi_range(0, first_names.size() - 1)
	return first_names[idx].name

func get_random_last_name() -> String:
	if last_names.size() == 0:
		return "LastName"
	var idx: int = _rng.randi_range(0, last_names.size() - 1)
	return last_names[idx]

func get_npc_name_by_index(npc_index: int) -> Dictionary:
	var total_combos: int = first_names.size() * middle_initials.size() * last_names.size()
	var suffix_num: int = npc_index / total_combos
	var base_index: int = npc_index % total_combos
	var name_index: int = feistel_shuffle(base_index, total_combos, name_seed)

	var first_count: int = first_names.size()
	var middle_count: int = middle_initials.size()
	var last_count: int = last_names.size()

	var first_idx: int = name_index / (middle_count * last_count)
	var middle_idx: int = (name_index / last_count) % middle_count
	var last_idx: int = name_index % last_count

	var gendered_first: GenderedFirstName = first_names[first_idx]
	var middle_initial: String = middle_initials[middle_idx]
	var last_name: String = last_names[last_idx]

	# Suffix logic using int_to_roman and no ternary
	var suffix: String = ""
	if suffix_num > 0:
		var roman: String = int_to_roman(int(suffix_num) + 1)
		# Only add the suffix if it is not "I"
		if roman != "I":
			suffix = " " + roman

	var full_name: String = "%s %s. %s%s" % [gendered_first.name, middle_initial, last_name, suffix]

	return {
		"first_name": gendered_first.name,
		"middle_initial": middle_initial,
		"last_name": last_name,
		"gender_vector": gendered_first.gender_vector,
		"full_name": full_name,
		"gendered_first": gendered_first
	}

func feistel_shuffle(idx: int, size: int, seed: int) -> int:
	# 3 rounds Feistel shuffle for demo (replace with more rounds as desired)
	var l: int = idx & 0xFFFF
	var r: int = idx >> 16
	for i in range(3):
		var new_l: int = r
		var new_r: int = l ^ ((djb2(str(r) + str(seed + i)) & 0xFFFF))
		l = new_l
		r = new_r
	return ((r << 16) | l) % size

func djb2(s: String) -> int:
	var hash: int = 5381
	for i in s.length():
		hash = ((hash << 5) + hash) + s.unicode_at(i)
	return hash & 0xFFFFFFFF

func int_to_roman(n: int) -> String:
	#if n < 2:
	#	return ""
	var numerals: Array = [
		[1000, "M"],
		[900, "CM"],
		[500, "D"],
		[400, "CD"],
		[100, "C"], 
		[90, "XC"],
		[50, "L"],
		[40, "XL"],
		[10, "X"],
		[9, "IX"],
		[5, "V"],
		[4, "IV"],
		[1, "I"]
	]
	var result: String = ""
	var value: int = n
	for pair in numerals:
		while value >= pair[0]:
			result += pair[1]
			value -= pair[0]
	return result
