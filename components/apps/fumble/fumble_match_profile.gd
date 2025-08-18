extends Control
class_name FumbleMatchProfile

signal start_battle_requested(battle_id, npc, npc_idx)


@onready var fumble_profile: FumbleProfileUI = %FumbleProfile
@onready var chat_button: Button = %ChatButton

var npc: NPC
var npc_idx


func set_profile(profile_npc, profile_idx):
        npc = profile_npc
        npc_idx = profile_idx
        fumble_profile.load_npc(npc, npc_idx)
	
	var already_in_battle = FumbleManager.has_active_battle(npc_idx)
	chat_button.visible = not already_in_battle

func _ready():
	#chat_button.pressed.connect(_on_chat_button_pressed)
	pass

func _on_chat_button_pressed():
	if not FumbleManager.has_active_battle(npc_idx):
		var battle_id = FumbleManager.start_battle(npc_idx)
		start_battle_requested.emit(battle_id, npc, npc_idx)
		queue_free()  # Close the profile popup
	else:
		print("Already in a battle with this NPC.")


func _on_close_fumble_profile_button_pressed() -> void:
	#TODO animate
	queue_free()
