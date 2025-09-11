extends Pane
class_name ConversationMaker

signal conversation_edited(conv_id: String)
signal graph_dirty

const CONVERSATIONS_PATH: String = "res://autoloads/conversations.json"
const NODES_PATH: String = "res://autoloads/nodes.json"
const CHOICES_PATH: String = "res://autoloads/choices.json"

@onready var graph_edit: GraphEdit = %GraphEdit
@onready var new_conversation_button: Button = %NewConversationButton
@onready var add_node_button: Button = %AddNodeButton
@onready var delete_node_button: Button = %DeleteNodeButton
@onready var add_choice_button: Button = %AddChoiceButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton

var conversation_registry: Dictionary = {}
var nodes: Dictionary = {}
var choices: Dictionary = {}
var current_conv_id: String = ""
var selected_node_id: String = ""

func _ready() -> void:
	load_conversations()
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.node_selected.connect(_on_node_selected)
	new_conversation_button.pressed.connect(_on_new_conversation_pressed)
	add_node_button.pressed.connect(_on_add_node_pressed)
	delete_node_button.pressed.connect(_on_delete_node_pressed)
	add_choice_button.pressed.connect(_on_add_choice_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)

func load_conversations() -> void:
	conversation_registry = _load_json(CONVERSATIONS_PATH)
	nodes = _load_json(NODES_PATH)
	choices = _load_json(CHOICES_PATH)


func build_graph_for_conversation(conv_id: String) -> void:
	graph_edit.clear_connections()
	for child: Node in graph_edit.get_children():
		child.queue_free()
	current_conv_id = conv_id

	var conv_nodes: Dictionary = nodes.get(conv_id, {})
	for node_id: String in conv_nodes.keys():
		var data: Dictionary = conv_nodes.get(node_id, {})
		var gnode: GraphNode = GraphNode.new()
		gnode.name = node_id

		var speaker: String = data.get("speaker", "")
		gnode.title = "%s: %s" % [speaker, node_id]
		gnode.position_offset = Vector2(float(data.get("layout_x", 0.0)), float(data.get("layout_y", 0.0)))
		graph_edit.add_child(gnode)

		gnode.position_offset_changed.connect(_on_node_moved.bind(gnode))

		var vbox: VBoxContainer = VBoxContainer.new()
		gnode.add_child(vbox)

		# Speaker option
		var speaker_option: OptionButton = OptionButton.new()
		speaker_option.add_item("PLAYER")
		speaker_option.add_item("NPC")
		if speaker == "PLAYER":
			speaker_option.select(0)
		else:
			speaker_option.select(1)
		vbox.add_child(speaker_option)
		speaker_option.item_selected.connect(_on_node_speaker_selected.bind(node_id, gnode))

		# Dialogue text
		var text_edit: TextEdit = TextEdit.new()
		text_edit.text = String(data.get("text", ""))
		vbox.add_child(text_edit)
		text_edit.text_changed.connect(_on_node_text_changed.bind(node_id, text_edit))

		# Conditions
		var conditions_edit: TextEdit = TextEdit.new()
		conditions_edit.text = JSON.stringify(data.get("conditions_json", []), "\t")
		vbox.add_child(conditions_edit)
		conditions_edit.text_changed.connect(_on_node_conditions_changed.bind(node_id, conditions_edit))

		# Effects
		var effects_edit: TextEdit = TextEdit.new()
		effects_edit.text = JSON.stringify(data.get("effects_json", []), "\t")
		vbox.add_child(effects_edit)
		effects_edit.text_changed.connect(_on_node_effects_changed.bind(node_id, effects_edit))

		# Tags
		var tags_edit: LineEdit = LineEdit.new()
		tags_edit.text = String(data.get("tags", ""))
		vbox.add_child(tags_edit)
		tags_edit.text_changed.connect(_on_node_tags_changed.bind(node_id))

		# Start / End checkboxes
		var start_check: CheckBox = CheckBox.new()
		start_check.text = "Start"
		start_check.button_pressed = bool(data.get("start", false))
		vbox.add_child(start_check)
		start_check.toggled.connect(_on_node_start_toggled.bind(node_id))

		var end_check: CheckBox = CheckBox.new()
		end_check.text = "End"
		end_check.button_pressed = bool(data.get("end", false))
		vbox.add_child(end_check)
		end_check.toggled.connect(_on_node_end_toggled.bind(node_id))

		# Ports
		var ports: Array = []
		var next_ref: String = data.get("next", "")
		if next_ref.begins_with("choice:"):
			var choice_id: String = next_ref.substr(7)
			var conv_choices: Dictionary = choices.get(conv_id, {})
			var choice_def: Dictionary = conv_choices.get(choice_id, {})
			var port_index: int = 0
			for option_id: String in choice_def.keys():
				gnode.set_slot(port_index, false, 0, Color.WHITE, true, 0, Color.WHITE)
				gnode.set_slot_name(port_index, option_id)
				ports.append(option_id)
				port_index += 1
		else:
			gnode.set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)
			gnode.set_slot_name(0, "next")
			ports.append("next")

		gnode.set_meta("ports", ports)


