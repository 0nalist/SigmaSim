extends Pane
class_name Daterbase

@onready var query_edit: TextEdit = %QueryEdit
@onready var run_query_button: Button = %RunQueryButton
@onready var show_all_button: Button = %ShowAllButton
@onready var error_label: Label = %ErrorLabel
@onready var daterbase_tab_button: Button = %DaterbaseTabButton
@onready var sql_tab_button: Button = %SQLTabButton
@onready var headhunters_tab_button: Button = %HeadhuntersTabButton
@onready var daterbase_view: VBoxContainer = %DaterbaseView
@onready var sql_view: VBoxContainer = %SQLView
@onready var headhunters_view: VBoxContainer = %HeadhuntersView
@onready var results_container_daterbase: VBoxContainer = %ResultsContainer_Daterbase
@onready var results_container_sql: VBoxContainer = %ResultsContainer_SQL
@onready var hh_name_edit: LineEdit = %HHNameEdit
@onready var hh_create_button: Button = %HHCreateButton
@onready var hh_portrait_holder: VBoxContainer = %HHPortraitHolder
@onready var hh_stats_container: VBoxContainer = %HHStatsContainer
@onready var hh_open_fumble_button: Button = %HHOpenFumbleButton

# --- Grid control ---
var results_tree: Tree

# --- Table state ---
var current_headers: Array[String] = []
var current_rows: Array = []	 # Array[Dictionary]
var sort_column_index: int = -1
var sort_ascending: bool = true

# --- Parsing helpers ---
var numeric_regex: RegEx

# --- Config ---
const EXTRA_HEADER_PADDING: int = 10

# --- Column-resize state ---
const RESIZE_MARGIN: int = 6
var is_resizing_column: bool = false
var resizing_column_index: int = -1
var resize_start_mouse_x: float = 0.0
var resize_start_column_width: int = 0

var column_user_min_widths: Array[int] = []  # per-column min widths from user drag, 0 = not set yet

var _active_tab: StringName = &"Daterbase"
var _ran_initial_show_all: bool = false

var _portrait_views_by_npc: Dictionary = {}
var _affinity_labels_by_npc: Dictionary = {}
var _exclusivity_labels_by_npc: Dictionary = {}

var hh_current_npc: NPC = null

const PORTRAIT_SCENE: PackedScene = preload("res://components/portrait/portrait_view.tscn")
const EX_FACTOR_VIEW_SCENE: PackedScene = preload("res://components/popups/ex_factor_view.tscn")
const STAGE_NAMES: Array[String] = ["STRANGER", "TALKING", "DATING", "SERIOUS", "ENGAGED", "MARRIED", "DIVORCED", "EX"]
const DATERBASE_HEADERS: Array[String] = [
"Portrait",
"Full Name",
"Dime Status",
"Relationship Status",
"Exclusivity",
"Affinity",
]


func _ready() -> void:
	run_query_button.pressed.connect(_on_run_query_pressed)
	show_all_button.pressed.connect(_on_show_all_pressed)
	daterbase_tab_button.pressed.connect(_on_daterbase_tab_pressed)
	sql_tab_button.pressed.connect(_on_sql_tab_pressed)
	headhunters_tab_button.pressed.connect(_on_headhunters_tab_pressed)
	hh_create_button.pressed.connect(_on_hh_create_pressed)
	hh_name_edit.text_submitted.connect(_on_hh_name_submitted)
        hh_open_fumble_button.pressed.connect(_on_hh_open_fumble_button_pressed)

        _refresh_hh_open_fumble_button()

	NPCManager.portrait_changed.connect(_on_npc_portrait_changed)
	NPCManager.affinity_changed.connect(_on_npc_affinity_changed)
	NPCManager.exclusivity_core_changed.connect(_on_npc_exclusivity_core_changed)

	numeric_regex = RegEx.new()
	numeric_regex.compile("^[-+]?\\d*(?:\\.\\d+)?(?:[eE][-+]?\\d+)?$")

	_build_table_shell()
	UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	_update_tab_unlocks()
	_activate_tab(&"Daterbase")

