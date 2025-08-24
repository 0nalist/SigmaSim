extends Button
class_name ChatBattleActionButton

var action: ChatBattleAction
signal action_pressed(action: ChatBattleAction)

func _ready() -> void:
    pressed.connect(_on_pressed)

func load_action(new_action: ChatBattleAction, display_text: String) -> void:
    action = new_action
    text = display_text

func _on_pressed() -> void:
    if action:
        action_pressed.emit(action)
