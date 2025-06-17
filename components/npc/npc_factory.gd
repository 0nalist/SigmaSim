class_name NPCFactory

static func create_npc(npc_index: int, name_manager: NameManager) -> NPC:
	var name_data = name_manager.get_npc_name_by_index(npc_index)
	var full_name = name_data["full_name"]

	var npc = NPC.new()
	npc.full_name = full_name
	npc.first_name = name_data["first_name"]
	npc.middle_initial = name_data["middle_initial"]
	npc.last_name = name_data["last_name"]
	npc.gender_vector = name_data["gender_vector"]

	npc.affinity = _bounded_trait(full_name, "affinity")
	npc.rizz = _bounded_trait(full_name, "rizz")
	#npc.income = _unbounded_trait(full_name, "income")
	npc.wealth = _unbounded_trait(full_name, "wealth")
	
	# Example: Assign Greek stats deterministically
	npc.alpha = _bounded_trait(full_name, "alpha")
	npc.beta = _bounded_trait(full_name, "beta")
	npc.gamma = _bounded_trait(full_name, "gamma")
	npc.delta = _bounded_trait(full_name, "delta")
	npc.omega = _bounded_trait(full_name, "omega")
	npc.sigma = _bounded_trait(full_name, "sigma")

	# Dummy username generation (customize as needed)
	npc.username = _generate_username(npc)

	# Demo profile_pic (could use a pool or hash to pick an image)
	# npc.profile_pic = pick_profile_pic_based_on_index_or_name(npc_index, full_name)
	npc.bio = "This is a sample auto-generated NPC bio for %s." % npc.first_name
	npc.occupation = "Unemployed"  # Or generate based on stats/seed
	npc.relationship_status = "Single"
	npc.wall_posts = []
	npc.tags = []  # Add any logic for auto-tags here

	npc.preferred_pet_names = _generate_pet_names(full_name, "preferred")
	npc.player_pet_names = _generate_pet_names(full_name, "player")

	return npc


static func _bounded_trait(seed_string: String, trait_name: String) -> float:
	# Returns a deterministic float from -100 to 100
	return float((djb2(seed_string + trait_name) % 201) - 100)

static func _unbounded_trait(seed_string: String, trait_name: String) -> int:
	return djb2(seed_string + trait_name)

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

static func djb2(s: String) -> int:
	var hash := 5381
	for i in s.length():
		hash = ((hash << 5) + hash) + s.unicode_at(i)
	return hash & 0xFFFFFFFF

static func attractiveness_from_name(full_name: String) -> float:
	var z = box_muller(full_name + "A", full_name + "B")
	var bounded = clamp(z, -3.0, 3.0)
	return ((bounded + 3.0) / 6.0) * 100.0

static func _generate_pet_names(seed_string: String, key: String) -> Array[String]:
	# Placeholder—deterministic pet name list per NPC
	return []

static func _generate_username(npc: NPC) -> String:
	# Simple: lowercased first+last name with index, or use a hash
	return (npc.first_name + npc.last_name).to_lower()
