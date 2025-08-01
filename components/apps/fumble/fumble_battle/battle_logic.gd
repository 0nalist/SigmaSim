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
		reaction = "haha"
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
		if chemistry > 99 and apprehension < 1:
			return 1.0
		elif apprehension > chemistry:
			return 0.0
		else:
			var chance = float(chemistry - apprehension) / max(1.0, (100.0 - min(apprehension, chemistry)))
			return clamp(chance, 0.0, 1.0)

	var base_chance = 0.5 + (get_attractiveness_delta() / 10.0)
	if move_type == "simp":
		base_chance = 0.65 + (get_attractiveness_delta() / 10.0)

	var type_chance_adj = RizzBattleData.get_type_mod_chance_adjust(npc_type, move_type)

	return clamp(base_chance + type_chance_adj, 0.0, 1.0)




# === Baseline effect values for each move ===
var SUCCESS_FX = {
	"rizz": {
		"chemistry": 10,
		"apprehension": -5,
		"confidence": 5
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
		"self_esteem": -18  
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
	var type_mod = BattleLogic.get_move_type_modifier(npc_type, move_type)
	var multi = multipliers.get(move_type, 1.0)

	# Handle immune (immediate block)
	if type_mod == 0.0:
		result["reaction"] = "thumbs_down"
		success = false

	# Prepare raw effect values (no type mod yet)
	var raw_effects = {}

	if success:
		var base = SUCCESS_FX.get(move_type, {})
		if base.has("chemistry"):
			raw_effects["chemistry"] = base["chemistry"] + dime_delta
		if base.has("apprehension"):
			raw_effects["apprehension"] = base["apprehension"]
			if base.has("confidence"):
				var conf_base = base["confidence"]
				var conf_delta = conf_base - dime_delta
				# Allow negative delta only when the move is designed to be negative
				if conf_base >= 0 and conf_delta < 0:
					conf_delta = 0
				raw_effects["confidence"] = conf_delta

		if base.has("self_esteem"):
			raw_effects["self_esteem"] = base["self_esteem"] + dime_delta

		# **Apply multipliers, then type mod (ONLY ON SUCCESS)**
		for stat in raw_effects.keys():
			var val = raw_effects[stat]
			var final_val = val * multi * type_mod
			if stat == "confidence":
				PlayerManager.adjust_stat("confidence", final_val)
				result[stat] = final_val
			elif stat in stats:
				stats[stat] = clamp(stats.get(stat, 0) + final_val, 0, 100)
				result[stat] = final_val

	else:
		var fail = FAIL_FX.get(move_type, {})
		if fail.has("chemistry"):
			raw_effects["chemistry"] = fail["chemistry"]
		if fail.has("apprehension"):
			raw_effects["apprehension"] = fail["apprehension"]
		if fail.has("confidence"):
			raw_effects["confidence"] = fail["confidence"] - dime_delta
		if fail.has("self_esteem"):
			raw_effects["self_esteem"] = fail["self_esteem"]

		# **On failure, only multipliers are applied**
		for stat in raw_effects.keys():
			var val = raw_effects[stat]
			var final_val = val * multi
			if stat == "confidence":
				PlayerManager.adjust_stat("confidence", final_val)
				result[stat] = final_val
			elif stat in stats:
				stats[stat] = clamp(stats.get(stat, 0) + final_val, 0, 100)
				result[stat] = final_val

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
