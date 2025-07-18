extends Node
#Autoload: RizzBattleData

var player_lines = []
var npc_responses = {}
var npc_generic_responses = {}
var npc_block_warnings = {}

func _ready():
	player_lines = load_json("res://data/npc_data/battle/player_lines.json")
	npc_responses = load_json("res://data/npc_data/battle/npc_responses.json")
	npc_generic_responses = load_json("res://data/npc_data/battle/npc_generic_responses.json")
	npc_block_warnings = load_json("res://data/npc_data/battle/npc_block_warnings.json")

func load_json(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	return JSON.parse_string(text)
