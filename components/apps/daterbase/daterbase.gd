extends Pane
class_name Daterbase

@onready var query_edit: TextEdit = %QueryEdit
@onready var run_query_button: Button = %RunQueryButton
@onready var show_all_button: Button = %ShowAllButton
@onready var error_label: Label = %ErrorLabel
@onready var results_container: VBoxContainer = %ResultsContainer

# --- Grid control ---
var results_tree: Tree

# --- Table state ---
var current_headers: Array[String] = []
var current_rows: Array = []        # Array[Dictionary]
var sort_column_index: int = -1
var sort_ascending: bool = true

# --- Parsing helpers ---
var numeric_regex: RegEx

# --- Config ---
const EXTRA_HEADER_PADDING: int = 10

func _ready() -> void:
	run_query_button.pressed.connect(_on_run_query_pressed)
	show_all_button.pressed.connect(_on_show_all_pressed)

	numeric_regex = RegEx.new()
	numeric_regex.compile("^[-+]?\\d*(?:\\.\\d+)?(?:[eE][-+]?\\d+)?$")

	_build_table_shell()
	_load_default_entries()

# =========================================
# Shell
# =========================================
func _build_table_shell() -> void:
	_clear_results()

	results_tree = Tree.new()
	results_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_tree.hide_root = true
	results_tree.columns = 0
	results_tree.column_titles_visible = true
	results_tree.allow_reselect = true
	results_tree.select_mode = Tree.SELECT_ROW

	results_tree.item_activated.connect(_on_item_activated)
	results_tree.gui_input.connect(_on_tree_gui_input)

	results_container.add_child(results_tree)

func _on_item_activated() -> void:
	pass

func _on_tree_gui_input(input_event: InputEvent) -> void:
	var mouse_event := input_event as InputEventMouseButton
	if mouse_event == null:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	# Sort on click anywhere in that column (header or body).
	var clicked_column: int = results_tree.get_column_at_position(mouse_event.position)
	if clicked_column >= 0:
		_on_column_clicked(clicked_column)

# =========================================
# Buttons
# =========================================
func _on_show_all_pressed() -> void:
	query_edit.text = ""
	error_label.text = ""
	_load_default_entries()

func _on_run_query_pressed() -> void:
	var sql_text: String = query_edit.text.strip_edges()
	if sql_text == "":
		error_label.text = "Enter a SELECT query."
		return
	if not _is_safe_select(sql_text):
		error_label.text = "Only SELECT queries are allowed."
		return

	var result_rows: Array = DBManager.execute_select(sql_text)
	if result_rows.size() == 0:
		error_label.text = "No results or invalid query."
		_render_table([], [])
		return

	error_label.text = ""
	_display_generic_rows(result_rows)

# =========================================
# Safety
# =========================================
func _is_safe_select(query_text: String) -> bool:
	var lower_query_text: String = query_text.strip_edges().to_lower()
	if not lower_query_text.begins_with("select"):
		return false
	for unsafe_keyword in ["drop", "delete", "insert", "update", "alter", "pragma"]:
		if lower_query_text.findn(unsafe_keyword) != -1:
			return false
	return true

# =========================================
# Data loading
# =========================================
func _load_default_entries() -> void:
	var daterbase_entries: Array = DBManager.get_daterbase_entries()
	var table_rows: Array = []
	for entry_dictionary in daterbase_entries:
		var npc_object: NPC = NPCManager.get_npc_by_index(entry_dictionary.npc_id)
		var table_row: Dictionary = {
			"Full Name": npc_object.full_name,
			"Type": str(npc_object.chat_battle_type),
			"Attractiveness": int(npc_object.attractiveness),
			"Affinity": float(npc_object.affinity),
			"Obtained": Time.get_datetime_string_from_unix_time(int(entry_dictionary.timestamp))
		}
		table_rows.append(table_row)

	var header_names: Array[String] = ["Full Name", "Type", "Attractiveness", "Affinity", "Obtained"]
	_render_table(header_names, table_rows)

func _display_generic_rows(result_rows: Array) -> void:
	if result_rows.size() == 0:
		_render_table([], [])
		return

	var first_row_dictionary: Dictionary = result_rows[0]
	var header_names: Array[String] = []
	for key_name in first_row_dictionary.keys():
		header_names.append(str(key_name))

	header_names.sort()
	_render_table(header_names, result_rows)

# =========================================
# Rendering with Tree
# =========================================
func _render_table(header_names: Array[String], row_dictionaries: Array) -> void:
	current_headers = header_names.duplicate()
	current_rows = row_dictionaries.duplicate()
	sort_column_index = -1
	sort_ascending = true

	results_tree.clear()
	results_tree.columns = header_names.size()
	results_tree.column_titles_visible = header_names.size() > 0

	for column_index in range(header_names.size()):
		results_tree.set_column_title(column_index, header_names[column_index])
		results_tree.set_column_expand(column_index, true)
		results_tree.set_column_clip_content(column_index, true)

	_apply_header_min_widths()
	_rebuild_tree_items()
	_update_header_arrows()

