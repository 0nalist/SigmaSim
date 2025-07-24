extends Node
#Autoload: RizzBattleData

var player_lines = []
var npc_responses = {}
var npc_generic_responses = {}
var npc_block_warnings = {}

# Chat Battle Type Modifiers: type_name -> { strong: [], weak: [], immune: [] }
var type_mods = {}

func _ready():
	player_lines = load_json("res://data/npc_data/battle/player_lines.json")
	npc_responses = load_json("res://data/npc_data/battle/npc_responses.json")
	npc_generic_responses = load_json("res://data/npc_data/battle/npc_generic_responses.json")
	npc_block_warnings = load_json("res://data/npc_data/battle/npc_block_warnings.json")
	load_type_mods("res://data/npc_data/battle/npc_battle_types.json")

func load_json(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	return JSON.parse_string(text)

func load_type_mods(path: String):
	type_mods.clear()
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Couldn't open chat_battle_types.json")
		return
	var arr = JSON.parse_string(file.get_as_text())
	for entry in arr:
		var t = entry.get("Type", "").to_lower()
		if t == "":
			continue
		type_mods[t] = {
			"strong": _split(entry.get("Strong vs.", "")),
			"weak": _split(entry.get("Weak vs.", "")),
			"immune": _split(entry.get("Immune to", ""))
		}
	
	print("Loaded type_mods keys:", type_mods.keys())
	for k in type_mods.keys():
		print("Key:", k, "Value:", type_mods[k])


func _split(val: String) -> Array:
	val = val.strip_edges()
	if val == "":
		return []
	var out = []
	for s in val.split(",", false):
		out.append(s.strip_edges().to_lower())
	return out
