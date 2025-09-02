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
	"Crypto Bro": {"openness": [50, 100], "conscientiousness": [0, 45]},
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

static func get_zodiacs(full_name: String) -> Dictionary:
		return {
				"sun": ZODIAC_SIGNS[djb2(full_name + "zodiac_sun") % ZODIAC_SIGNS.size()],
				"moon": ZODIAC_SIGNS[djb2(full_name + "zodiac_moon") % ZODIAC_SIGNS.size()],
				"rising": ZODIAC_SIGNS[djb2(full_name + "zodiac_rising") % ZODIAC_SIGNS.size()],
		}

static func get_zodiac(full_name: String) -> String:
		return get_zodiacs(full_name)["sun"]

static func get_chat_battle_type(ocean: Dictionary, seed: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = djb2(seed + "_cbt")      # still 100 % deterministic per NPC

	var scores: Dictionary = {}         # {type: raw_score}
	for t in CHAT_BATTLE_TYPES:
		scores[t] = _rule_match_score(ocean, CHAT_BATTLE_OCEAN_RULES.get(t, {}))

	# --- convert to weights ---
	var total := 0.0
	for t in scores:
		scores[t] = max(scores[t], 0.01)   # keep everything >0
		total += scores[t]

	# target an **even prior** by inverting the weight:
	var weights := {}
	for t in scores:
		weights[t] = (1.0 / total) * scores[t]      # flatten high peaks

	# --- deterministic, weighted pick ---
	var roll := rng.randf()
	for t in weights:
		roll -= weights[t]
		if roll <= 0.0:
			return t

	return CHAT_BATTLE_TYPES[0]                    # fallback (shouldn’t hit)

static func _rule_match_score(o: Dictionary, rule: Dictionary) -> float:
	if rule.is_empty():
		return 1.0                                 # “generic” fit

	var score := 0.0
	for k in rule:
		var val = o[k]
		var r = rule[k]
		if val < r[0] or val > r[1]:
			return 0.0                              # outside band → no weight
		# distance from center of band (closer = higher):
		var center = (r[0] + r[1]) * 0.5
		score += 1.0 / (1.0 + abs(val - center))
	return score


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