# =========================================
# Shell
# =========================================
func _build_table_shell() -> void:
	_clear_results()

	results_tree = Tree.new()
	results_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_tree.hide_root = true
	results_tree.columns = 1
	results_tree.column_titles_visible = true
	results_tree.allow_reselect = true
	results_tree.select_mode = Tree.SELECT_ROW

	results_tree.item_activated.connect(_on_item_activated)
	results_tree.gui_input.connect(_on_tree_gui_input)

	results_container_sql.add_child(results_tree)

func _on_item_activated() -> void:
		pass

# =========================================
# Tabs
# =========================================
func _activate_tab(tab_name: StringName) -> void:
	if tab_name != &"Daterbase" and tab_name != &"SQL" and tab_name != &"Headhunters":
		push_error("Invalid tab: %s" % str(tab_name))
		return
	_active_tab = tab_name
	if tab_name == &"Daterbase":
		daterbase_tab_button.set_pressed(true)
		sql_tab_button.set_pressed(false)
		headhunters_tab_button.set_pressed(false)
		daterbase_view.visible = true
		sql_view.visible = false
		headhunters_view.visible = false
		error_label.text = ""
		if not _ran_initial_show_all:
				_on_show_all_pressed()
				_ran_initial_show_all = true
	elif tab_name == &"SQL":
		daterbase_tab_button.set_pressed(false)
		sql_tab_button.set_pressed(true)
		headhunters_tab_button.set_pressed(false)
		daterbase_view.visible = false
		sql_view.visible = true
		headhunters_view.visible = false
		error_label.text = ""
		_ensure_results_tree_parent(results_container_sql)
		query_edit.grab_focus()
	else:
                daterbase_tab_button.set_pressed(false)
                sql_tab_button.set_pressed(false)
                headhunters_tab_button.set_pressed(true)
                daterbase_view.visible = false
                sql_view.visible = false
                headhunters_view.visible = true
                error_label.text = ""
                hh_name_edit.grab_focus()
                _refresh_hh_open_fumble_button()



func _ensure_results_tree_parent(target_container: VBoxContainer) -> void:
	if results_tree.get_parent() != target_container:
		results_tree.reparent(target_container)


func _on_daterbase_tab_pressed() -> void:
		_activate_tab(&"Daterbase")

func _on_sql_tab_pressed() -> void:
				_activate_tab(&"SQL")

func _on_headhunters_tab_pressed() -> void:
		_activate_tab(&"Headhunters")

func _update_tab_unlocks() -> void:
		sql_tab_button.disabled = UpgradeManager.get_level("daterbase_unlock_sql") <= 0
		headhunters_tab_button.disabled = UpgradeManager.get_level("daterbase_unlock_headhunters") <= 0
		if sql_tab_button.disabled and _active_tab == &"SQL":
				_activate_tab(&"Daterbase")
		if headhunters_tab_button.disabled and _active_tab == &"Headhunters":
				_activate_tab(&"Daterbase")

func _on_upgrade_purchased(id: String, _level: int) -> void:
                if id == "daterbase_unlock_sql" or id == "daterbase_unlock_headhunters":
                                _update_tab_unlocks()

func _refresh_hh_open_fumble_button() -> void:
                var cost: float = PlayerManager.get_var("hh_open_fumble_cost", 10)
                hh_open_fumble_button.text = "Open in Fumble (%d EX)" % int(cost)
                hh_open_fumble_button.disabled = hh_current_npc == null or StatManager.get_stat("ex", 0.0) < cost

# =========================================
# Buttons
# =========================================
func _on_show_all_pressed() -> void:
	query_edit.text = ""
	error_label.text = ""
	_ran_initial_show_all = true
	_load_default_entries()
	if _active_tab == &"SQL":
		_activate_tab(&"Daterbase")

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

