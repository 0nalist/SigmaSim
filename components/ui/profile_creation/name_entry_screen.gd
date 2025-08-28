extends Control

signal step_valid(valid: bool)

@onready var name_line_edit: LineEdit = %NameLineEdit
@onready var username_line_edit: LineEdit = %UsernameLineEdit
@onready var password_line_edit: LineEdit = %PasswordLineEdit

func _ready():
	# Connect validation on any text change
	name_line_edit.text_changed.connect(_check_validity)
	username_line_edit.text_changed.connect(_check_validity)
	password_line_edit.text_changed.connect(_check_validity)

	# Initial check in case of autofill or default values
	_check_validity("")

func _check_validity(_text) -> void:
	var is_valid : bool = (
		   name_line_edit.text.strip_edges() != "" and
		   username_line_edit.text.strip_edges() != ""
	)
	
	emit_signal("step_valid", is_valid)

# Called by ProfileCreationUI when "Next" is pressed
func save_data() -> void:
	var user_data = PlayerManager.user_data

	user_data["name"] = name_line_edit.text.strip_edges()
	user_data["username"] = username_line_edit.text.strip_edges()
	user_data["password"] = password_line_edit.text
