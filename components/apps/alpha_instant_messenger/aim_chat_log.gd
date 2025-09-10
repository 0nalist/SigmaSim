extends PanelContainer
class_name AimChatLog

const AIM_CHAT_MESSAGE_SCENE: PackedScene = preload("res://components/apps/alpha_instant_messenger/aim_chat_message.tscn")

@onready var messages_container: VBoxContainer = $Messages

func add_message(text: String, from_player: bool) -> void:
    var message: AimChatMessage = AIM_CHAT_MESSAGE_SCENE.instantiate()
    messages_container.add_child(message)
    message.set_message(text, from_player)