func _on_hh_create_pressed() -> void:
		var name: String = hh_name_edit.text.strip_edges()
		if name == "":
				return
		_display_headhunter_npc(name)

func _on_hh_name_submitted(_text: String) -> void:
		_on_hh_create_pressed()


func _display_headhunter_npc(full_name: String) -> void:
	for child in hh_portrait_holder.get_children():
		child.queue_free()
	for child in hh_stats_container.get_children():
		child.queue_free()

        var npc: NPC = NPCFactory.create_npc_from_name(full_name)
        hh_current_npc = npc
        _refresh_hh_open_fumble_button()

	var portrait: PortraitView = PORTRAIT_SCENE.instantiate()
	portrait.portrait_creator_enabled = false
	portrait.custom_minimum_size = Vector2(132, 132)
	portrait.size = Vector2(132, 132)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.apply_config(npc.portrait_config)
	hh_portrait_holder.add_child(portrait)

	var stats: Dictionary = npc.to_dict()
	var keys := stats.keys()
	keys.sort()
	for key in keys:
		var val = stats[key]
		var lbl := Label.new()
		if typeof(val) in [TYPE_DICTIONARY, TYPE_ARRAY]:
			lbl.text = "%s: %s" % [key, JSON.stringify(val)]
		else:
			lbl.text = "%s: %s" % [key, str(val)]
		hh_stats_container.add_child(lbl)


