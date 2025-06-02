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

# Pan and zoom state
var pan_offset: Vector2 = Vector2.ZERO
var zoom: float = 1.0
var is_panning: bool = false
var pan_start_mouse: Vector2 = Vector2.ZERO
var pan_start_offset: Vector2 = Vector2.ZERO

var current_scene_path: String = ""



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

# Add upgrade node (can be called from a button, etc.)
func add_upgrade_node(upgrade_resource, pos: Vector2, name: String = "", is_major: bool = false):
	var node = editor_canvas.add_upgrade_node(upgrade_resource, pos, name, is_major)
	dependency_overlay.queue_redraw()
	return node

# Called after node drag or dependency edit
func on_tree_changed():
	dependency_overlay.queue_redraw()

# Save/load helpers (optional, WIP)
func save_layout_to_file(path: String):
	var layout = []
	for node in editor_canvas.upgrade_nodes:
		var resource_path = ""
		if node.upgrade_resource != null and node.upgrade_resource.resource_path != null:
			resource_path = node.upgrade_resource.resource_path
		layout.append({
			"resource": resource_path,
			"pos": node.position,
			"display_name": node.display_name,
			"is_major": node.is_major,
		})
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_var(layout)
	f.close()

func load_layout_from_file(path: String):
	if not FileAccess.file_exists(path):
		return
	var f = FileAccess.open(path, FileAccess.READ)
	var layout = f.get_var()
	f.close()
	# Clear old nodes
	for n in editor_canvas.upgrade_nodes:
		n.queue_free()
	editor_canvas.upgrade_nodes.clear()
	# Add from file
	for n in layout:
		var resource = null
		if n["resource"] != "":
			resource = load(n["resource"])
		add_upgrade_node(resource, n["pos"], n["display_name"], n["is_major"])
	dependency_overlay.queue_redraw()


func _on_add_node_button_pressed() -> void:
	# Spawn in the center of current view or at a default spot
	var pos = editor_canvas.size / 2
	add_upgrade_node(null, pos, "Node" + str(editor_canvas.get_child_count() + 1), false)


func _on_clear_all_button_pressed() -> void:
	for node in editor_canvas.upgrade_nodes:
		node.queue_free()
	editor_canvas.upgrade_nodes.clear()
	dependency_overlay.queue_redraw()
	current_scene_path = ""      # Forget which file was last saved/loaded
	_update_save_name_label()

func _on_save_button_pressed() -> void:
	if current_scene_path == "":
		push_warning("No save file specified. Use 'Save As' first.")
		# Optionally: automatically open Save As dialog
		save_as_dialog.popup_centered()
		return
	save_canvas_as_scene(current_scene_path)




func _on_load_button_pressed() -> void:
	# For simplicity, use a hardcoded path or add a file dialog
	var filename = file_name_edit.text.strip_edges()
	if filename == "":
		push_warning("Filename cannot be empty!")
		return
	if not filename.ends_with(".tscn"):
		filename += ".tscn"
	var path = "res://data/upgrade_trees/" + filename
	load_canvas_scene(path)
	current_scene_path = path

func load_canvas_scene(path: String):
	if not ResourceLoader.exists(path):
		push_warning("Scene not found: " + path)
		return
	# Remove old nodes
	for node in editor_canvas.upgrade_nodes:
		node.queue_free()
	editor_canvas.upgrade_nodes.clear()
	# Remove any extra children just in case
	for child in editor_canvas.get_children():
		child.queue_free()
	# Instance the saved scene and re-parent its nodes
	var scene = load(path)
	if scene is PackedScene:
		var new_canvas = scene.instantiate()
		for child in new_canvas.get_children():
			editor_canvas.add_child(child)
			if child is UpgradeNodeEditor:
				editor_canvas.upgrade_nodes.append(child)
		print("Loaded upgrade tree from:", path)




func save_canvas_as_scene(path: String):
	var packed_scene = PackedScene.new()
	packed_scene.pack(editor_canvas)
	var err = ResourceSaver.save(packed_scene, path)
	if err == OK:
		print("Saved upgrade tree as scene to:", path)
	else:
		push_error("Failed to save scene: " + str(err))



func _update_save_name_label():
	if current_scene_path == "":
		save_name_label.text = "UNSAVED"
	else:
		# Only show the file name, not full path
		var split_path = current_scene_path.rsplit("/", false, 1)
		var name = current_scene_path
		if split_path.size() > 1:
			name = split_path[1]
		save_name_label.text = name


func _on_confirm_button_pressed() -> void:
	var filename = file_name_edit.text.strip_edges()
	if filename == "":
		push_warning("Filename cannot be empty!")
		return
	if not filename.ends_with(".tscn"):
		filename += ".tscn"
	var path = "res://data/upgrade_trees/" + filename
	save_canvas_as_scene(path)
	current_scene_path = path
	_update_save_name_label()
	save_as_dialog.hide()


func _on_save_as_button_pressed() -> void:
	file_name_edit.text = ""
	save_as_dialog.popup_centered()