func add_node(conv_id: String, speaker: String, node_id: String, text: String = "", conditions_json: Variant = [], effects_json: Variant = [], tags: String = "", start: bool = false, end: bool = false) -> void:
	if not nodes.has(conv_id):
		nodes[conv_id] = {}
	var conv_nodes: Dictionary = nodes.get(conv_id, {})
	var node_data: Dictionary = {
		"speaker": speaker,
		"text": text,
		"next": "",
		"conditions_json": conditions_json,
		"effects_json": effects_json,
		"tags": tags,
		"start": start,
		"end": end,
		"layout_x": 0,
		"layout_y": 0
	}
	conv_nodes[node_id] = node_data
	build_graph_for_conversation(conv_id)
	emit_signal("graph_dirty")
	conversation_edited.emit(conv_id)

func delete_node(conv_id: String, node_id: String) -> void:
	var conv_nodes: Dictionary = nodes.get(conv_id, {})
	if not conv_nodes.has(node_id):
		return
	conv_nodes.erase(node_id)
	for other_id: String in conv_nodes.keys():
		var other: Dictionary = conv_nodes.get(other_id, {})
		if other.get("next", "") == node_id:
			other["next"] = ""
	var conv_choices: Dictionary = choices.get(conv_id, {})
	for choice_id: String in conv_choices.keys():
		var choice_def: Dictionary = conv_choices.get(choice_id, {})
		for option_id: String in choice_def.keys():
			var opt: Dictionary = choice_def.get(option_id, {})
			if opt.get("on_success_next", "") == node_id:
				opt["on_success_next"] = ""
			if opt.get("on_failure_next", "") == node_id:
				opt["on_failure_next"] = ""
	build_graph_for_conversation(conv_id)
	emit_signal("graph_dirty")
	conversation_edited.emit(conv_id)

func add_choice(conv_id: String, choice_id: String, option_id: String) -> void:
	if not choices.has(conv_id):
		choices[conv_id] = {}
	var conv_choices: Dictionary = choices.get(conv_id, {})
	if not conv_choices.has(choice_id):
		conv_choices[choice_id] = {}
	var choice_def: Dictionary = conv_choices.get(choice_id, {})
	if not choice_def.has(option_id):
		choice_def[option_id] = {
			"text": "",
			"success_chance": 1.0,
			"show_success_pct": false,
			"conditions_json": [],
			"on_success_next": "",
			"on_failure_next": "",
			"effects_success_json": [],
			"effects_failure_json": []
		}
	build_graph_for_conversation(conv_id)
	emit_signal("graph_dirty")
	conversation_edited.emit(conv_id)

func delete_choice(conv_id: String, choice_id: String, option_id: String) -> void:
	var conv_choices: Dictionary = choices.get(conv_id, {})
	if not conv_choices.has(choice_id):
		return
	if option_id == "":
		conv_choices.erase(choice_id)
	else:
		var choice_def: Dictionary = conv_choices.get(choice_id, {})
		choice_def.erase(option_id)
		if choice_def.size() == 0:
			conv_choices.erase(choice_id)
	build_graph_for_conversation(conv_id)
	emit_signal("graph_dirty")
	conversation_edited.emit(conv_id)

