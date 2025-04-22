extends PanelContainer
class_name ProfilePanel

signal login_requested(slot_id: int)

#@onready var profile_panel: Panel = %ProfilePanel
@onready var profile_pic: TextureRect = %ProfilePic
@onready var name_label: Label = %NameLabel
@onready var username_label: Label = %UsernameLabel
@onready var password_text_edit: TextEdit = %PasswordTextEdit
@onready var log_in_button: Button = %LogInButton

var pending_data: Dictionary
var pending_slot_id: int = -1
var slot_id: int = -1



func _ready() -> void:
	password_text_edit.hide()
	log_in_button.hide()
	if pending_data:
		_apply_profile_data()

func set_profile_data(data: Dictionary, id: int) -> void:
	pending_data = data
	pending_slot_id = id
	if is_inside_tree():
		_apply_profile_data()

func _apply_profile_data() -> void:
	name_label.text = pending_data.get("name", "Unnamed")
	username_label.text = "@%s" % pending_data.get("username", "user")
	var path = pending_data.get("profile_pic", "res://assets/profiles/default.png")
	if ResourceLoader.exists(path):
		profile_pic.texture = load(path)
	slot_id = pending_slot_id


func _on_mouse_entered() -> void:
	password_text_edit.show()
	log_in_button.show()
	size = Vector2(180,270)


func _on_log_in_button_pressed() -> void:
	emit_signal("login_requested", slot_id)
