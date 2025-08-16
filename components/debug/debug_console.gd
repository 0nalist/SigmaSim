extends PanelContainer
class_name DebugConsole

@onready var command_line: LineEdit = %CommandLine
@onready var enter_button: Button = %EnterButton
@onready var feedback_label: Label = %FeedbackLabel

func _ready() -> void:
    # Fullscreen anchors (defensive in case scene settings change)
    anchors_preset = Control.PRESET_FULL_RECT
    anchor_right = 1.0
    anchor_bottom = 1.0
    visible = false

    # Simple appearance tweak so it reads as an overlay
    self_modulate = Color(1, 1, 1, 0.95)

    enter_button.pressed.connect(_on_enter_pressed)
    command_line.text_submitted.connect(_on_text_submitted)

func open() -> void:
    visible = true
    show()
    await get_tree().process_frame
    if is_instance_valid(command_line):
        command_line.grab_focus()
        command_line.caret_column = command_line.text.length()

func close() -> void:
    hide()
    visible = false

func toggle() -> void:
    if visible:
        close()
    else:
        open()

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return

    # Submit on Enter anywhere
    if event.is_action_pressed("ui_accept"):
        _submit_command()
        get_viewport().set_input_as_handled()

    # Close on ESC
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
        var amount := _parse_number(amount_str)
        if amount == null:
            _set_feedback("Invalid amount: " + amount_str, false)
            return false
        if not _has_portfolio_manager():
            _set_feedback("PortfolioManager not found.", false)
            return false
        # Prefer a dedicated API; fall back to set/get if needed.
        if "add_cash" in PortfolioManager:
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
    # Accept int or float
    if s.find(".") != -1:
        var f := s.to_float()
        if str(f) == "nan":
            return null
        return f
    else:
        var i := s.to_int()
        # to_int always returns 0 on failure; detect non-numeric explicitly
        if s != "0" and i == 0 and not s.strip_edges().begins_with("0"):
            # check if it truly is non-numeric
            var tmp := s.to_float()
            if str(tmp) == "nan":
                return null
            return tmp
        return i

func _has_portfolio_manager() -> bool:
    return Engine.has_singleton("PortfolioManager") or typeof(PortfolioManager) != TYPE_NIL
