extends VBoxContainer
class_name AimChatLog

const AIM_CHAT_MESSAGE_SCENE: PackedScene = preload("res://components/apps/alpha_instant_messenger/aim_chat_message.tscn")

func add_message(text: String, from_player: bool) -> void:
    var message: AimChatMessage = AIM_CHAT_MESSAGE_SCENE.instantiate()
    add_child(message)
    message.set_message(text, from_player)
