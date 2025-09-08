@tool
extends Node

var npc_catalog: Array[Dictionary] = []
var index_by_attractiveness: Array[int] = []
var index_by_gender: Dictionary = {
	"fem": [],
	"masc": [],
	"nb": [],
}

# When the pool of NPC records runs low we proactively extend the
# catalogue.  These defaults provide a reasonable buffer for the game
# but can be overridden in tests or from the editor.
var extend_threshold: int = 100
var extend_batch_size: int = 100

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

# Ensures the catalogue always maintains a minimum number of
# unencountered NPC entries.  When the remaining unencountered count
# falls below `min_unencountered` we regenerate the catalogue with an
# additional `batch_size` entries.  Regeneration is deterministic
# because each NPC's data is derived from its index and the global name
# seed, so existing indices retain their original names and traits.
func ensure_unencountered(min_unencountered: int = extend_threshold, batch_size: int = extend_batch_size) -> void:
		var encountered := 0
		if Engine.has_singleton("NPCManager"):
				encountered = NPCManager.encountered_npcs.size()
		var remaining: int = npc_catalog.size() - encountered
		if remaining < min_unencountered:
				var target := npc_catalog.size() + batch_size
				generate(target)

# Ensures the catalogue keeps a buffer of unencountered NPCs that match
# incoming query filters. Currently gender similarity and minimum
# attractiveness are supported. When the remaining unencountered count of
# matching entries falls below `min_unencountered` the catalogue is
# regenerated with an additional `batch_size` entries.
func ensure_filtered_unencountered(filters: Dictionary, min_unencountered: int = extend_threshold, batch_size: int = extend_batch_size) -> void:
				if min_unencountered <= 0:
								return

				var pref_gender: Vector3 = filters.get("gender_similarity_vector", Vector3.ZERO)
				var min_gender: float = float(filters.get("min_gender_similarity", 0.0))
				var min_attr: float = float(filters.get("min_attractiveness", 0.0))

				var check_gender := pref_gender != Vector3.ZERO and min_gender > 0.0
				var check_attr := min_attr > 0.0
				if not check_gender and not check_attr:
								return

				var encountered: Dictionary = {}
				if Engine.has_singleton("NPCManager"):
								for idx in NPCManager.encountered_npcs:
												encountered[int(idx)] = true

				var remaining := 0
				for record in npc_catalog:
								var idx: int = int(record["index"])
								if encountered.has(idx):
												continue
								if check_attr and float(record.get("attractiveness", 0.0)) < min_attr:
												continue
								if check_gender:
												var gv: Vector3 = record.get("gender_vector", Vector3.ZERO)
												if gender_dot_similarity(pref_gender, gv) < min_gender:
																continue
								remaining += 1

				if remaining < min_unencountered:
								var target := npc_catalog.size() + batch_size
								generate(target)

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

func gender_dot_similarity(a: Vector3, b: Vector3) -> float:
		if a.length() == 0 or b.length() == 0:
				return 0.0
		return a.dot(b) / (a.length() * b.length())
