extends Button
class_name MatchButton

signal match_pressed(npc, npc_idx)

@onready var portrait: PortraitView = %ProfilePic
@onready var name_label: Label = %NameLabel
@onready var attractiveness_label: Label = %AttractivenessLabel
@onready var type_label: Label = %TypeLabel



var npc: NPC
var npc_idx: int

# Sets up the button for a specific NPC (and its index)
func set_profile(npc_ref, idx):
	npc = npc_ref
	npc_idx = idx
	# Set portrait
	if npc.portrait_config != null:
			portrait.apply_config(npc.portrait_config)
	# Set name
	name_label.text = npc.full_name
	type_label.text = npc.chat_battle_type
	attractiveness_label.text = "🔥 %.1f/10" % (float(npc.attractiveness) / 10.0)


func _ready():
	self.pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("match_pressed", npc, npc_idx)
