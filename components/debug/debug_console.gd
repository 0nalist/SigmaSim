extends CanvasLayer
class_name DebugConsole

@onready var panel: PanelContainer = $PanelContainer
@onready var command_line: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CommandLine
@onready var enter_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EnterButton
@onready var feedback_label: Label = $PanelContainer/MarginContainer/VBoxContainer/FeedbackLabel

func _ready() -> void:
	# Fullscreen anchor on the actual control (not CanvasLayer)
	panel.anchors_preset = Control.PRESET_FULL_RECT
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0

	# Background style for visibility
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.7)
	panel.add_theme_stylebox_override("panel", sb)

	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false

	enter_button.pressed.connect(_on_enter_pressed)
	command_line.text_submitted.connect(_on_text_submitted)

func open() -> void:
	print("opening debug")
	panel.visible = true
	call_deferred("_focus_line")

func close() -> void:
	panel.visible = false

func toggle() -> void:
	if panel.visible:
		close()
	else:
		open()

func _focus_line() -> void:
	if is_instance_valid(command_line):
		command_line.grab_focus()
		command_line.caret_column = command_line.text.length()

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("ui_accept"):
		_submit_command()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_enter_pressed() -> void:
	_submit_command()

func _on_text_submitted(_text: String) -> void:
	_submit_command()

func _submit_command() -> void:
	var cmd := command_line.text.strip_edges()
	if cmd == "":
		_set_feedback("No command entered.", false)
		return

	var ok := process_command(cmd)
	if ok:
		_set_feedback("OK: " + cmd, true)
	else:
		if feedback_label.text == "" or feedback_label.text.begins_with("OK"):
			_set_feedback("Unknown or invalid command.", false)

	command_line.text = ""
	command_line.grab_focus()

func _set_feedback(msg: String, success: bool) -> void:
	if success:
		feedback_label.modulate = Color(0.6, 1.0, 0.6, 1.0)
	else:
		feedback_label.modulate = Color(1.0, 0.6, 0.6, 1.0)
	feedback_label.text = msg

func process_command(command: String) -> bool:
	var parts := command.split(" ", false)
	if parts.size() == 0:
		return false

	var cmd := parts[0].to_lower()

	if cmd == "add_cash":
		if parts.size() < 2:
			_set_feedback("Usage: add_cash <amount>", false)
			return false
		var amount_str := parts[1]
		var amount = _parse_number(amount_str)
		if amount == null:
			_set_feedback("Invalid amount: " + amount_str, false)
			return false
		if not _has_portfolio_manager():
			_set_feedback("PortfolioManager not found.", false)
			return false
		if PortfolioManager.has_method("add_cash"):
			PortfolioManager.add_cash(amount)
		else:
			if not PortfolioManager.has_method("get_cash") or not PortfolioManager.has_method("set_cash"):
				_set_feedback("PortfolioManager lacks add_cash and get/set APIs.", false)
				return false
			var current_cash = PortfolioManager.get_cash()
			PortfolioManager.set_cash(current_cash + amount)
		return true

	return false

func _parse_number(s: String):
	if s.find(".") != -1:
		var f := s.to_float()
		if str(f) == "nan":
			return null
		return f
	else:
		var i := s.to_int()
		if s != "0" and i == 0 and not s.strip_edges().begins_with("0"):
			var tmp := s.to_float()
			if str(tmp) == "nan":
				return null
			return tmp
		return i

func _has_portfolio_manager() -> bool:
	return (typeof(PortfolioManager) != TYPE_NIL)