func _on_hh_open_fumble_button_pressed() -> void:
                if hh_current_npc == null:
                                return
                var cost: float = PlayerManager.get_var("hh_open_fumble_cost", 10)
                var current_ex: float = StatManager.get_stat("ex", 0.0)
                if current_ex < cost:
                                return
                StatManager.set_base_stat("ex", current_ex - cost)
                PlayerManager.set_var("hh_open_fumble_cost", cost * 2)
                _refresh_hh_open_fumble_button()
                var idx = NPCManager.get_batch_of_new_npc_indices("fumble", 1)[0]
                NPCManager.npcs[idx] = hh_current_npc
                WindowManager.launch_app_by_name("Fumble")
                await get_tree().process_frame
                var win = WindowManager.find_window_by_app("Fumble")
                if win and win.pane is FumbleUI:
                                var pane: FumbleUI = win.pane
                                pane.add_npc_profile_to_top(idx)

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
	for child in results_container_daterbase.get_children():
		child.queue_free()
	_portrait_views_by_npc.clear()
	_affinity_labels_by_npc.clear()
	_exclusivity_labels_by_npc.clear()

	var npc_indices: Array[int] = NPCManager.get_daterbase_npcs()
	if sort_column_index != -1:
			npc_indices.sort_custom(_npc_less_than)
			if not sort_ascending:
					npc_indices.reverse()
	if npc_indices.is_empty():
			var empty_label: Label = Label.new()
			empty_label.text = "no one wants you yet"
			empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			results_container_daterbase.add_child(empty_label)
			return

	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header_buttons: Array[Button] = []
	for header_index in range(DATERBASE_HEADERS.size()):
			var base_text: String = DATERBASE_HEADERS[header_index]
			if sort_column_index == header_index:
					if sort_ascending:
							base_text += " ▲"
					else:
							base_text += " ▼"
			var btn: Button = _create_header_button(base_text, header_index)
			header_buttons.append(btn)
			header.add_child(btn)
	results_container_daterbase.add_child(header)

	var default_font: Font = get_theme_default_font()
	var default_font_size: int = get_theme_default_font_size()
	var column_widths: Array[int] = [132, 0, 0, 0, 0, 0]

	for header_index in range(1, header_buttons.size()):
			var header_size: Vector2 = default_font.get_string_size(header_buttons[header_index].text, default_font_size)
			column_widths[header_index] = int(ceil(header_size.x)) + EXTRA_HEADER_PADDING

	var rows: Array[HBoxContainer] = []
	for npc_idx in npc_indices:
		var npc_object: NPC = NPCManager.get_npc_by_index(npc_idx)
		if npc_object.relationship_stage == NPCManager.RelationshipStage.STRANGER:
			NPCManager.set_relationship_stage(npc_idx, NPCManager.RelationshipStage.TALKING)
			npc_object.relationship_stage = NPCManager.RelationshipStage.TALKING
			npc_object.affinity += 1

		var row: HBoxContainer = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_row_gui_input.bind(npc_idx, npc_object))

		var portrait: PortraitView = PORTRAIT_SCENE.instantiate()
		portrait.portrait_creator_enabled = false
		portrait.custom_minimum_size = Vector2(132, 132)
		portrait.size = Vector2(132, 132)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if npc_object.portrait_config != null:
			portrait.apply_config(npc_object.portrait_config)
		_portrait_views_by_npc[npc_idx] = portrait
		row.add_child(portrait)

		var name_label: Label = Label.new()
		name_label.text = npc_object.full_name
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(name_label)

		var dime_label: Label = Label.new()
		dime_label.text = "🔥 %.1f/10" % (float(npc_object.attractiveness) / 10.0)
		dime_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(dime_label)

		var rel_label: Label = Label.new()
		rel_label.text = STAGE_NAMES[npc_object.relationship_stage]
		rel_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(rel_label)

		var ex_label: Label = Label.new()
		ex_label.text = NPCManager.exclusivity_descriptor_label(npc_idx)
		ex_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ex_label)
		_exclusivity_labels_by_npc[npc_idx] = ex_label

		var affinity_label: Label = Label.new()
		affinity_label.text = "%.1f" % npc_object.affinity
		affinity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(affinity_label)
		_affinity_labels_by_npc[npc_idx] = affinity_label

		var text_values: Array = [
			name_label.text,
			dime_label.text,
			rel_label.text,
			ex_label.text,
			affinity_label.text
		]
		for idx in range(text_values.size()):
			var measured: Vector2 = default_font.get_string_size(text_values[idx], default_font_size)
			column_widths[idx + 1] = max(column_widths[idx + 1], int(ceil(measured.x)) + EXTRA_HEADER_PADDING)

		results_container_daterbase.add_child(row)
		rows.append(row)

		for header_index in range(header_buttons.size()):
				header_buttons[header_index].custom_minimum_size.x = column_widths[header_index]
				if header_index != 0:
						header_buttons[header_index].size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for row in rows:
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for child_index in range(row.get_child_count()):
			var ctrl: Control = row.get_child(child_index)
			ctrl.custom_minimum_size.x = column_widths[child_index]
			if child_index != 0:
				ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _create_header_button(text: String, column_index: int) -> Button:
		var btn := Button.new()
		btn.text = text
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_header_pressed.bind(column_index))
		return btn
	
func _on_row_gui_input(event: InputEvent, idx: int, npc: NPC) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		_open_ex_factor_view(idx, npc)

func _open_ex_factor_view(idx: int, npc: NPC) -> void:
		var key: String = "ex_factor_%d" % idx
		WindowManager.launch_popup(EX_FACTOR_VIEW_SCENE, key, {"npc": npc, "npc_idx": idx})

func _on_npc_portrait_changed(idx: int, cfg: PortraitConfig) -> void:
	if _portrait_views_by_npc.has(idx):
		var portrait: PortraitView = _portrait_views_by_npc[idx]
		portrait.apply_config(cfg)


func _on_npc_affinity_changed(idx: int, value: float) -> void:
		if _affinity_labels_by_npc.has(idx):
				var lbl: Label = _affinity_labels_by_npc[idx]
				lbl.text = "%.1f" % value

func _on_npc_exclusivity_core_changed(idx: int, _old_core: int, _new_core: int) -> void:
		if _exclusivity_labels_by_npc.has(idx):
								var lbl: Label = _exclusivity_labels_by_npc[idx]
								lbl.text = NPCManager.exclusivity_descriptor_label(idx)

