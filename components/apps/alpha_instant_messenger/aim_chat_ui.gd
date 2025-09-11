extends Pane
class_name AimChatUI

const EX_FACTOR_VIEW_SCENE: PackedScene = preload("res://components/popups/ex_factor_view.tscn")
const AIM_CHOICE_SCENE: PackedScene = preload("res://components/apps/alpha_instant_messenger/aim_choice.tscn")

@onready var header_container: PanelContainer = %HeaderContainer
@onready var name_label: Label = %NameLabel
@onready var portrait_view: PortraitView = %Portrait
@onready var chat_log: AimChatLog = %AimChatLog
@onready var line_edit: LineEdit = %PlayerLineEdit
@onready var greet_button: Button = %GreetButton
@onready var gift_button: Button = %GiftButton
@onready var date_button: Button = %DateButton
@onready var relationship_button: Button = %RelationshipButton
@onready var choices_vbox: VBoxContainer = %ChoicesVBox

var npc: NPC
var npc_idx: int = -1
var current_node_id: String = ""

func setup_custom(data: Dictionary) -> void:
	npc = data.get("npc")
	npc_idx = data.get("npc_idx", -1)
	if is_node_ready():
		_finalize_setup()
	else:
		ready.connect(_finalize_setup, CONNECT_ONE_SHOT)

func _ready() -> void:
	header_container.gui_input.connect(_on_header_gui_input)
	greet_button.pressed.connect(_on_greet_pressed)
	gift_button.pressed.connect(_on_gift_pressed)
	date_button.pressed.connect(_on_date_pressed)
	relationship_button.pressed.connect(_on_relationship_pressed)
	line_edit.text_submitted.connect(_on_line_edit_submitted)
	if ConversationManager != null:
		ConversationManager.node_entered.connect(_on_node_entered)
		ConversationManager.choice_presented.connect(_on_choice_presented)
		ConversationManager.conversation_ended.connect(_on_conversation_ended)

func _finalize_setup() -> void:
	if npc == null:
		return
	name_label.text = "@%s" % npc.username
	portrait_view.portrait_creator_enabled = false
	portrait_view.custom_minimum_size = Vector2(32, 32)
	portrait_view.portrait_scale = 1.0
	if npc_idx != -1:
		portrait_view.subject_npc_idx = npc_idx
	if npc.portrait_config and portrait_view.has_method("apply_config"):
		portrait_view.apply_config(npc.portrait_config)
	_populate_aim_choices()

func _populate_aim_choices() -> void:
	if ConversationManager == null:
		return
	for child in choices_vbox.get_children():
		child.queue_free()
	var convo_ids: Array = ConversationManager.get_available_conversations(npc_idx, "CHATBOX_OPEN")
	for convo_id in convo_ids:
		var choice: AimChoice = AIM_CHOICE_SCENE.instantiate()
		choice.conv_id = convo_id
		choice.set_npc_idx(npc_idx)
		var meta: Dictionary = ConversationManager.conversation_registry.get(convo_id, {})
		choice.text = meta.get("name", convo_id)
		choices_vbox.add_child(choice)

func _on_node_entered(conv_id: String, node_id: String, speaker: String, text: String) -> void:
	current_node_id = node_id
	if speaker == "player":
		line_edit.text = text
	else:
		chat_log.add_message(text, false)
		if ConversationManager != null:
			ConversationManager.progress(node_id, npc_idx)

func _on_choice_presented(choice_id: String, options: Array) -> void:
	for child in choices_vbox.get_children():
		child.queue_free()
	for option_data in options:
		var option_id: String = option_data.get("id", "")
		var option_text: String = option_data.get("text", "")
		var choice_button: Button = Button.new()
		choice_button.text = option_text
		choices_vbox.add_child(choice_button)
		choice_button.pressed.connect(func():
			line_edit.text = option_text
			if ConversationManager != null:
				ConversationManager.choose(choice_id, option_id, npc_idx)
		)

func _on_conversation_ended(conv_id: String, npc_id: int) -> void:
	if npc_id != npc_idx:
		return
	current_node_id = ""
	line_edit.clear()
	_populate_aim_choices()

func _on_header_gui_input(event: InputEvent) -> void:
	print("header gui input")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_romantically_pursuing():
			var key := "ex_factor_%d" % npc_idx
			var existing := WindowManager.find_popup_by_key(key)
			if existing:
				WindowManager.focus_window(existing)
			else:
				WindowManager.launch_popup(EX_FACTOR_VIEW_SCENE, key, {"npc": npc, "npc_idx": npc_idx})

func _is_romantically_pursuing() -> bool:
	if npc_idx == -1:
		return false
	return NPCManager.has_romantic_relationship(npc_idx)

func _on_greet_pressed() -> void:
	pass

func _on_gift_pressed() -> void:
	pass

func _on_date_pressed() -> void:
	pass

func _on_relationship_pressed() -> void:
	pass

func _on_line_edit_submitted(new_text: String) -> void:
	var text = new_text.strip_edges()
	if text == "":
		return
	chat_log.add_message(text, true)
	line_edit.clear()
	if ConversationManager != null and current_node_id != "":
		ConversationManager.progress(current_node_id, npc_idx)
