extends Pane
class_name Daterbase

@onready var query_edit: TextEdit = %QueryEdit
@onready var run_query_button: Button = %RunQueryButton
@onready var show_all_button: Button = %ShowAllButton
@onready var error_label: Label = %ErrorLabel
@onready var results_container: VBoxContainer = %ResultsContainer

func _ready() -> void:
	run_query_button.pressed.connect(_on_run_query_pressed)
	show_all_button.pressed.connect(_on_show_all_pressed)
	_load_default_entries()

func _on_show_all_pressed() -> void:
	query_edit.text = ""
	error_label.text = ""
	_load_default_entries()

func _on_run_query_pressed() -> void:
	var sql = query_edit.text.strip_edges()
	if sql == "":
		error_label.text = "Enter a SELECT query."
		return
	if not _is_safe_select(sql):
		error_label.text = "Only SELECT queries are allowed."
		return
	var rows = DBManager.execute_select(sql)
	if rows.size() == 0:
		error_label.text = "No results or invalid query."
	else:
		error_label.text = ""
	_display_generic_rows(rows)

func _is_safe_select(q: String) -> bool:
	var l = q.strip_edges().to_lower()
	if not l.begins_with("select"):
		return false
	for bad in ["drop", "delete", "insert", "update", "alter", "pragma"]:
		if bad in l:
				return false
	return true

func _load_default_entries() -> void:
	_clear_results()
	var entries = DBManager.get_daterbase_entries()
	for e in entries:
		var npc = NPCManager.get_npc_by_index(e.npc_id)
		_add_npc_row(npc, e.timestamp)

func _clear_results() -> void:
		for child in results_container.get_children():
			child.queue_free()

func _add_npc_row(npc: NPC, timestamp: int) -> void:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 64)
		var pic = TextureRect.new()
		pic.texture = npc.profile_pic if npc.profile_pic else preload("res://assets/prof_pics/silhouette.png")
		pic.custom_minimum_size = Vector2(64, 64)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		row.add_child(pic)
		var label = Label.new()
		label.text = "%s\nType: %s  Attract: %d  Affinity: %.1f\nObtained: %s" % [npc.full_name, npc.chat_battle_type, npc.attractiveness, npc.affinity, Time.get_datetime_string_from_unix_time(timestamp)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		results_container.add_child(row)

func _display_generic_rows(rows: Array) -> void:
	_clear_results()
	if rows.size() == 0:
		return
	var headers = rows[0].keys()
	var header_label = Label.new()
	header_label.text = ", ".join(headers)
	results_container.add_child(header_label)
	for r in rows:
		var line := []
		for h in headers:
			line.append(str(r.get(h, "")))
		var lbl = Label.new()
		lbl.text = ", ".join(line)
		lbl.tooltip_text = lbl.text
		results_container.add_child(lbl)