func _on_header_pressed(column_index: int) -> void:
		if sort_column_index == column_index:
				sort_ascending = not sort_ascending
		else:
				sort_column_index = column_index
				sort_ascending = true
		_load_default_entries()

func _npc_less_than(left_idx: int, right_idx: int) -> bool:
		var left_npc: NPC = NPCManager.get_npc_by_index(left_idx)
		var right_npc: NPC = NPCManager.get_npc_by_index(right_idx)
		var left_value: Variant = _get_sort_value(left_idx, left_npc)
		var right_value: Variant = _get_sort_value(right_idx, right_npc)
		return _compare_any(left_value, right_value, true)

func _get_sort_value(idx: int, npc: NPC) -> Variant:
		match sort_column_index:
				0:
						return idx
				1:
						return npc.full_name
				2:
						return npc.attractiveness
				3:
						return npc.relationship_stage
				4:
						return NPCManager.exclusivity_descriptor_for(npc.relationship_stage, npc.exclusivity_core, npc.claimed_exclusive_boost)
				5:
						return npc.affinity
				_:
						return idx

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
	var column_count: int = max(header_names.size(), 1)
	results_tree.columns = column_count
	results_tree.column_titles_visible = header_names.size() > 0

	# init user min widths
	column_user_min_widths.resize(current_headers.size())
	for init_index in range(column_user_min_widths.size()):
		column_user_min_widths[init_index] = 0

	for column_index in range(header_names.size()):
		results_tree.set_column_title(column_index, header_names[column_index])
		results_tree.set_column_expand(column_index, true)
		results_tree.set_column_clip_content(column_index, true)

	_apply_header_min_widths()
	_rebuild_tree_items()
	_update_header_arrows()


func _rebuild_tree_items() -> void:
	var root_item: TreeItem = results_tree.get_root()
	if root_item == null:
		root_item = results_tree.create_item()
	else:
		_clear_tree_rows()

	for row_dictionary in current_rows:
		var row_item: TreeItem = results_tree.create_item(root_item)
		for column_index in range(current_headers.size()):
			var column_key_name: String = current_headers[column_index]
			var cell_value: Variant = row_dictionary.get(column_key_name, "")
			row_item.set_text(column_index, _variant_to_string(cell_value))


# =========================================
# Sorting (header click only)
# =========================================
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
	# This may increase a column if the arrow makes the title wider;
	# it will not decrease below the user's chosen width.
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
		var base_min_width: int = int(ceil(measured_size.x)) + EXTRA_HEADER_PADDING

		var user_min_width: int = 0
		if column_index < column_user_min_widths.size():
			user_min_width = column_user_min_widths[column_index]

		var final_min_width: int = max(base_min_width, user_min_width)
		results_tree.set_column_custom_minimum_width(column_index, final_min_width)
		results_tree.set_column_expand(column_index, true)


func _get_header_text_min_width(column_index: int) -> int:
	var header_font: Font = results_tree.get_theme_font("font", "Tree")
	if header_font == null:
		header_font = get_theme_default_font()
	var header_font_size: int = results_tree.get_theme_font_size("font_size", "Tree")
	var title_text: String = results_tree.get_column_title(column_index)
	var measured_size: Vector2 = header_font.get_string_size(title_text, header_font_size)
	return int(ceil(measured_size.x)) + EXTRA_HEADER_PADDING

# =========================================
# Drag-resize + header click handling (no get_header_height)
# =========================================
func _on_tree_gui_input(input_event: InputEvent) -> void:
	var mouse_button_event: InputEventMouseButton = input_event as InputEventMouseButton
	var mouse_motion_event: InputEventMouseMotion = input_event as InputEventMouseMotion

	if mouse_motion_event != null:
		_on_mouse_motion(mouse_motion_event)
		return

	if mouse_button_event == null:
		return

	if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
		_on_mouse_left_pressed(mouse_button_event.position)
	elif mouse_button_event.button_index == MOUSE_BUTTON_LEFT and not mouse_button_event.pressed:
		_on_mouse_left_released()

