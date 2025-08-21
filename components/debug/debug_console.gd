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
	"gimme": {
		"args": "",
		"description": "Adds a buncha stuff",
	},
	"add_cash": {
		"args": "<amount>",
		"description": "Adds the given amount of cash to your portfolio.",
	},
	"help": {
		"args": "",
		"description": "Displays or hides the list of available debug commands.",
	},
	"set_stat": {
		"args": "<stat_name> <value>",
		"description": "Sets the specified player stat to the given value.",
	},
	"list_stats": {
		"args": "",
		"description": "Lists all current stats and values.",
	},
	"clear_log": {
		"args": "",
		"description": "Clears the command log window.",
	},
	"stress_test": {
		"args": "",
		"description": "Opens every app in the app registry at once.",
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
			_set_feedback("Toggled command list.", true)
			# Toggle instead of always showing
			command_list_parent_container.visible = not command_list_parent_container.visible
			if command_list_parent_container.visible:
				_populate_command_list()
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
			if amount < 0:
				PortfolioManager.spend_cash(-amount)
			else:
				PortfolioManager.add_cash(amount)
			#var current_cash = StatManager.get_stat("cash")
			#StatManager.set_base_stat("cash", current_cash + amount)
			return true

		"gimme":
			PortfolioManager.add_cash(100000000)
			PlayerManager.set_var("ex", 100)
			return true

		"set_stat":
			if parts.size() < 3:
				_set_feedback("Usage: set_stat <stat_name> <value>", false)
				return false

			var stat_name := parts[1]
			var value_str = command.substr(command.findn(stat_name) + stat_name.length()).strip_edges()

			# --- determine the expected type from current stat ---
			var current_value = StatManager.get_stat(stat_name)
			if current_value == null:
				_set_feedback("❌ Unknown stat '%s'.".format([stat_name]), false)
				return false

			var expected_type := typeof(current_value)

			# --- parse attempted new value ---
			var new_value = null
			var parsed_number = _parse_number(value_str)
			if parsed_number != null:
				new_value = parsed_number
			else:
				new_value = value_str

			# --- type check ---
			var new_type := typeof(new_value)
			var type_ok := false

			# Allow int/float interchange if stat is numeric
			if (expected_type == TYPE_FLOAT or expected_type == TYPE_INT) and (new_type == TYPE_FLOAT or new_type == TYPE_INT):
				type_ok = true
			elif expected_type == new_type:
				type_ok = true

			if not type_ok:
				var expected_name := type_string(expected_type)
				var got_name := type_string(new_type)
				var msg := "❌ Stat '{0}' expects type {1} but got {2}.".format([stat_name, expected_name, got_name])
				_set_feedback(msg, false)
				return false


			# --- apply ---
			StatManager.set_base_stat(stat_name, new_value)
			var label := Label.new()
			label.text = "%s's value is now %s" % [stat_name, str(new_value)]
			command_log_container.add_child(label)
			return true



		"list_stats":
			var all_stats := StatManager.get_all_stats()
			var stat_keys := all_stats.keys()
			stat_keys.sort()
			for stat_key in stat_keys:
				var label := Label.new()
				label.text = "%s: %s" % [stat_key, str(all_stats[stat_key])]
				command_log_container.add_child(label)
			return true
		
		
		"stress_test":
			for app_name in WindowManager.app_registry.keys():
				WindowManager.launch_app_by_name(app_name)
			return true
		
		
		"clear_log":
			_clear_command_log()
			_set_feedback("Command log cleared.", true)
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


func _clear_command_log() -> void:
	for child in command_log_container.get_children():
		child.queue_free()
