extends Control

@onready var name_line_edit: LineEdit = %NameLineEdit
@onready var username_line_edit: LineEdit = %UsernameLineEdit
@onready var password_line_edit: LineEdit = %PasswordLineEdit

# Called by ProfileCreationUI when "Next" is pressed
func save_data() -> void:
	var user_data = PlayerManager.user_data

	user_data["name"] = name_line_edit.text.strip_edges()
	user_data["username"] = username_line_edit.text.strip_edges()
	user_data["password"] = password_line_edit.text