func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	var pointer_position: Vector2 = event.position
	var header_threshold_y: float = _header_y_threshold()

	if is_resizing_column:
		var delta_x: float = pointer_position.x - resize_start_mouse_x
		var new_width: int = max(int(resize_start_column_width + delta_x), _get_header_text_min_width(resizing_column_index))
		# remember the user’s choice so header arrow updates won’t shrink it
		if resizing_column_index >= 0 and resizing_column_index < column_user_min_widths.size():
			column_user_min_widths[resizing_column_index] = new_width
		results_tree.set_column_custom_minimum_width(resizing_column_index, new_width)
		return

	# Only show resize cursor above header line and near a divider
	if pointer_position.y <= header_threshold_y:
		var divider_index: int = _get_nearby_divider_index(pointer_position.x)
		if divider_index != -1:
			results_tree.mouse_default_cursor_shape = Control.CURSOR_HSIZE
			return

	results_tree.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_mouse_left_pressed(local_pos: Vector2) -> void:
	var header_threshold_y: float = _header_y_threshold()

	if local_pos.y <= header_threshold_y:
		var divider_index: int = _get_nearby_divider_index(local_pos.x)
		if divider_index != -1:
			is_resizing_column = true
			resizing_column_index = divider_index
			resize_start_mouse_x = local_pos.x
			resize_start_column_width = results_tree.get_column_width(resizing_column_index)
			return

		var clicked_column: int = _get_column_from_x(local_pos.x)
		if clicked_column >= 0:
			if sort_column_index == clicked_column:
				sort_ascending = not sort_ascending
			else:
				sort_column_index = clicked_column
				sort_ascending = true
			_sort_rows(clicked_column, sort_ascending)
			_rebuild_tree_items()
			_update_header_arrows()




func _clear_tree_rows() -> void:
	var root_item: TreeItem = results_tree.get_root()
	if root_item == null:
		return
	var child_item: TreeItem = root_item.get_first_child()
	while child_item != null:
		var next_item: TreeItem = child_item.get_next()
		child_item.free()  # TreeItem is not a Node; free() removes it from the Tree
		child_item = next_item






func _on_mouse_left_released() -> void:
	if is_resizing_column:
		is_resizing_column = false
		resizing_column_index = -1

# Map an x-position to a column by summing widths
func _get_column_from_x(xpos: float) -> int:
	var running_sum: float = 0.0
	for column_index in range(current_headers.size()):
		running_sum += float(results_tree.get_column_width(column_index))
		if xpos < running_sum:
			return column_index
	return -1

# Find divider near x (returns left column index), only between columns
func _get_nearby_divider_index(xpos: float) -> int:
	var running_sum: float = 0.0
	for column_index in range(current_headers.size() - 1):
		running_sum += float(results_tree.get_column_width(column_index))
		if abs(xpos - running_sum) <= float(RESIZE_MARGIN):
			return column_index
	return -1

# Compute the header/beginning-of-rows Y threshold without get_header_height()
func _header_y_threshold() -> float:
	# If there is a visible first row, use its top as the divider
	var root_item: TreeItem = results_tree.get_root()
	if root_item != null:
		var first_child: TreeItem = root_item.get_first_child()
		if first_child != null:
			var first_row_rect: Rect2 = results_tree.get_item_area_rect(first_child, -1, -1)
			return first_row_rect.position.y

	# Fallback: font height + a little padding
	var header_font: Font = results_tree.get_theme_font("font", "Tree")
	if header_font == null:
		header_font = get_theme_default_font()
	var header_font_size: int = results_tree.get_theme_font_size("font_size", "Tree")
	var font_height: float = header_font.get_height(header_font_size)
	return max(20.0, font_height + 6.0)

# =========================================
# Utilities
# =========================================
func _clear_results() -> void:
		for child_node in results_container_daterbase.get_children():
				child_node.queue_free()
		for child_node in results_container_sql.get_children():
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