func save_data() -> void:
	_save_json(CONVERSATIONS_PATH, conversation_registry)
	_save_json(NODES_PATH, nodes)
	_save_json(CHOICES_PATH, choices)
	if ConversationManager != null and ConversationManager.has_method("_load_data"):
		ConversationManager._load_data()
	emit_signal("graph_dirty")

func get_node_property(conv_id: String, node_id: String, property: String) -> Variant:
	var conv_nodes: Dictionary = nodes.get(conv_id, {})
	var node: Dictionary = conv_nodes.get(node_id, {})
	return node.get(property)

func set_node_property(conv_id: String, node_id: String, property: String, value: Variant) -> void:
	var conv_nodes: Dictionary = nodes.get(conv_id, {})
	if not conv_nodes.has(node_id):
		return
	var node: Dictionary = conv_nodes.get(node_id, {})
	node[property] = value
	emit_signal("graph_dirty")
	conversation_edited.emit(conv_id)

func get_choice_option(conv_id: String, choice_id: String, option_id: String) -> Dictionary:
	var conv_choices: Dictionary = choices.get(conv_id, {})
	var choice_def: Dictionary = conv_choices.get(choice_id, {})
	return choice_def.get(option_id, {})

func set_choice_option(conv_id: String, choice_id: String, option_id: String, data: Dictionary) -> void:
	if not choices.has(conv_id):
		choices[conv_id] = {}
	var conv_choices: Dictionary = choices.get(conv_id, {})
	if not conv_choices.has(choice_id):
		conv_choices[choice_id] = {}
	var choice_def: Dictionary = conv_choices.get(choice_id, {})
	choice_def[option_id] = data
	emit_signal("graph_dirty")
	conversation_edited.emit(conv_id)

func _on_node_moved(gnode: GraphNode) -> void:
	if current_conv_id == "":
		return
	var conv_nodes: Dictionary = nodes.get(current_conv_id, {})
	if not conv_nodes.has(gnode.name):
		return
	var data: Dictionary = conv_nodes.get(gnode.name, {})
	data["layout_x"] = gnode.position_offset.x
	data["layout_y"] = gnode.position_offset.y
	emit_signal("graph_dirty")

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var port_name: String = _get_port_name(String(from_node), from_port)
	var conv_nodes: Dictionary = nodes.get(current_conv_id, {})
	var from_data: Dictionary = conv_nodes.get(String(from_node), {})
	if port_name == "next":
		from_data["next"] = String(to_node)
	else:
		var choice_id: String = String(from_data.get("next", "")).substr(7)
		var conv_choices: Dictionary = choices.get(current_conv_id, {})
		var choice_def: Dictionary = conv_choices.get(choice_id, {})
		var option: Dictionary = choice_def.get(port_name, {})
		option["on_success_next"] = String(to_node)
	graph_edit.connect_node(from_node, from_port, to_node, to_port)
	emit_signal("graph_dirty")
	conversation_edited.emit(current_conv_id)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var port_name: String = _get_port_name(String(from_node), from_port)
	var conv_nodes: Dictionary = nodes.get(current_conv_id, {})
	var from_data: Dictionary = conv_nodes.get(String(from_node), {})
	if port_name == "next" and from_data.get("next", "") == String(to_node):
		from_data["next"] = ""
	else:
		var next_ref: String = String(from_data.get("next", ""))
		if next_ref.begins_with("choice:"):
			var choice_id: String = next_ref.substr(7)
			var conv_choices: Dictionary = choices.get(current_conv_id, {})
			var choice_def: Dictionary = conv_choices.get(choice_id, {})
			var option: Dictionary = choice_def.get(port_name, {})
			if option.get("on_success_next", "") == String(to_node):
				option["on_success_next"] = ""
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	emit_signal("graph_dirty")
	conversation_edited.emit(current_conv_id)

