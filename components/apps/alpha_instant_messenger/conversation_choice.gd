extends CustomButton
class_name ConversationChoice

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
	if ConversationManager != null:
		ConversationManager.start(conv_id, npc_idx, "player")

func _update_label() -> void:
	var meta: Dictionary = {}
	if ConversationManager != null:
		meta = ConversationManager.conversation_registry.get(conv_id, {})
	text = meta.get("name", conv_id)
