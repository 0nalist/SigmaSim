extends PanelContainer
class_name UserLoginCardUI

signal login_requested(slot_id: int)
signal card_selected(card: UserLoginCardUI)

@onready var profile_pic: PortraitView = %ProfilePic
@onready var name_label: Label = %NameLabel
@onready var username_label: Label = %UsernameLabel
@onready var net_worth_label: Label = %NetWorthLabel
@onready var password_line_edit: LineEdit = %PasswordLineEdit
@onready var show_password_button: Button = %ShowPasswordButton
@onready var password_hbox: HBoxContainer = %PasswordHBox
@onready var rainbow_password_label: RichTextLabel = %RainbowPasswordLabel
@onready var log_in_button: Button = %LogInButton

var pending_data: Dictionary = {}
var pending_slot_id: int = -1
var slot_id: int = -1

const BASE_CARD_WIDTH: float = 180.0
const BASE_COLLAPSED_HEIGHT: float = 190.0
const BASE_EXPANDED_HEIGHT: float = 260.0
const BASE_PROFILE_SIZE: float = 128.0
const BASE_PASSWORD_HEIGHT: float = 35.0
const BASE_LABEL_HEIGHT: float = 20.0

var expanded_height: float = BASE_EXPANDED_HEIGHT
var collapsed_height: float = BASE_COLLAPSED_HEIGHT
var tween: Tween = null
var expanded: bool = false

func _ready() -> void:
	var base_res := Vector2(1280.0, 720.0)
	var scale := get_window().size.y / base_res.y
	collapsed_height = BASE_COLLAPSED_HEIGHT * scale
	expanded_height = BASE_EXPANDED_HEIGHT * scale
	custom_minimum_size = Vector2(BASE_CARD_WIDTH * scale, collapsed_height)
	size = custom_minimum_size
	password_line_edit.custom_minimum_size = Vector2(0.0, BASE_PASSWORD_HEIGHT * scale)
	rainbow_password_label.custom_minimum_size = Vector2(0.0, BASE_LABEL_HEIGHT * scale)
	profile_pic.custom_minimum_size = Vector2(BASE_PROFILE_SIZE * scale, BASE_PROFILE_SIZE * scale)
	log_in_button.hide()
	net_worth_label.hide()
	password_hbox.hide()
	show_password_button.toggled.connect(_on_show_password_button_toggled)
	if not pending_data.is_empty():
		_apply_profile_data()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("card_selected", self)

func set_profile_data(data: Dictionary, id: int) -> void:
	pending_data = data
	pending_slot_id = id
	if is_inside_tree():
		_apply_profile_data()

func _apply_profile_data() -> void:
	name_label.text = pending_data.get("name", "Unnamed")
	username_label.text = "@%s" % pending_data.get("username", "user")

	var net: float = float(pending_data.get("net_worth", 0.0))
	#net_worth_label.text = "$" + NumberFormatter.format_commas(net, 2, true)
	net_worth_label.text = "$" + NumberFormatter.smart_format(net)

	var using_random_seed: bool = bool(pending_data.get("using_random_seed", false))
	if using_random_seed:
		password_line_edit.text = ""
		password_line_edit.hide()
		show_password_button.button_pressed = false
		#show_password_button.text = "show"
		show_password_button.hide()
		rainbow_password_label.bbcode_text = _generate_rainbow_password()
		rainbow_password_label.show()
	else:
		password_line_edit.show()
		show_password_button.show()
		rainbow_password_label.hide()
		password_line_edit.text = String(pending_data.get("password", ""))
		password_line_edit.secret = true
		show_password_button.button_pressed = false
		#show_password_button.text = "show"

	var cfg_dict: Dictionary = pending_data.get("portrait_config", {})
	if cfg_dict is Dictionary:
		var cfg: PortraitConfig = PortraitConfig.from_dict(cfg_dict)
		profile_pic.apply_config(cfg)
		profile_pic.size_flags_horizontal = Control.SIZE_FILL
		profile_pic.size_flags_vertical = Control.SIZE_FILL

	slot_id = pending_slot_id

func expand() -> void:
		if expanded:
				return
		expanded = true
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		net_worth_label.text = "$" + NumberFormatter.format_commas(float(pending_data.get("net_worth", 0.0)), 2, true)
		net_worth_label.show()
		password_hbox.show()
		log_in_button.show()
		if tween != null:
				tween.kill()
		tween = create_tween()
		tween.tween_property(self, "custom_minimum_size:y", expanded_height, 0.25)
		tween.parallel().tween_property(self, "size:y", expanded_height, 0.25)
		tween.parallel().tween_property(net_worth_label, "modulate:a", 1.0, 0.25).from(0.0)
		tween.parallel().tween_property(password_hbox, "modulate:a", 1.0, 0.25).from(0.0)

func collapse() -> void:
		if not expanded:
				return
		expanded = false
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if tween != null:
				tween.kill()
		tween = create_tween()
		tween.tween_property(self, "custom_minimum_size:y", collapsed_height, 0.25)
		tween.parallel().tween_property(self, "size:y", collapsed_height, 0.25)
		tween.parallel().tween_property(net_worth_label, "modulate:a", 0.0, 0.25)
		tween.parallel().tween_property(password_hbox, "modulate:a", 0.0, 0.25)
		tween.finished.connect(func() -> void:
				net_worth_label.hide()
				password_hbox.hide()
				log_in_button.hide()
		)

func _on_log_in_button_pressed() -> void:
	emit_signal("login_requested", slot_id)

func _on_show_password_button_toggled(toggled_on: bool) -> void:
	password_line_edit.secret = not toggled_on
	#if toggled_on:
	#	show_password_button.text = "hide"
	#else:
	#	show_password_button.text = "show"

func _generate_rainbow_password() -> String:
	var text: String = "password"
	var colors: Array[Color] = [
		Color(1, 0, 0),
		Color(1, 0.5, 0),
		Color(1, 1, 0),
		Color(0, 1, 0),
		Color(0, 0, 1),
		Color(0.29, 0, 0.51),
		Color(0.56, 0, 1),
	]
	var bbcode: String = ""
	for i in text.length():
			var ch: String = text.substr(i, 1)
			var color: Color = colors[i % colors.size()]
			bbcode += "[color=%s]%s[/color]" % [color.to_html(), ch]
	return bbcode
