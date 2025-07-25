class_name BattleLogic
extends Resource

var npc: NPC
var stats = {}


func setup(npc_ref, stats_dict = {}):
	npc = npc_ref
	stats = stats_dict.duplicate()

func resolve_move(move_type: String) -> Dictionary:
	var chance = get_success_chance(move_type)
	var success = randf() < chance
	var mod = get_move_type_modifier(npc.chat_battle_type, move_type)
	var reaction = ""
	if mod == 2.0:
		reaction = "heart"
	elif mod == 0.5:
		reaction = "zzz"
	elif mod == 0.0:
		reaction = "thumbs_down"
	# Default: no reaction or normal (could add more)
	var effects = apply_move_effects(move_type, success)
	return {
		"success": success,
		"chance": chance,
		"effects": effects,
		"reaction": reaction
	}


func get_success_chance(move_type: String) -> float:
	var npc_type = npc.chat_battle_type if npc.chat_battle_type != null else ""
	var mod = BattleLogic.get_move_type_modifier(npc_type, move_type)
	if mod == 0.0:
		return 0.0
	
	# Special handling for "catch"
	if move_type == "catch":
		var chemistry = stats.get("chemistry", 0)
		var apprehension = stats.get("apprehension", 0)
		
		# If chemistry > 99 and apprehension < 1, guaranteed success
		if chemistry > 99 and apprehension < 1:
			return 1.0
		# If apprehension > chemistry, guaranteed failure
		elif apprehension > chemistry:
			return 0.0
		else:
			# The more chemistry exceeds apprehension, the higher the chance of success
			# When chemistry == apprehension, chance = 0
			# When chemistry == 100 and apprehension == 0, chance = 1
			var chance = float(chemistry - apprehension) / max(1.0, (100.0 - min(apprehension, chemistry)))
			# Clamp between 0 and 1 for safety
			return clamp(chance, 0.0, 1.0)
	
	if move_type == "simp":
		return 0.65 + (get_attractiveness_delta() / 10.0)
	
	# Default success rate
	return 0.5 + (get_attractiveness_delta() / 10.0)



# === Baseline effect values for each move ===
var SUCCESS_FX = {
	"rizz": {
		"chemistry": 10,
		"apprehension": -5,
		"confidence": 3
	},
	"simp": {
		"chemistry": 12,
		"apprehension": -4,
		"confidence": -4,
		"self_esteem": 5
	},
	"flex": {
		"chemistry": 8,
		"apprehension": -8,
		"confidence": 12,
		"self_esteem": -3
	},
	"neg": {
		"chemistry": 4,
		"apprehension": -5,
		"confidence": 10,
		"self_esteem": -8  
	}
}

var FAIL_FX = {
	"rizz": {
		"confidence": -10,
		"chemistry": -3,
	},
	"simp": {
		"confidence": -10,
		"apprehension": 4,
		"chemistry": -2,
	},
	"flex": {
		"confidence": -10,
		"apprehension": 4,
		"chemistry": -2,
	},
	"neg": {
		"confidence": -6,
		"apprehension": 12,
		"chemistry": -10,
	}
}

# === Multipliers (could be replaced with logic by npc type etc) ===
var multipliers = {
	"rizz": 1.0,
	"simp": 1.0,
	"flex": 1.5,
	"neg": 1.5
}


func apply_move_effects(move_type: String, success: bool) -> Dictionary:
	var result = {}
	var dime_delta = get_attractiveness_delta()
	var npc_type = npc.chat_battle_type if npc.chat_battle_type != null else ""
	var mod = BattleLogic.get_move_type_modifier(npc_type, move_type)

	# Set emoji reaction based on mod
	if mod == 0.0:
		result["reaction"] = "thumbs_down" # immune
		# Fill result with zero for all relevant stats for that move
		var stats_set = []
		if move_type in SUCCESS_FX:
			stats_set = SUCCESS_FX[move_type].keys()
		elif move_type in FAIL_FX:
			stats_set = FAIL_FX[move_type].keys()
		for stat in stats_set:
			result[stat] = 0
		return result

	# === Handle move effects ===
	if success:
		var base = SUCCESS_FX.get(move_type, {})
		var multi = multipliers.get(move_type, 1.0) * mod
		if base.has("chemistry"):
			var c_val = base["chemistry"] + dime_delta * multi
			stats["chemistry"] = clamp(stats.get("chemistry", 0) + c_val, 0, 100)
			result["chemistry"] = c_val
		if base.has("apprehension"):
			var a_val = base["apprehension"]
			stats["apprehension"] = clamp(stats.get("apprehension", 0) + a_val, 0, 100)
			result["apprehension"] = a_val
		if base.has("confidence"):
			var conf_val = base["confidence"] - dime_delta
			PlayerManager.adjust_stat("confidence", conf_val)
			result["confidence"] = conf_val
		if base.has("self_esteem"):
			var se_val = base["self_esteem"] + dime_delta * multi
			stats["self_esteem"] = clamp(stats.get("self_esteem", 0) + se_val, 0, 100)
			result["self_esteem"] = se_val
	else:
		var fail = FAIL_FX.get(move_type, {})
		# Confidence always applied
		if fail.has("confidence"):
			var conf_val = fail["confidence"] - dime_delta
			PlayerManager.adjust_stat("confidence", conf_val)
			result["confidence"] = conf_val
		if fail.has("apprehension"):
			var a_val = fail["apprehension"]
			stats["apprehension"] = clamp(stats.get("apprehension", 0) + a_val, 0, 100)
			result["apprehension"] = a_val
		if fail.has("chemistry"):
			var c_val = fail["chemistry"]
			stats["chemistry"] = clamp(stats.get("chemistry", 0) + c_val, 0, 100)
			result["chemistry"] = c_val
		if fail.has("self_esteem"):
			var se_val = fail["self_esteem"]
			stats["self_esteem"] = clamp(stats.get("self_esteem", 0) + se_val, 0, 100)
			result["self_esteem"] = se_val
	return result





func get_attractiveness_delta() -> float: # + if player is more attractive than npc
	var dime_delta: float = ((PlayerManager.get_stat("attractiveness") - npc.attractiveness)/10.0)
	#print("dime delta: " + str(dime_delta))
	return dime_delta


func get_stats() -> Dictionary:
	return stats.duplicate()



static func get_move_type_modifier(npc_type: String, move_type: String) -> float:
	npc_type = npc_type.strip_edges().to_lower()
	move_type = move_type.strip_edges().to_lower()
	var mods = RizzBattleData.type_mods.get(npc_type, null)
	#print("Looking up npc_type=", npc_type, " move_type=", move_type)
	#print("Type data:", mods)
	if mods == null:
		return 1.0
	if move_type in mods["immune"]:
		return 0.0
	if move_type in mods["strong"]:
		return 2.0
	if move_type in mods["weak"]:
		return 0.5
	return 1.0
