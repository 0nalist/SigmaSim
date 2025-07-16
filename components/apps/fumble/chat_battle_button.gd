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
	self.text = "%s (%0.1f/10)" % [npc.full_name, float(npc.attractiveness)/10.0]

func _ready():
	self.pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("battle_pressed", battle_id, npc, npc_idx)
