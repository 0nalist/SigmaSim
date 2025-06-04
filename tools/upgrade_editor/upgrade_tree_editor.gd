#upgrade_tree_editor.gd
@tool
extends Control

@onready var editor_canvas = %EditorCanvas
@onready var dependency_overlay = %DependencyOverlay

@onready var toolbar = %Toolbar
@onready var save_name_label: Label = %SaveNameLabel
@onready var add_node_button = %AddNodeButton
@onready var clear_all_button = %ClearAllButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var save_as_button = %SaveAsButton
@onready var save_as_dialog = %SaveAsDialog
@onready var file_name_edit = %FileNameEdit
@onready var confirm_button = %ConfirmButton

@onready var load_menu_button: MenuButton = %LoadMenuButton

var dependency_dragging_from: UpgradeNodeEditor = null
var dependency_dragging_pos: Vector2 = Vector2.ZERO

var grid_enabled := true
var snap_enabled := true
var grid_size := 32


# Pan and zoom state
var pan_offset: Vector2 = Vector2.ZERO
var zoom: float = 1.0
var is_panning: bool = false
var pan_start_mouse: Vector2 = Vector2.ZERO
var pan_start_offset: Vector2 = Vector2.ZERO

var current_resource_path: String = ""


func _ready():
	
	
	dependency_overlay.canvas = editor_canvas
	set_process(true)
	_update_save_name_label()

var _did_create_sample_node := false
func _process(_delta):
	if Engine.is_editor_hint() and not _did_create_sample_node:
		# Only add once
		if editor_canvas.get_child_count() == 0:
			editor_canvas.add_upgrade_node(null, size / 2, "First", true)
			_did_create_sample_node = true

