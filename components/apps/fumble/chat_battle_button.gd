extends Button
class_name ChatBattleButton

signal battle_pressed(battle_id, npc, npc_idx)

var npc
var battle_id
var npc_idx

func set_battle(npc_obj, battle_id_str, idx):
	npc = npc_obj
	battle_id = battle_id_str
	npc_idx = idx

	var name = npc.full_name
	var score = "%.1f/10" % (float(npc.attractiveness) / 10.0)

	var type_str = "Unknown"
	if npc.chat_battle_type != null and str(npc.chat_battle_type) != "":
		type_str = str(npc.chat_battle_type)
	
	self.text = "%s (%s)  [%s]" % [name, score, type_str]

func _ready():
	self.pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("battle_pressed", battle_id, npc, npc_idx)
