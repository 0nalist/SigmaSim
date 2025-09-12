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
	if TimeManager != null:
		TimeManager.minute_passed.connect(_on_minute_passed)

func set_npc_idx(idx: int) -> void:
	npc_idx = idx
	_update_label()

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
	var base_text: String = conversation_metadata.get("name", conv_id)
	var remaining: int = 0
	if ConversationManager != null:
		remaining = ConversationManager.get_cooldown_remaining(conv_id, npc_idx)
	if remaining > 0:
		disabled = true
		var hours: int = remaining / 60
		var minutes: int = remaining % 60
		text = "%s (%02dh %02dm)" % [base_text, hours, minutes]
	else:
		disabled = false
		text = base_text

func _on_minute_passed(_total_minutes: int) -> void:
	_update_label()