func _get_port_name(node_name: String, port_idx: int) -> String:
	var gnode: GraphNode = graph_edit.get_node_or_null(node_name)
	if gnode == null:
		return ""
	var ports: Array = gnode.get_meta("ports", [])
	if port_idx >= 0 and port_idx < ports.size():
		return String(ports[port_idx])
	return ""

func _on_node_selected(node: Node) -> void:
	selected_node_id = node.name


func _on_node_speaker_selected(index: int, node_id: String, gnode: GraphNode) -> void:
	var value: String
	if index == 0:
		value = "PLAYER"
	else:
		value = "NPC"

	set_node_property(current_conv_id, node_id, "speaker", value)
	gnode.title = "%s: %s" % [value, node_id]


func _on_node_text_changed(node_id: String, text_edit: TextEdit) -> void:
	set_node_property(current_conv_id, node_id, "text", text_edit.text)

func _on_node_conditions_changed(node_id: String, edit: TextEdit) -> void:
	var parsed: Variant = JSON.parse_string(edit.text)
	if typeof(parsed) == TYPE_ARRAY or typeof(parsed) == TYPE_DICTIONARY:
		set_node_property(current_conv_id, node_id, "conditions_json", parsed)

func _on_node_effects_changed(node_id: String, edit: TextEdit) -> void:
	var parsed: Variant = JSON.parse_string(edit.text)
	if typeof(parsed) == TYPE_ARRAY or typeof(parsed) == TYPE_DICTIONARY:
		set_node_property(current_conv_id, node_id, "effects_json", parsed)

func _on_node_tags_changed(new_text: String, node_id: String) -> void:
	set_node_property(current_conv_id, node_id, "tags", new_text)

func _on_node_start_toggled(pressed: bool, node_id: String) -> void:
	set_node_property(current_conv_id, node_id, "start", pressed)

func _on_node_end_toggled(pressed: bool, node_id: String) -> void:
	set_node_property(current_conv_id, node_id, "end", pressed)

func _on_new_conversation_pressed() -> void:
	var conv_id: String = "conversation_%d" % conversation_registry.size()
	conversation_registry[conv_id] = {
		"name": conv_id,
		"trigger_type": "",
		"trigger_args_json": {},
		"conditions_json": [],
		"priority": 0,
		"repeatable": false,
		"cooldown_days": 0,
		"weight": 1,
		"tags": ""
	}
	nodes[conv_id] = {}
	choices[conv_id] = {}
	current_conv_id = conv_id
	build_graph_for_conversation(conv_id)
	emit_signal("graph_dirty")
	conversation_edited.emit(conv_id)

func _on_add_node_pressed() -> void:
	if current_conv_id == "":
		return
	var conv_nodes: Dictionary = nodes.get(current_conv_id, {})
	var node_id: String = "node_%d" % conv_nodes.size()
	add_node(current_conv_id, "NPC", node_id)

func _on_delete_node_pressed() -> void:
	if current_conv_id == "" or selected_node_id == "":
		return
	delete_node(current_conv_id, selected_node_id)
	selected_node_id = ""

func _on_add_choice_pressed() -> void:
	if current_conv_id == "" or selected_node_id == "":
		return
	var conv_choices: Dictionary = choices.get(current_conv_id, {})
	var choice_id: String = "choice_%d" % conv_choices.size()
	add_choice(current_conv_id, choice_id, "option_0")
	var conv_nodes: Dictionary = nodes.get(current_conv_id, {})
	var node_data: Dictionary = conv_nodes.get(selected_node_id, {})
	node_data["next"] = "choice:%s" % choice_id
	build_graph_for_conversation(current_conv_id)
	emit_signal("graph_dirty")
	conversation_edited.emit(current_conv_id)

func _on_save_pressed() -> void:
	save_data()

func _on_load_pressed() -> void:
	load_conversations()
	if current_conv_id != "":
		build_graph_for_conversation(current_conv_id)

func _load_json(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		var text: String = FileAccess.get_file_as_string(path)
		var parsed: Variant = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			return parsed
	return {}

func _save_json(path: String, data: Dictionary) -> void:
	var text: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()
