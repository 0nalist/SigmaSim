#class_name NameManager
extends Node

var first_names_json_path: String = "res://data/npc_data/names/first_names.json"
var last_names_json_path: String = "res://data/npc_data/names/last_names.json"
var use_json_for_last_names: bool = true # Set false if you want to load from a .txt

var first_names: Array[GenderedFirstName] = []
var last_names: Array[String] = []
var middle_initials: Array[String] = []
var global_seed: int = 123456

func _ready():
	# Load names
	_load_first_names()
	_load_last_names()

	# Generate A-Z middle initials
	for ascii in range(65, 91):
		middle_initials.append(String.chr(ascii))

func _load_first_names():
	first_names.clear()
	var file = FileAccess.open(first_names_json_path, FileAccess.READ)
	if not file:
		push_error("Couldn't load first names JSON: %s" % first_names_json_path)
		return
	var data = JSON.parse_string(file.get_as_text())
	for entry in data:
		var name = entry.get("Name", entry.get("name", ""))
		var fem = float(entry.get("Femme", entry.get("fem", "0")))
		var masc = float(entry.get("Masc", entry.get("masc", "0")))
		var nb = float(entry.get("Enby", entry.get("enby", "0")))
		first_names.append(GenderedFirstName.new(name, Vector3(fem, masc, nb)))

func _load_last_names():
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
		var file = FileAccess.open(last_names_json_path, FileAccess.READ)
		if not file:
			push_error("Couldn't load last names TXT: %s" % last_names_json_path)
			return
		last_names = file.get_as_text().split("\n", false)

func get_npc_name_by_index(npc_index: int) -> Dictionary:
	var total_combos = first_names.size() * middle_initials.size() * last_names.size()
	var suffix_num = npc_index / total_combos
	var base_index = npc_index % total_combos
	var name_index = feistel_shuffle(base_index, total_combos, global_seed)

	var first_count = first_names.size()
	var middle_count = middle_initials.size()
	var last_count = last_names.size()

	var first_idx = name_index / (middle_count * last_count)
	var middle_idx = (name_index / last_count) % middle_count
	var last_idx = name_index % last_count

	var gendered_first = first_names[first_idx]
	var middle_initial = middle_initials[middle_idx]
	var last_name = last_names[last_idx]

	# Suffix logic using int_to_roman and no ternary
	var suffix = ""
	if suffix_num > 0:
		var roman = int_to_roman(int(suffix_num) + 1)
		# Only add the suffix if it is not "I"
		if roman != "I":
			suffix = " " + roman

	var full_name = "%s %s. %s%s" % [gendered_first.name, middle_initial, last_name, suffix]

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
	var l = idx & 0xFFFF
	var r = idx >> 16
	for i in range(3):
		var new_l = r
		var new_r = l ^ ((djb2(str(r) + str(seed + i)) & 0xFFFF))
		l = new_l
		r = new_r
	return ((r << 16) | l) % size

func djb2(s: String) -> int:
	var hash := 5381
	for i in s.length():
		hash = ((hash << 5) + hash) + s.unicode_at(i)
	return hash & 0xFFFFFFFF


func int_to_roman(n: int) -> String:
	#if n < 2:
	#	return ""
	var numerals = [
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
	var result = ""
	var value = n
	for pair in numerals:
		while value >= pair[0]:
			result += pair[1]
			value -= pair[0]
	return result
