extends PanelContainer
class_name UserLoginCardUI

signal login_requested(slot_id: int)
signal card_selected(card: UserLoginCardUI)

@onready var profile_pic: PortraitView = %ProfilePic
@onready var name_label: Label = %NameLabel
@onready var username_label: Label = %UsernameLabel
@onready var password_line_edit: LineEdit = %PasswordLineEdit
@onready var net_worth_label: Label = %NetWorthLabel
@onready var log_in_button: Button = %LogInButton

var pending_data: Dictionary
var slot_id: int = -1

const COLLAPSED_SIZE := Vector2(220, 160)
const EXPANDED_SIZE := Vector2(220, 260)

func _ready() -> void:
custom_minimum_size = COLLAPSED_SIZE
if pending_data:
_apply_profile_data()

func set_profile_data(data: Dictionary, id: int) -> void:
pending_data = data
slot_id = id
if is_inside_tree():
_apply_profile_data()

func _apply_profile_data() -> void:
name_label.text = pending_data.get("name", "Unnamed")
username_label.text = "@%s" % pending_data.get("username", "user")
password_line_edit.text = pending_data.get("password", "")
var cash = pending_data.get("cash", 0)
net_worth_label.text = "$%s" % NumberFormatter.format_commas(int(cash))

var cfg_dict = pending_data.get("portrait_config", {})
if cfg_dict is Dictionary:
var cfg = PortraitConfig.from_dict(cfg_dict)
profile_pic.apply_config(cfg)
profile_pic.custom_minimum_size = Vector2(128, 128)
profile_pic.set_size(Vector2(128, 128))

func _on_gui_input(event: InputEvent) -> void:
if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
emit_signal("card_selected", self)

func select() -> void:
net_worth_label.show()
password_line_edit.show()
log_in_button.show()
var tween = create_tween()
tween.tween_property(self, "custom_minimum_size", EXPANDED_SIZE, 0.25)
tween.set_trans(Tween.TRANS_SINE)
tween.set_ease(Tween.EASE_OUT)

func deselect() -> void:
net_worth_label.hide()
password_line_edit.hide()
log_in_button.hide()
var tween = create_tween()
tween.tween_property(self, "custom_minimum_size", COLLAPSED_SIZE, 0.25)
tween.set_trans(Tween.TRANS_SINE)
tween.set_ease(Tween.EASE_OUT)

func _on_log_in_button_pressed() -> void:
emit_signal("login_requested", slot_id)
