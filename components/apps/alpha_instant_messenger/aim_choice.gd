extends CustomButton
class_name AimChoice

signal choice_selected(choice_id: String, option_id: String, text: String)

@export var choice_id: String = ""
@export var option_id: String = ""
@export var conv_id: String = "":
	set(value):
		conv_id = value
		if is_inside_tree():
			_update_label()
	get:
		return conv_id

var npc_idx: int = -1

func _ready() -> void:
	super._ready()
	pressed.connect(_on_pressed)
	_update_label()

func set_npc_idx(idx: int) -> void:
	npc_idx = idx

func _on_pressed() -> void:
	if conv_id != "":
		if ConversationManager != null:
			ConversationManager.start(conv_id, npc_idx, "player")
	else:
		choice_selected.emit(choice_id, option_id, text)

func _update_label() -> void:
	if conv_id == "":
		return
	var conversation_metadata: Dictionary = {}
	if ConversationManager != null:
		conversation_metadata = ConversationManager.conversation_registry.get(conv_id, {})
	text = conversation_metadata.get("name", conv_id)
