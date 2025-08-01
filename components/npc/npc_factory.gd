class_name NPCFactory


const TRAIT_CONFIG = {
	"wealth": {
		"buckets": [
			{ "cutoff": 0.3, "range": Vector2(-800000, 0) },          # Bottom 30%: Indebted
			{ "cutoff": 0.7, "range": Vector2(-10000, 200000) },      # Next 40%: Middle class
			{ "cutoff": 0.9, "range": Vector2(200000, 1100000) },     # Next 20%: Upper-middle
			{ "cutoff": 0.99, "range": Vector2(1100000, 4000000) },   # Next 9%: Wealthy
			{ "cutoff": 1.0, "range": Vector2(4000000, 50000000000) } # Top 1%: Ultra wealthy
		]
	}
}

static var TAG_DATA = {}
static var LIKE_DATA = {}
static var FUMBLE_BIOS = []








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
	npc.occupation = "Unemployed"
	npc.relationship_status = "Single"

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
	npc.zodiac = PersonalityEngine.get_zodiac(full_name)
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
static func generate_npc_likes(seed: String, like_data: Dictionary, like_count: int = 3) -> Array:
	var selected = []
	var all_likes = like_data.keys()
	if all_likes.size() == 0:
		return []
	var rng = RandomNumberGenerator.new()
	rng.seed = djb2(seed + "like")
	
	var l1 = all_likes[rng.randi_range(0, all_likes.size() - 1)]
	selected.append(l1)
	while selected.size() < like_count:
		var weights = {}
		for l in all_likes:
			if l in selected:
				continue
			var valid = true
			for s in selected:
				if _is_excluded_like(l, s, like_data):
					valid = false
					break
			if not valid:
				continue
			weights[l] = 1
			for s in selected:
				if l in like_data.get(s, {}).get("correlated", []):
					weights[l] += 5
		if weights.size() == 0:
			break
		var weighted_list = []
		for l in weights.keys():
			for i in range(weights[l]):
				weighted_list.append(l)
		var chosen = weighted_list[rng.randi_range(0, weighted_list.size() - 1)]
		selected.append(chosen)
	return selected

static func _is_excluded_like(like_a: String, like_b: String, like_data: Dictionary) -> bool:
	var excl_a = like_data.get(like_a, {}).get("excluded", [])
	var excl_b = like_data.get(like_b, {}).get("excluded", [])
	return like_b in excl_a or like_a in excl_b


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
		if percentile < bucket.cutoff:
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
