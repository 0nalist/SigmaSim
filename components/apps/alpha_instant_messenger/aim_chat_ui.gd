extends Pane
class_name AimChatUI

const EX_FACTOR_VIEW_SCENE: PackedScene = preload("res://components/popups/ex_factor_view.tscn")

@onready var header_container: PanelContainer = %HeaderContainer
@onready var name_label: Label = %NameLabel
@onready var portrait_view: PortraitView = %Portrait
@onready var chat_log: AimChatLog = %AimChatLog
@onready var line_edit: LineEdit = %PlayerLineEdit
@onready var greet_button: Button = %GreetButton
@onready var gift_button: Button = %GiftButton
@onready var date_button: Button = %DateButton
@onready var relationship_button: Button = %RelationshipButton

var npc: NPC
var npc_idx: int = -1

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

