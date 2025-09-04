class_name NPCFactory


const TRAIT_CONFIG = {
	"wealth": {
		"buckets": [
			{ "cutoff": 0.3, "range": Vector2(-1400000, 0) }, # Bottom 30%: Indebted
			{ "cutoff": 0.7, "range": Vector2(-60000, 60000) },# Next 40%: Middle class
			{ "cutoff": 0.9, "range": Vector2(60000, 1100000) },  # Next 20%: Upper-middle
			{ "cutoff": 0.99, "range": Vector2(1100000, 4000000) },# Next 9%: Wealthy
			{ "cutoff": 1.0, "range": Vector2(4000000, 50000000000) } # Top 1%: Ultra wealthy
		]
	}
}

static var TAG_DATA = {}
static var LIKE_DATA = {}
static var FUMBLE_BIOS = []
static var JOB_LIST: Array[String] = []








# -- M E T H O D S -- #

static func create_npc(npc_index: int) -> NPC:
	var name_data = NameManager.get_npc_name_by_index(npc_index)
	var full_name = name_data["full_name"]

	var npc = NPC.new()
	# Basic Info
	npc.full_name = full_name
	npc.first_name = name_data["first_name"]
	npc.middle_initial = name_data["middle_initial"]
	npc.last_name = name_data["last_name"]
	npc.gender_vector = name_data["gender_vector"]
	npc.username = _generate_username(npc)
	npc.occupation = generate_npc_job(full_name)
	npc.relationship_status = "Single"
	npc.locked_in_connection = true

	# Personality/OCEAN/Greek
	var ocean = PersonalityEngine.generate_ocean(full_name)
	npc.openness = ocean.openness
	npc.conscientiousness = ocean.conscientiousness
	npc.extraversion = ocean.extraversion
	npc.agreeableness = ocean.agreeableness
	npc.neuroticism = ocean.neuroticism
	
	npc.attractiveness = attractiveness_from_name(full_name)

	var greek = PersonalityEngine.get_greek(ocean)
	for stat in greek.keys():
		npc.set(stat, greek[stat])

		npc.mbti = PersonalityEngine.get_mbti(ocean)
		var zodiacs = PersonalityEngine.get_zodiacs(full_name)
		npc.zodiac_sun = zodiacs.sun
		npc.zodiac_moon = zodiacs.moon
		npc.zodiac_rising = zodiacs.rising
		npc.chat_battle_type = PersonalityEngine.get_chat_battle_type(ocean, full_name)

	npc.wealth = generate_multi_bucket_trait(full_name, "wealth")
	
	# Tags/likes must be set BEFORE generating bio

	if "tags" in npc.get_property_list().map(func(x): return x.name):
		npc.tags.clear()
		npc.tags.append_array(generate_npc_tags(full_name, TAG_DATA, 3))
	else:
		push_error("NPC resource missing 'tags' property!")
		if "likes" in npc.get_property_list().map(func(x): return x.name):
				npc.likes.clear()
				npc.likes.append_array(generate_npc_likes(full_name, LIKE_DATA, 3))
		else:
				push_error("NPC resource missing 'likes' property!")
		if "dislikes" in npc.get_property_list().map(func(x): return x.name):
				npc.dislikes.clear()
				npc.dislikes.append_array(generate_npc_dislikes(full_name, LIKE_DATA, npc.likes, 1))
		else:
				push_error("NPC resource missing 'dislikes' property!")

	# The NPC resource always has `tags` and `likes` properties, so we can
	# assign directly without checking the property list. The previous
	# implementation attempted to inspect the property list using
	# `get_property_list().map(func(x): return x.name)`, which was invalid
	# because `get_property_list()` returns an array of dictionaries and
	# accessing `x.name` on a Dictionary triggers a runtime error. That
	# error aborted NPC generation before these fields (and later fields
	# like attractiveness and wealth) were assigned. By removing the faulty
	# check and directly populating the arrays we ensure all NPCs are fully
	# initialised.

	npc.tags.clear()
	npc.tags.append_array(generate_npc_tags(full_name, TAG_DATA, 3))

	npc.likes.clear()
	npc.likes.append_array(generate_npc_likes(full_name, LIKE_DATA, 3))

	npc.dislikes.clear()
	npc.dislikes.append_array(generate_npc_dislikes(full_name, LIKE_DATA, npc.likes, 1))


	# Now generate fumble_bio (dynamic)
	npc.fumble_bio = generate_npc_fumble_bio(npc)

	# Set fallback static bio
	#npc.bio = "This is a sample auto-generated NPC bio for %s." % npc.first_name

	# Pet names
	npc.preferred_pet_names = _generate_pet_names(full_name, "preferred")
	npc.player_pet_names = _generate_pet_names(full_name, "player")

	# Wall posts, etc, if needed...
	# npc.wall_posts = []

	return npc

