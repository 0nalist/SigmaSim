#class_name NameManager
extends Node

var first_names: Array[GenderedFirstName] = []
var middle_initials: Array[String] = []
var last_names: Array[String] = []
var global_seed: int = 123456

func _ready():
	# Dummy first names (with sample gender vectors)
	first_names.append(GenderedFirstName.new("Alex", Vector3(0.7, 0.2, 0.1)))
	first_names.append(GenderedFirstName.new("Jordan", Vector3(0.5, 0.4, 0.1)))
	first_names.append(GenderedFirstName.new("Morgan", Vector3(0.33, 0.33, 0.34)))

	# Middle initials: A-Z
	for ascii in range(65, 91):  # 65 = 'A', 90 = 'Z'
		middle_initials.append(String.chr(ascii))

	# Dummy last names
	last_names.append("Smith")
	last_names.append("Patel")
	last_names.append("Rivera")

func get_npc_name_by_index(npc_index: int) -> Dictionary:
	var total_combos = first_names.size() * middle_initials.size() * last_names.size()
	assert(npc_index < total_combos)

	var name_index = feistel_shuffle(npc_index, total_combos, global_seed)

	var first_count = first_names.size()
	var middle_count = middle_initials.size()
	var last_count = last_names.size()

	var first_idx = name_index / (middle_count * last_count)
	var middle_idx = (name_index / last_count) % middle_count
	var last_idx = name_index % last_count

	var gendered_first = first_names[first_idx]
	var middle_initial = middle_initials[middle_idx]
	var last_name = last_names[last_idx]

	return {
		"first_name": gendered_first.name,
		"middle_initial": middle_initial,
		"last_name": last_name,
		"gender_vector": gendered_first.gender_vector,
		"full_name": "%s %s. %s" % [gendered_first.name, middle_initial, last_name],
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
