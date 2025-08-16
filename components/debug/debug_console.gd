extends CanvasLayer
class_name DebugConsole

@onready var panel: PanelContainer = $PanelContainer
@onready var command_line: LineEdit = %CommandLine
@onready var enter_button: Button = %EnterButton
@onready var feedback_label: Label = %FeedbackLabel
@onready var command_list_container: VBoxContainer = %CommandListContainer
@onready var command_log_container: VBoxContainer = %CommandLogContainer

@onready var command_list_parent_container: VBoxContainer = %CommandListParentContainer


var commands := {
        "add_cash": {
                "args": "<amount>",
                "description": "Adds the given amount of cash to your portfolio.",
        },
        "help": {
                "args": "",
                "description": "Displays a list of available debug commands.",
        },
        "set_stat": {
                        "args": "<stat_name> <value>",
                        "description": "Sets the specified player stat to the given value.",
        },
        "list_stats": {
                        "args": "",
                        "description": "Lists all current stats and values.",
        },
}

func _ready() -> void:
	# Fullscreen anchor
	panel.anchors_preset = Control.PRESET_FULL_RECT
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0

	# Background style
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.7)
	panel.add_theme_stylebox_override("panel", sb)

	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false

	enter_button.pressed.connect(_on_enter_pressed)
	command_line.text_submitted.connect(_on_text_submitted)
	enter_button.focus_mode = Control.FOCUS_NONE

	_populate_command_list()
	#command_list_container.visible = false
	command_list_parent_container.visible = false
	

func open() -> void:
	print("opening debug")
	visible = true
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

func _refocus_line() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(command_line):
		get_viewport().set_input_as_handled()
		command_line.release_focus()
		await get_tree().process_frame
		command_line.grab_focus()
		command_line.caret_column = command_line.text.length()

func _on_enter_pressed() -> void:
	_submit_command()

func _on_text_submitted(_text: String) -> void:
	_submit_command()

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("ui_accept"):
		_submit_command()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _submit_command() -> void:
	var cmd := command_line.text.strip_edges()
	if cmd == "":
		_set_feedback("No command entered.", false)
		call_deferred("_refocus_line")
		return

	_log_command(cmd)  # ← Add this

	var ok := process_command(cmd)
	if ok:
		_set_feedback("OK: " + cmd, true)
	else:
		if feedback_label.text == "" or feedback_label.text.begins_with("OK"):
			_set_feedback("Unknown or invalid command.", false)

	command_line.text = ""
	call_deferred("_refocus_line")


func _log_command(cmd: String) -> void:
	var label := Label.new()
	label.text = "> " + cmd
	command_log_container.add_child(label)


func _set_feedback(msg: String, success: bool) -> void:
	feedback_label.text = msg

	if success:
		feedback_label.modulate = Color(0.6, 1.0, 0.6, 1.0)
	else:
		feedback_label.modulate = Color(1.0, 0.6, 0.6, 1.0)


func _populate_command_list() -> void:
	for child in command_list_container.get_children():
		child.queue_free()

	for cmd in commands.keys():
		var data = commands[cmd]
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD

		var args := ""
		if data.has("args"):
			args = data["args"]

		var desc := ""
		if data.has("description"):
			desc = data["description"]

		label.text = cmd + " " + args + ":\n  " + desc
		command_list_container.add_child(label)


func process_command(command: String) -> bool:
        var parts := command.split(" ", false)
        if parts.size() == 0:
                return false

        var cmd := parts[0].to_lower()

        match cmd:
                "help":
                        _set_feedback("Available commands listed below.", true)
                        _populate_command_list()
                        command_list_parent_container.visible = true
                        return true

                "add_cash":
                        if parts.size() < 2:
                                _set_feedback("Usage: add_cash <amount>", false)
                                return false

                        var amount_str := parts[1]
                        var amount = _parse_number(amount_str)
                        if amount == null:
                                _set_feedback("❌ 'add_cash' requires a numeric value. '%s' is not valid.".format([amount_str]), false)
                                return false

                        var current_cash := StatManager.get_stat("cash")
                        StatManager.set_base_stat("cash", current_cash + amount)
                        return true

                "set_stat":
                        if parts.size() < 3:
                                _set_feedback("Usage: set_stat <stat_name> <value>", false)
                                return false

                        var stat_name := parts[1]
                        var value_str := parts[2]
                        var value = _parse_number(value_str)
                        if value == null:
                                _set_feedback("❌ 'set_stat' requires a numeric value. '%s' is not valid.".format([value_str]),false)
                                return false

                        StatManager.set_base_stat(stat_name, value)
                        return true

                "list_stats":
                        var all_stats := StatManager.get_all_stats()
                        for stat_key in all_stats.keys().sort():
                                var label := Label.new()
                                label.text = "%s: %s" % [stat_key, str(all_stats[stat_key])]
                                command_log_container.add_child(label)
                        return true

                _:
                        return false

func _parse_number(s: String) -> Variant:
	s = s.strip_edges()
	var regex := RegEx.new()
	regex.compile("^[-+]?[0-9]+(\\.[0-9]+)?$")
	if not regex.search(s):
		return null
	return s.to_float()
