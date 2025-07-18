extends Button
class_name MatchButton

signal match_pressed(npc, npc_idx)

@onready var profile_pic: TextureRect = %ProfilePic
@onready var name_label: Label = %NameLabel
@onready var attractiveness_label: Label = %AttractivenessLabel

var npc: NPC
var npc_idx: int

# Sets up the button for a specific NPC (and its index)
func set_profile(npc_ref, idx):
	npc = npc_ref
	npc_idx = idx
	# Set picture
	if npc.profile_pic and typeof(npc.profile_pic) == TYPE_OBJECT:
		profile_pic.texture = npc.profile_pic
	else:
		profile_pic.texture = preload("res://assets/prof_pics/silhouette.png") # fallback
	# Set name
	name_label.text = npc.full_name
	attractiveness_label.text = "❤️ %.1f/10" % (float(npc.attractiveness) / 10.0)


func _ready():
	self.pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("match_pressed", npc, npc_idx)