static func create_npc_from_name(full_name: String) -> NPC:
	var parts: PackedStringArray = full_name.strip_edges().split(" ")

	var first: String = ""
	if parts.size() > 0:
		first = parts[0]

	var middle: String = ""
	if parts.size() > 2:
		middle = parts[1].left(1).to_upper()

	var last: String = ""
	if parts.size() > 1:
		last = parts[parts.size() - 1]

	var npc := NPC.new()
	npc.full_name = full_name
	npc.first_name = first
	npc.middle_initial = middle
	npc.last_name = last
	npc.gender_vector = _gender_vector_from_first(first)
	npc.username = _generate_username(npc)
	npc.occupation = generate_npc_job(full_name)
	npc.relationship_status = "Single"
	npc.locked_in_connection = true

	var ocean := PersonalityEngine.generate_ocean(full_name)
	npc.ocean = ocean
	npc.openness = ocean.openness
	npc.conscientiousness = ocean.conscientiousness
	npc.extraversion = ocean.extraversion
	npc.agreeableness = ocean.agreeableness
	npc.neuroticism = ocean.neuroticism

	npc.attractiveness = attractiveness_from_name(full_name)

	var greek := PersonalityEngine.get_greek(ocean)
	for stat in greek.keys():
			npc.set(stat, greek[stat])

	npc.mbti = PersonalityEngine.get_mbti(ocean)
	var zodiacs = PersonalityEngine.get_zodiacs(full_name)
	npc.zodiac_sun = zodiacs.sun
	npc.zodiac_moon = zodiacs.moon
	npc.zodiac_rising = zodiacs.rising
	npc.chat_battle_type = PersonalityEngine.get_chat_battle_type(ocean, full_name)

	npc.wealth = generate_multi_bucket_trait(full_name, "wealth")

	npc.tags.clear()
	npc.tags.append_array(generate_npc_tags(full_name, TAG_DATA, 3))

	npc.likes.clear()
	npc.likes.append_array(generate_npc_likes(full_name, LIKE_DATA, 3))

	npc.dislikes.clear()
	npc.dislikes.append_array(generate_npc_dislikes(full_name, LIKE_DATA, npc.likes, 1))

	npc.fumble_bio = generate_npc_fumble_bio(npc)

	npc.preferred_pet_names = _generate_pet_names(full_name, "preferred")
	npc.player_pet_names = _generate_pet_names(full_name, "player")

	npc.portrait_config = PortraitFactory.generate_config_for_name(full_name)

	return npc

static func _gender_vector_from_first(first: String) -> Vector3:
		for entry in NameManager.first_names:
				if entry.name.to_lower() == first.to_lower():
						return entry.gender_vector
		return Vector3(0, 0, 1)




