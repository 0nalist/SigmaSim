@tool
extends Node

var npc_catalog: Array[Dictionary] = []
var index_by_attractiveness: Array[int] = []
var index_by_gender: Dictionary = {
	"fem": [],
	"masc": [],
	"nb": [],
}

func generate(count: int = -1) -> void:
	npc_catalog.clear()
	index_by_attractiveness.clear()
	for key in index_by_gender.keys():
		index_by_gender[key].clear()

	if NPCFactory.TAG_DATA.is_empty():
		NPCFactory.load_tag_data("res://data/npc_data/traits/tags.json")

	var total: int = NameManager.get_unique_name_count()
	if count <= 0 or count > total:
		count = total
	for i in range(count):
		var name_data = NameManager.get_npc_name_by_index(i)
		var full_name: String = name_data["full_name"]
		var record: Dictionary = {
			"index": i,
			"gender_vector": name_data["gender_vector"],
			"attractiveness": NPCFactory.attractiveness_from_name(full_name),
			"tags": NPCFactory.generate_npc_tags(full_name, NPCFactory.TAG_DATA, 3),
		}
		npc_catalog.append(record)
		index_by_attractiveness.append(i)
		index_by_gender["fem"].append(i)
		index_by_gender["masc"].append(i)
		index_by_gender["nb"].append(i)

	index_by_attractiveness.sort_custom(func(a, b):
		return npc_catalog[a]["attractiveness"] < npc_catalog[b]["attractiveness"])
	index_by_gender["fem"].sort_custom(func(a, b):
		return npc_catalog[a]["gender_vector"].x < npc_catalog[b]["gender_vector"].x)
	index_by_gender["masc"].sort_custom(func(a, b):
		return npc_catalog[a]["gender_vector"].y < npc_catalog[b]["gender_vector"].y)
	index_by_gender["nb"].sort_custom(func(a, b):
		return npc_catalog[a]["gender_vector"].z < npc_catalog[b]["gender_vector"].z)

func get_by_attractiveness_range(min_value: float, max_value: float) -> Array:
	var getter := func(i: int) -> float:
		return npc_catalog[i]["attractiveness"]
	var start := _lower_bound(index_by_attractiveness, min_value, getter)
	var end := _lower_bound(index_by_attractiveness, max_value, getter)
	var result: Array = []
	for n in range(start, end):
		result.append(npc_catalog[index_by_attractiveness[n]])
	return result

func get_by_gender_range(component: String, min_value: float, max_value: float) -> Array:
	if not index_by_gender.has(component):
		return []
	var getter := func(i: int) -> float:
		var gv: Vector3 = npc_catalog[i]["gender_vector"]
		match component:
			"fem":
				return gv.x
			"masc":
				return gv.y
			"nb":
				return gv.z
			_:
				return 0.0
	var arr: Array[int] = index_by_gender[component]
	var start := _lower_bound(arr, min_value, getter)
	var end := _lower_bound(arr, max_value, getter)
	var result: Array = []
	for n in range(start, end):
		result.append(npc_catalog[arr[n]])
	return result

func _lower_bound(arr: Array[int], value: float, getter: Callable) -> int:
	var lo := 0
	var hi := arr.size()
	while lo < hi:
		var mid := (lo + hi) / 2
		if getter.call(arr[mid]) < value:
			lo = mid + 1
		else:
			hi = mid
	return lo
