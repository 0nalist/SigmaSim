class_name PersonalityEngine

const GREEK_FROM_OCEAN = {
	"alpha": {"extraversion": 1.2, "agreeableness": -0.8, "neuroticism": -0.5, "openness": 0.2, "conscientiousness": 0.1},
	"beta": {"agreeableness": 1.0, "neuroticism": 0.4},
	"gamma": {"neuroticism": 1.0, "agreeableness": 0.6},
	"delta": {"conscientiousness": 1.2, "openness": -0.5},
	"omega": {"neuroticism": 1.2, "extraversion": -0.8},
	"sigma": {"openness": 0.9, "conscientiousness": 0.2, "extraversion": -0.6}
}

const MBTI_AXES = [
	["E", "I", "extraversion"],      # High extraversion = E, low = I
	["N", "S", "openness"],          # High openness = N, low = S
	["F", "T", "agreeableness"],     # High agreeableness = F, low = T
	["J", "P", "conscientiousness"], # High conscientiousness = J, low = P
]

const ZODIAC_SIGNS = [
	"Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
	"Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
]

const CHAT_BATTLE_TYPES = [
	"Brat", "Crypto Bro", "Edgelord", "Ghoster", "Gym Rat", "Hypebeast", "Influencer",
	"INTJ", "Irony-poisoned", "Manic Pixie", "Normie", "Nympho", "Pickme", "Romantic",
	"Sapiosexual", "Sigma", "Softie", "Stoner", "Validation-seeker", "Wallflower", "Yuppie"
]

# Data-driven: map chat battle types to OCEAN preference
const CHAT_BATTLE_OCEAN_RULES = {
	"Brat": {"agreeableness": [-100, 45], "extraversion": [50, 100]},
	"Crypto Bro": {"openness": [30, 100], "conscientiousness": [40, 80]},
	"Edgelord": {"agreeableness": [-100, 30], "openness": [30, 100]},
	"Ghoster": {"agreeableness": [-100, 40], "conscientiousness": [-100, 50]},
	"Gym Rat": {"extraversion": [50, 100], "conscientiousness": [60, 100]},
	"Hypebeast": {"openness": [40, 100], "extraversion": [55, 100]},
	"Influencer": {"extraversion": [65, 100], "agreeableness": [40, 100]},
	"INTJ": {"openness": [60, 100], "conscientiousness": [55, 100], "extraversion": [0, 49]},
	"Irony-poisoned": {"openness": [55, 100], "agreeableness": [-100, 60]},
	"Manic Pixie": {"openness": [60, 100], "extraversion": [55, 100]},
	"Normie": {"openness": [0, 40], "conscientiousness": [40, 80]},
	"Nympho": {"extraversion": [70, 100], "openness": [60, 100]},
	"Pickme": {"agreeableness": [60, 100], "conscientiousness": [30, 100]},
	"Romantic": {"agreeableness": [60, 100], "openness": [60, 100]},
	"Sapiosexual": {"openness": [70, 100]},
	"Sigma": {"extraversion": [0, 50], "conscientiousness": [55, 100]},
	"Softie": {"agreeableness": [65, 100], "extraversion": [40, 80]},
	"Stoner": {"conscientiousness": [0, 50]},
	"Validation-seeker": {"agreeableness": [55, 100], "extraversion": [60, 100]},
	"Wallflower": {"extraversion": [0, 35]},
	"Yuppie": {"conscientiousness": [65, 100], "openness": [40, 100]},
}

static func generate_ocean(full_name: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	var traits = ["openness", "conscientiousness", "extraversion", "agreeableness", "neuroticism"]
	var ocean := {}
	for npc_trait in traits:
		rng.seed = djb2(full_name + npc_trait)
		ocean[npc_trait] = clamp(rng.randfn(50.0, 15.0), 0.0, 100.0)
	return ocean

static func get_greek(ocean: Dictionary) -> Dictionary:
	var result = {}
	for stat in GREEK_FROM_OCEAN.keys():
		result[stat] = _normalized_weighted_sum(ocean, GREEK_FROM_OCEAN[stat])
	return result

static func get_mbti(ocean: Dictionary) -> String:
	var mbti = ""
	for axis in MBTI_AXES:
		var val = ocean[axis[2]]
		mbti += axis[0] if val >= 50.0 else axis[1]
	return mbti

static func get_zodiac(full_name: String) -> String:
	var idx = djb2(full_name + "zodiac") % ZODIAC_SIGNS.size()
	return ZODIAC_SIGNS[idx]

static func get_chat_battle_type(ocean: Dictionary, full_name: String) -> String:
	# Try to match rules first; if multiple match, pick most 'on brand' by scoring, else pick pseudo-random
	var best_type = ""
	var best_score = -1.0
	for type in CHAT_BATTLE_OCEAN_RULES.keys():
		var rule = CHAT_BATTLE_OCEAN_RULES[type]
		var score = 0
		var matches = true
		for k in rule.keys():
			var val = ocean[k]
			var bounds = rule[k]
			if val < bounds[0] or val > bounds[1]:
				matches = false
				break
			score += abs(val - (bounds[0] + bounds[1]) * 0.5)
		if matches and (best_score == -1 or score < best_score):
			best_score = score
			best_type = type
	# If none match, pick a deterministic pseudo-random type
	if best_type == "":
		var idx = djb2(full_name + "chat_type") % CHAT_BATTLE_TYPES.size()
		best_type = CHAT_BATTLE_TYPES[idx]
	return best_type

static func _normalized_weighted_sum(data: Dictionary, weights: Dictionary) -> float:
	var sum = 0.0
	var total_weight = 0.0
	for key in weights:
		sum += data.get(key, 50.0) * weights[key]
		total_weight += abs(weights[key])
	if total_weight == 0.0:
		return 50.0
	return clamp(sum / total_weight, 0.0, 100.0)

static func djb2(s: String) -> int:
	var hash := 5381
	for i in s.length():
		hash = ((hash << 5) + hash) + s.unicode_at(i)
	return hash & 0xFFFFFFFF
