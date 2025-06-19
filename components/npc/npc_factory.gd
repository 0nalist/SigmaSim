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



# -- M E T H O D S -- #

static func create_npc(npc_index: int) -> NPC:
	var name_data = NameManager.get_npc_name_by_index(npc_index)
	var full_name = name_data["full_name"]

	var npc = NPC.new()
	npc.full_name = full_name
	npc.first_name = name_data["first_name"]
	npc.middle_initial = name_data["middle_initial"]
	npc.last_name = name_data["last_name"]
	npc.gender_vector = name_data["gender_vector"]

	npc.affinity = _bounded_trait(full_name, "affinity")
	npc.rizz = _bounded_trait(full_name, "rizz")
	
	# --- Multi-bucket Wealth ---
	npc.wealth = generate_multi_bucket_trait(full_name, "wealth")

	# --- Attractiveness as normal distribution [0,100] ---
	npc.attractiveness = attractiveness_from_name(full_name)

	# Greek stats
	assign_greek_stats(npc, full_name)


	npc.username = _generate_username(npc)
	npc.bio = "This is a sample auto-generated NPC bio for %s." % npc.first_name
	npc.occupation = "Unemployed"
	npc.relationship_status = "Single"
	npc.wall_posts = [] as Array[String]
	npc.tags = [] as Array[String]

	npc.preferred_pet_names = _generate_pet_names(full_name, "preferred")
	npc.player_pet_names = _generate_pet_names(full_name, "player")

	return npc

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
	var h = djb2(seed)
	return float(h % 1000000) / 1000000.0

static func box_muller(seed_a: String, seed_b: String) -> float:
	var u1 = deterministic_randf(seed_a)
	var u2 = deterministic_randf(seed_b)
	if u1 <= 0.0:
		u1 = 0.000001
	var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	return z0

static func attractiveness_from_name(full_name: String) -> float:
	var z = box_muller(full_name + "A", full_name + "B")
	var bounded = clamp(z, -3.0, 3.0)
	return ((bounded + 3.0) / 6.0) * 100.0

# --- Placeholder for pet names/username ---
static func _generate_pet_names(seed_string: String, key: String) -> Array[String]:
	return []

static func _generate_username(npc: NPC) -> String:
	return (npc.first_name + npc.last_name).to_lower()