func _rebuild_tree_items() -> void:
	var root_item: TreeItem = results_tree.create_item()
	for row_dictionary in current_rows:
		var row_item: TreeItem = results_tree.create_item(root_item)
		for column_index in range(current_headers.size()):
			var column_key_name: String = current_headers[column_index]
			var cell_value: Variant = row_dictionary.get(column_key_name, "")
			row_item.set_text(column_index, _variant_to_string(cell_value))

# =========================================
# Sorting
# =========================================
func _on_column_clicked(column_index: int) -> void:
	if sort_column_index == column_index:
		sort_ascending = not sort_ascending
	else:
		sort_column_index = column_index
		sort_ascending = true

	_sort_rows(column_index, sort_ascending)
	_rebuild_tree_items()
	_update_header_arrows()

func _sort_rows(column_index: int, ascending_sort: bool) -> void:
	if current_headers.size() == 0:
		return
	var column_key_name: String = current_headers[column_index]
	current_rows.sort_custom(func(left_row: Dictionary, right_row: Dictionary) -> bool:
		var left_value: Variant = left_row.get(column_key_name)
		var right_value: Variant = right_row.get(column_key_name)
		return _compare_any(left_value, right_value, ascending_sort)
	)

func _compare_any(left_value: Variant, right_value: Variant, ascending_sort: bool) -> bool:
	var left_is_empty: bool = left_value == null or str(left_value) == ""
	var right_is_empty: bool = right_value == null or str(right_value) == ""
	if left_is_empty and right_is_empty:
		return false
	if left_is_empty and not right_is_empty:
		return not ascending_sort
	if right_is_empty and not left_is_empty:
		return ascending_sort

	var left_number: float = _to_number_or_nan(left_value)
	var right_number: float = _to_number_or_nan(right_value)
	var left_is_numeric: bool = not is_nan(left_number)
	var right_is_numeric: bool = not is_nan(right_number)

	if left_is_numeric and right_is_numeric:
		if ascending_sort:
			return left_number < right_number
		else:
			return left_number > right_number

	var left_string: String = str(left_value).to_lower()
	var right_string: String = str(right_value).to_lower()
	if ascending_sort:
		return left_string < right_string
	else:
		return left_string > right_string

func _to_number_or_nan(value_to_parse: Variant) -> float:
	if value_to_parse == null:
		return NAN
	if typeof(value_to_parse) == TYPE_INT:
		return float(value_to_parse)
	if typeof(value_to_parse) == TYPE_FLOAT:
		return float(value_to_parse)
	var string_value: String = str(value_to_parse).strip_edges()
	if string_value == "":
		return NAN
	if numeric_regex.search(string_value) == null:
		return NAN
	return string_value.to_float()

func _update_header_arrows() -> void:
	for column_index in range(current_headers.size()):
		var base_title: String = current_headers[column_index]
		if sort_column_index == column_index:
			if sort_ascending:
				results_tree.set_column_title(column_index, "%s ↑" % base_title)
			else:
				results_tree.set_column_title(column_index, "%s ↓" % base_title)
		else:
			results_tree.set_column_title(column_index, base_title)
	# keep widths consistent with changed titles
	_apply_header_min_widths()

# =========================================
# Column widths (min = header text width + 10px)
# =========================================
func _apply_header_min_widths() -> void:
	var header_font: Font = results_tree.get_theme_font("font", "Tree")
	if header_font == null:
		header_font = get_theme_default_font()
	var header_font_size: int = results_tree.get_theme_font_size("font_size", "Tree")

	for column_index in range(current_headers.size()):
		var title_text: String = results_tree.get_column_title(column_index)
		var measured_size: Vector2 = header_font.get_string_size(title_text, header_font_size)
		var min_width: int = int(ceil(measured_size.x)) + EXTRA_HEADER_PADDING
		# Godot 4.4: use set_column_custom_minimum_width, not set_column_min_width
		results_tree.set_column_custom_minimum_width(column_index, min_width) # 4.4 API
		results_tree.set_column_expand(column_index, true)

# =========================================
# Utilities
# =========================================
func _clear_results() -> void:
	for child_node in results_container.get_children():
		child_node.queue_free()

func _variant_to_string(input_value: Variant) -> String:
	if input_value == null:
		return ""
	match typeof(input_value):
		TYPE_DICTIONARY, TYPE_ARRAY:
			return JSON.stringify(input_value)
		TYPE_BOOL:
			if input_value:
				return "true"
			return "false"
		_:
			return str(input_value)