# --- Initialization --- #
static func load_tag_data(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		TAG_DATA = JSON.parse_string(file.get_as_text())
		# Remove "nan" entries from arrays
		for k in TAG_DATA.keys():
			TAG_DATA[k]["correlated"] = TAG_DATA[k].get("correlated", []).filter(func(x): return x != "nan")
			TAG_DATA[k]["excluded"] = TAG_DATA[k].get("excluded", []).filter(func(x): return x != "nan")

static func load_like_data(path: String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
				LIKE_DATA = JSON.parse_string(file.get_as_text())
				for k in LIKE_DATA.keys():
						LIKE_DATA[k]["correlated"] = LIKE_DATA[k].get("correlated", []).filter(func(x): return x != "nan")
						LIKE_DATA[k]["excluded"] = LIKE_DATA[k].get("excluded", []).filter(func(x): return x != "nan")

static func load_fumble_bios(path: String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
				FUMBLE_BIOS = JSON.parse_string(file.get_as_text())

static func load_job_data(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_ARRAY:
					JOB_LIST.clear()
					for j in parsed:
							JOB_LIST.append(String(j))


# --- Tag generation (with correlation/exclusion) --- #
static func generate_npc_tags(seed: String, tag_data: Dictionary, tag_count: int = 3) -> Array:
	var selected = []
	var all_tags = tag_data.keys()
	if all_tags.size() == 0:
		return [] # Defensive: no tags available
	var rng = RandomNumberGenerator.new()
	rng.seed = djb2(seed + "tag")
	
	var t1 = all_tags[rng.randi_range(0, all_tags.size() - 1)]
	selected.append(t1)
	while selected.size() < tag_count:
		var weights = {}
		for t in all_tags:
			if t in selected:
				continue
			var valid = true
			for s in selected:
				if _is_excluded_tag(t, s, tag_data):
					valid = false
					break
			if not valid:
				continue
			weights[t] = 1
			for s in selected:
				if t in tag_data.get(s, {}).get("correlated", []):
					weights[t] += 5
		if weights.size() == 0:
			break
		var weighted_list = []
		for t in weights.keys():
			for i in range(weights[t]):
				weighted_list.append(t)
		var chosen = weighted_list[rng.randi_range(0, weighted_list.size() - 1)]
		selected.append(chosen)
	return selected

static func _is_excluded_tag(tag_a: String, tag_b: String, tag_data: Dictionary) -> bool:
	var excl_a = tag_data.get(tag_a, {}).get("excluded", [])
	var excl_b = tag_data.get(tag_b, {}).get("excluded", [])
	return tag_b in excl_a or tag_a in excl_b

# --- Likes generation (can use same correlation/exclusion logic) --- #
static func generate_npc_likes(seed: String, like_data: Dictionary, like_count: int = 3) -> Array[String]:
	var result: Array[String] = []
	if like_count <= 0:
		return result

	# Collect keys as strings deterministically from provided data.
	var all_likes: Array[String] = []
	for k in like_data.keys():
		all_likes.append(String(k))
	if all_likes.is_empty():
		return result

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = djb2(seed + "like")

	# Never ask for more than we can possibly pick.
	var target_count: int = min(like_count, all_likes.size())

	# Pick the first like uniformly.
	var first_index: int = rng.randi_range(0, all_likes.size() - 1)
	result.append(all_likes[first_index])

	# Subsequent picks are weighted by correlations (+5 each) and exclude conflicts.
	while result.size() < target_count:
		var weights: Dictionary = {} # Dictionary[String, int]
		for l_untyped in all_likes:
			var l: String = String(l_untyped)
			if result.has(l):
				continue

			var valid: bool = true
			for s in result:
				if _is_excluded_like(l, s, like_data):
					valid = false
					break
			if not valid:
				continue

			var w: int = 1
			for s in result:
				var s_data: Dictionary = like_data.get(s, {})
				var correlated: Array = s_data.get("correlated", [])
				if correlated.has(l):
					w += 5
			weights[l] = w
		if weights.is_empty():
			break

		# Roulette-wheel selection (no big temporary arrays).
		var total_w: int = 0
		for l_key in weights.keys():
			total_w += int(weights[l_key])

		var ticket: int = rng.randi_range(1, total_w)
		var running: int = 0
		var chosen: String = ""
		for l_key in weights.keys():
			running += int(weights[l_key])
			if ticket <= running:
				chosen = String(l_key)
				break
		if chosen == "":
			# Fallback (shouldn't happen, but avoid infinite loop)
			var any_key: String = String(weights.keys()[0])
			chosen = any_key

		result.append(chosen)

	return result
static func _is_excluded_like(like_a: String, like_b: String, like_data: Dictionary) -> bool:
		var excl_a = like_data.get(like_a, {}).get("excluded", [])
		var excl_b = like_data.get(like_b, {}).get("excluded", [])
		return like_b in excl_a or like_a in excl_b

static func generate_npc_dislikes(seed: String, like_data: Dictionary, existing_likes: Array, dislike_count: int = 1) -> Array:
				var available = like_data.keys().duplicate()
				for l in existing_likes:
								available.erase(l)
				if available.size() == 0:
								return []
				var rng = RandomNumberGenerator.new()
				rng.seed = djb2(seed + "dislike")
				var selected = []
				while selected.size() < dislike_count and available.size() > 0:
								var chosen = available[rng.randi_range(0, available.size() - 1)]
								selected.append(chosen)
								available.erase(chosen)
				return selected

static func generate_npc_job(seed: String) -> String:
	if JOB_LIST.size() == 0:
			return "Unemployed"
	var rng = RandomNumberGenerator.new()
	rng.seed = djb2(seed + "job")
	return JOB_LIST[rng.randi_range(0, JOB_LIST.size() - 1)]


# Returns a random bio_dict from FUMBLE_BIOS, weighted by .weight
static func pick_weighted_bio(rng: RandomNumberGenerator) -> Dictionary:
	if FUMBLE_BIOS.size() == 0:
		return {}
	var total_weight = 0.0
	for bio_dict in FUMBLE_BIOS:
		total_weight += bio_dict.get("weight", 1.0)
	var r = rng.randf_range(0, total_weight)
	for bio_dict in FUMBLE_BIOS:
		r -= bio_dict.get("weight", 1.0)
		if r < 0:
			return bio_dict
	# Fallback: last one
	return FUMBLE_BIOS[FUMBLE_BIOS.size() - 1]



static func generate_npc_fumble_bio(npc: NPC) -> String:
	if FUMBLE_BIOS.size() == 0:
		return ""
	var rng = RandomNumberGenerator.new()
	# Seed using full_name or another property if you want deterministic results for an NPC
	rng.seed = djb2(npc.full_name + "bio_weighted")
	var bio_dict = pick_weighted_bio(rng)
	var bio_template = bio_dict.get("bio", "")
	return MarkupParser.parse(bio_template, npc)






# ---- Trait generation helpers ----

static func generate_multi_bucket_trait(seed_string: String, trait_name: String) -> int:
	if not TRAIT_CONFIG.has(trait_name):
		push_error("No config for trait %s" % trait_name)
		return 0

	var buckets = TRAIT_CONFIG[trait_name].buckets
	var percentile = float(_bounded_trait(seed_string, trait_name) + 100) / 200.0  # [0,1]
	for bucket in buckets:
		# Allow the upper bound of the final bucket by checking <=
		if percentile <= bucket.cutoff:
			var r = bucket.range
			var val = int(deterministic_randf(seed_string + str(bucket.cutoff)) * (r.y - r.x + 1)) + int(r.x)
			return val
	push_error("Percentile did not match a bucket in trait %s" % trait_name)
	return 0

static func assign_greek_stats(npc: NPC, seed_string: String) -> void:
	var greek_stats = ["alpha", "beta", "gamma", "delta", "omega", "sigma"]
	
	# Deterministically select primary stat
	var primary_idx = djb2(seed_string + "primary_greek_stat") % greek_stats.size()
	var primary_stat = greek_stats[primary_idx]
	
	# Set all stats
	for stat in greek_stats:
		if stat == primary_stat:
			npc.set(stat, 60 + int(deterministic_randf(seed_string + stat) * 41))  # 60–100
		else:
			npc.set(stat, int(deterministic_randf(seed_string + stat) * 60))  # 0–59

func get_primary_greek_stat() -> String:
	var greek_stats = ["alpha", "beta", "gamma", "delta", "omega", "sigma"]
	var max_val = -1
	var primary = ""
	for stat in greek_stats:
		var val = self.get(stat)
		if val > max_val:
			max_val = val
			primary = stat
	return primary


static func _bounded_trait(seed_string: String, trait_name: String) -> float:
	return float((djb2(seed_string + trait_name) % 201) - 100)

static func _secondary_trait_value(seed_string: String, suffix: String) -> int:
	return djb2(seed_string + suffix)

static func djb2(s: String) -> int:
	var hash := 5381
	for i in s.length():
		hash = ((hash << 5) + hash) + s.unicode_at(i)
	return hash & 0xFFFFFFFF

# --- Normal Distribution Attractiveness [0,100] ---
static func deterministic_randf(seed: String) -> float:
	var rng = RandomNumberGenerator.new()
	rng.seed = djb2(seed)
	return rng.randf()

static func box_muller(seed_a: String, seed_b: String) -> float:
	var u1 = deterministic_randf(seed_a)
	var u2 = deterministic_randf(seed_b)
	if u1 <= 0.0:
		u1 = 0.000001
	var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	return z0

static func attractiveness_from_name(full_name: String) -> float:
	var u1 = deterministic_randf(full_name + "A")
	var u2 = deterministic_randf(full_name + "B")
	if u1 <= 0.0:
		u1 = 0.000001
	var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	var bounded = clamp(z0, -3.0, 3.0)
	return ((bounded + 3.0) / 6.0) * 100.0


# --- Placeholder for pet names/username ---
static func _generate_pet_names(seed_string: String, key: String) -> Array[String]:
	return []

static func _generate_username(npc: NPC) -> String:
	return (npc.first_name + npc.last_name).to_lower()
