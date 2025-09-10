extends PanelContainer
class_name AimChatMessage

@onready var message_box: HBoxContainer = $MessageBox
@onready var message_label: Label = %MessageLabel

var is_npc_message: bool = false

func set_message(text: String, from_player: bool) -> void:
    is_npc_message = not from_player
    message_label.text = text
    message_box.alignment = BoxContainer.ALIGNMENT_END if from_player else BoxContainer.ALIGNMENT_BEGIN
