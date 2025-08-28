extends PanelContainer
class_name ProfilePanel

signal login_requested(slot_id: int)

#@onready var profile_panel: Panel = %ProfilePanel
@onready var profile_pic: PortraitView = %ProfilePic
@onready var name_label: Label = %NameLabel
@onready var username_label: Label = %UsernameLabel
@onready var password_line_edit: LineEdit = %PasswordLineEdit
@onready var show_password_button: Button = %ShowPasswordButton
@onready var password_hbox: HBoxContainer = %PasswordHBox
@onready var rainbow_password_label: RichTextLabel = %RainbowPasswordLabel
@onready var log_in_button: Button = %LogInButton

var pending_data: Dictionary
var pending_slot_id: int = -1
var slot_id: int = -1


func _ready() -> void:
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	log_in_button.hide()
	show_password_button.toggled.connect(_on_show_password_button_toggled)
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

	var using_random_seed = pending_data.get("using_random_seed", false)
	if using_random_seed:
		password_line_edit.text = ""
		password_line_edit.hide()
		show_password_button.button_pressed = false
		show_password_button.text = "show"
		show_password_button.hide()
		rainbow_password_label.bbcode_text = _generate_rainbow_password()
		rainbow_password_label.show()
		password_hbox.show()
	else:
		password_line_edit.show()
		show_password_button.show()
		rainbow_password_label.hide()
		password_line_edit.text = pending_data.get("password", "")
		password_line_edit.secret = true
		show_password_button.button_pressed = false
		show_password_button.text = "show"
		password_hbox.show()

	var cfg_dict = pending_data.get("portrait_config", {})
	if cfg_dict is Dictionary:
		var cfg = PortraitConfig.from_dict(cfg_dict)
		profile_pic.apply_config(cfg)

		# FORCE 128x128 size
		profile_pic.custom_minimum_size = Vector2(128, 128)
		profile_pic.set_size(Vector2(128, 128))
		profile_pic.size_flags_horizontal = Control.SIZE_FILL
		profile_pic.size_flags_vertical = Control.SIZE_FILL

	slot_id = pending_slot_id


func _on_mouse_entered() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_in_button.show()
	#size = Vector2(180,270)


func _on_log_in_button_pressed() -> void:
	emit_signal("login_requested", slot_id)


func _on_mouse_exited() -> void:
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	log_in_button.hide()


func _on_show_password_button_toggled(toggled_on: bool) -> void:
	password_line_edit.secret = not toggled_on
	show_password_button.text = toggled_on ? "hide" : "show"


func _generate_rainbow_password() -> String:
	var text := "password"
	var colors := [
		Color(1, 0, 0), # red
		Color(1, 0.5, 0), # orange
		Color(1, 1, 0), # yellow
		Color(0, 1, 0), # green
		Color(0, 0, 1), # blue
		Color(0.29, 0, 0.51), # indigo
		Color(0.56, 0, 1), # violet
	]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bbcode := ""
	for c in text:
		var color := colors[rng.randi_range(0, colors.size() - 1)]
		bbcode += "[color=%s]%s[/color]" % [color.to_html(), c]
	return bbcode
