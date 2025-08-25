extends Button
class_name ChatBattleActionButton

var action: ChatBattleAction
signal action_pressed(action: ChatBattleAction)

@onready var auto_checkbox: CheckBox = get_node_or_null("MarginContainer/CheckBox")

func _ready() -> void:
	pressed.connect(_on_pressed)

	if auto_checkbox == null:
		auto_checkbox = CheckBox.new()
		auto_checkbox.name = "CheckBox"
		auto_checkbox.text = ""
		auto_checkbox.focus_mode = Control.FOCUS_NONE
		auto_checkbox.mouse_filter = Control.MOUSE_FILTER_STOP
		auto_checkbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
		auto_checkbox.position = Vector2(4, 4)
		add_child(auto_checkbox)

	auto_checkbox.visible = UpgradeManager.get_level("fumble_predictive_text") > 0
	UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)

func _on_upgrade_purchased(id: String, _level: int) -> void:
	if id == "fumble_predictive_text":
		auto_checkbox.visible = true

func load_action(new_action: ChatBattleAction, display_text: String) -> void:
	action = new_action
	text = display_text

func _on_pressed() -> void:
	if action:
		action_pressed.emit(action)

func is_auto_selected() -> bool:
	return auto_checkbox.button_pressed if auto_checkbox else false

func reset_auto_checkbox() -> void:
	if auto_checkbox:
		auto_checkbox.button_pressed = false