func _unhandled_input(event):
	# Pan canvas with middle mouse drag or space + left mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or (event.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SPACE)):
			if event.pressed:
				is_panning = true
				pan_start_mouse = event.position
				pan_start_offset = pan_offset
			else:
				is_panning = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(zoom * 1.1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(zoom / 1.1, event.position)

	elif event is InputEventMouseMotion and is_panning:
		pan_offset = pan_start_offset + (event.position - pan_start_mouse)
		_apply_pan_zoom()

func _set_zoom(new_zoom: float, focus_point: Vector2):
	new_zoom = clamp(new_zoom, 0.2, 2.5)
	var local_focus = (focus_point - pan_offset) / zoom
	zoom = new_zoom
	_apply_pan_zoom()
	# Re-center zoom on focus
	pan_offset = focus_point - local_focus * zoom
	_apply_pan_zoom()

func _apply_pan_zoom():
	editor_canvas.position = pan_offset
	editor_canvas.scale = Vector2(zoom, zoom)
	dependency_overlay.position = pan_offset
	dependency_overlay.scale = Vector2(zoom, zoom)
	editor_canvas.queue_redraw()

# Add upgrade node (can be called from a button, etc.)
func add_upgrade_node(upgrade_resource, pos: Vector2, name: String = "", is_major: bool = false):
	var node = editor_canvas.add_upgrade_node(upgrade_resource, pos, name, is_major)
	node.tool_mode = true
	# Connect dependency signals
	node.node_deleted.connect(_on_node_deleted)
	node.dependencies_cleared.connect(_on_node_dependencies_cleared)
	node.output_circle_pressed.connect(_on_node_output_circle_pressed)
	node.input_circle_pressed.connect(_on_node_input_circle_pressed)
	dependency_overlay.queue_redraw()
	print("Added node at pos: ", pos)
	return node

func _on_node_deleted(node: UpgradeNodeEditor):
	# Remove all references to this node in other nodes' dependency lists
	for other in editor_canvas.upgrade_nodes:
		other.outgoing_dependencies.erase(node)
		other.incoming_dependencies.erase(node)
	# Remove from canvas and free
	editor_canvas.upgrade_nodes.erase(node)
	node.queue_free()
	dependency_overlay.queue_redraw()

func _on_node_dependencies_cleared(node: UpgradeNodeEditor):
	# Remove all dependency references involving this node
	for other in editor_canvas.upgrade_nodes:
		other.outgoing_dependencies.erase(node)
		other.incoming_dependencies.erase(node)
	node.outgoing_dependencies.clear()
	node.incoming_dependencies.clear()
	dependency_overlay.queue_redraw()



func _on_node_output_circle_pressed(node: UpgradeNodeEditor, global_pos: Vector2) -> void:
	# Start dependency drag from this node
	dependency_dragging_from = node
	dependency_dragging_pos = global_pos
	dependency_overlay.update_drag_line(global_pos, global_pos) # Start dummy line

func _on_node_input_circle_pressed(node: UpgradeNodeEditor, global_pos: Vector2) -> void:
	print("input circle pressed")
	if dependency_dragging_from and node != dependency_dragging_from:
		# Check for cycles
		if _creates_circular_dependency(dependency_dragging_from, node):
			print("Circular dependency prevented: %s -> %s" % [dependency_dragging_from.display_name, node.display_name])
			# Optional: show a dialog or UI warning here!
		elif not dependency_dragging_from.outgoing_dependencies.has(node):
			dependency_dragging_from.outgoing_dependencies.append(node)
			node.incoming_dependencies.append(dependency_dragging_from)
			print("Node dependency added: %s -> %s" % [dependency_dragging_from.display_name, node.display_name])
	dependency_dragging_from = null
	dependency_overlay.queue_redraw()


func _creates_circular_dependency(start_node: UpgradeNodeEditor, target_node: UpgradeNodeEditor) -> bool:
	# Returns true if adding a dependency from start_node to target_node would cause a cycle
	var stack = [target_node]
	var visited = {}
	while not stack.is_empty():
		var node = stack.pop_back()
		if node == start_node:
			return true  # A cycle would be created!
		if visited.has(node):
			continue
		visited[node] = true
		for dep in node.outgoing_dependencies:
			if is_instance_valid(dep):
				stack.append(dep)
	return false


func _input(event):
	# Update live drag line
	if dependency_dragging_from and event is InputEventMouseMotion:
		dependency_overlay.update_drag_line(
			dependency_dragging_from.get_global_position() + dependency_dragging_from.size * 0.5,
			get_global_mouse_position()
		)
	# Cancel on right-click
	if dependency_dragging_from and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		dependency_dragging_from = null
		dependency_overlay.clear_drag_line()
		dependency_overlay.queue_redraw()


# Called after node drag or dependency edit
func on_tree_changed():
	dependency_overlay.queue_redraw()




# --- SAVE / LOAD LOGIC ---

func save_tree_resource(path: String):
	print("Children of editor_canvas at save time:")
	for node in editor_canvas.get_children():
		print(" - ", node, " (type: ", typeof(node), ")")
	var tree = UpgradeTreeResource.new()
	var node_list = []
	# Build a mapping so dependencies can use indices
	var node_index = {}
	var nodes = []
	var i = 0
	for node in editor_canvas.get_children():
		if node is UpgradeNodeEditor:
			node_index[node] = i
			nodes.append(node)
			i += 1
	# Now collect node info and dependencies
	for idx in nodes.size():
		var node = nodes[idx]
		var upgrade_resource_path = ""
		if node.upgrade_resource != null:
			upgrade_resource_path = str(node.upgrade_resource.resource_path)
		var node_dict = {
			"position": node.position,
			"display_name": node.display_name,
			"is_major": node.is_major,
			"upgrade_resource_path": upgrade_resource_path,
			"dependencies": []
		}
		if node.has_method("get_dependencies"):
			for dep in node.get_dependencies():
				if node_index.has(dep):
					node_dict["dependencies"].append(node_index[dep])
		node_list.append(node_dict)
	tree.nodes = node_list

	print("NODES BEING SAVED: ", node_list)

	var err = ResourceSaver.save(tree, path)
	if err == OK:
		print("Saved tree resource to: ", path)
	else:
		push_error("Failed to save: " + str(err))


func load_tree_resource(path: String):
	var tree: UpgradeTreeResource = load(path)
	if not tree:
		push_warning("Failed to load tree resource.")
		return
	# Remove old nodes
	for node in editor_canvas.get_children():
		node.queue_free()

	# Add nodes and build index for dependencies
	var created_nodes: Array = []
	for node_dict in tree.nodes:
		var upgrade_res = null
		if node_dict.has("upgrade_resource_path"):
			var resource_path = node_dict["upgrade_resource_path"]
			if typeof(resource_path) == TYPE_STRING and resource_path != "":
				upgrade_res = load(resource_path)
		var node = add_upgrade_node(
			upgrade_res,
			node_dict["position"],
			node_dict.get("display_name", ""),
			node_dict.get("is_major", false)
		)
		created_nodes.append(node)

	# --- THIS SECTION CLEARS ALL DEPENDENCIES TO PREVENT DUPLICATES ---
	for node in created_nodes:
		node.outgoing_dependencies.clear()
		node.incoming_dependencies.clear()

	# --- THIS SECTION REWIRES DEPENDENCIES FROM SAVE DATA ---
	for i in tree.nodes.size():
		var dep_indices = tree.nodes[i].get("dependencies", [])
		for dep_idx in dep_indices:
			if dep_idx >= 0 and dep_idx < created_nodes.size():
				var dep_node = created_nodes[dep_idx]
				var this_node = created_nodes[i]
				this_node.add_dependency(dep_node)
	current_resource_path = path
	_update_save_name_label()
	await get_tree().process_frame
	await get_tree().process_frame
	dependency_overlay.queue_redraw()

# --- TOOLBAR BUTTONS ---

func _on_add_node_button_pressed():
	var pos = editor_canvas.size / 2
	add_upgrade_node(null, pos, "Node" + str(editor_canvas.get_child_count() + 1), false)

func _on_clear_all_button_pressed():
	for node in editor_canvas.get_children():
		node.queue_free()
	current_resource_path = ""
	_update_save_name_label()
	dependency_overlay.queue_redraw()

func _on_save_button_pressed():
	if current_resource_path == "":
		push_warning("No save file specified. Use 'Save As' first.")
		save_as_dialog.popup_centered()
		return
	save_tree_resource(current_resource_path)

func _on_save_as_button_pressed():
	file_name_edit.text = ""
	save_as_dialog.popup_centered()

func _on_confirm_button_pressed():
	var filename = file_name_edit.text.strip_edges()
	if filename == "":
		push_warning("Filename cannot be empty!")
		return
	if not filename.ends_with(".tres"):
		filename += ".tres"
	var path = "res://data/upgrade_trees/" + filename
	save_tree_resource(path)
	current_resource_path = path
	_update_save_name_label()
	save_as_dialog.hide()

## UNUSED, see _on_load_menu_button_pressed():
func _on_load_button_pressed():
	var filename = file_name_edit.text.strip_edges()
	if filename == "":
		push_warning("Filename cannot be empty!")
		return
	if not filename.ends_with(".tres"):
		filename += ".tres"
	var path = "res://data/upgrade_trees/" + filename
	load_tree_resource(path)
	current_resource_path = path
	_update_save_name_label()
	

func _update_save_name_label():
	if current_resource_path == "":
		save_name_label.text = "UNSAVED"
	else:
		var split_path = current_resource_path.rsplit("/", false, 1)
		var name = current_resource_path
		if split_path.size() > 1:
			name = split_path[1]
		save_name_label.text = name


func _on_load_menu_button_pressed():
	var popup = load_menu_button.get_popup()
	popup.clear()  # Remove old items
	var dir = DirAccess.open("res://data/upgrade_trees/")
	if dir:
		var idx = 0
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				popup.add_item(file_name, idx)
				idx += 1
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		popup.add_item("Could not open directory", 0)
	popup.id_pressed.connect(_on_load_menu_file_selected)
	

func _on_load_menu_file_selected(id):
	var popup = load_menu_button.get_popup()
	var file_name = popup.get_item_text(id)
	if not file_name.ends_with(".tres"):
		return
	var path = "res://data/upgrade_trees/" + file_name
	load_tree_resource(path)
	current_resource_path = path
	_update_save_name_label()
	dependency_overlay.queue_redraw()


func _on_show_grid_toggled(toggled_on: bool) -> void:
	grid_enabled = toggled_on
	editor_canvas.queue_redraw()


func _on_snap_to_grid_toggled(toggled_on: bool) -> void:
	snap_enabled = toggled_on
	editor_canvas.queue_redraw()


func _on_grid_size_value_changed(value: float) -> void:
	grid_size = int(value)
	editor_canvas.queue_redraw()
