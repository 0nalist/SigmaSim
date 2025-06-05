#editor_canvas.gd
@tool
extends Control


#signal node_selected(node)
signal node_clicked(node)
signal connection_started(from_node)
signal connection_finished(to_node)

# Editor state
var upgrade_nodes := []
var dragging_node = null
var drag_offset := Vector2.ZERO

var connecting_from = null
var mouse_pos := Vector2.ZERO

#func _ready():
#	if Engine.is_editor_hint():
#		add_upgrade_node(null, Vector2(100,100), "A", true)
#		add_upgrade_node(null, Vector2(300,200), "B")
	#custom_minimum_size = Vector2(20000, 20000)


# Add/Remove
func add_upgrade_node(upgrade_resource, position: Vector2, display_name: String = "", is_major := false):
	var node_scene = preload("res://tools/upgrade_editor/upgrade_node_editor.tscn")
	var node = node_scene.instantiate()
	node.upgrade_resource = upgrade_resource
	node.display_name = display_name
	node.is_major = is_major
	add_child(node)
	node.position = position
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	upgrade_nodes.append(node)
	node.gui_input.connect(_on_node_gui_input.bind(node))
	return node

func _on_node_gui_input(event, node):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Start a connection from this node
			connecting_from = node
			mouse_pos = event.position
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				emit_signal("node_clicked", node)
				dragging_node = node
				drag_offset = event.position
			else:
				dragging_node = null
	elif event is InputEventMouseMotion:
		mouse_pos = event.position
		if dragging_node == node:
			node.position += event.relative

func _draw():
	var editor = get_parent()
	if not editor.grid_enabled:
		return

	var window_size = editor.size         # <- use the parent's size, not get_size()
	var gs = editor.grid_size * editor.zoom
	var pan = editor.pan_offset
	var zoom = editor.zoom

	# Visible area in graph-space coordinates:
	var top_left = -pan / zoom
	var bottom_right = (window_size - pan) / zoom

	var min_x = floor(top_left.x / editor.grid_size) * editor.grid_size
	var max_x = ceil(bottom_right.x / editor.grid_size) * editor.grid_size
	var min_y = floor(top_left.y / editor.grid_size) * editor.grid_size
	var max_y = ceil(bottom_right.y / editor.grid_size) * editor.grid_size

	var grid_color = Color(0.16, 0.16, 0.2, 0.42)

	# Draw vertical lines
	var x = min_x
	while x <= max_x:
		var sx = (x - top_left.x) * zoom
		draw_line(Vector2(sx, 0), Vector2(sx, window_size.y), grid_color, 1)
		x += editor.grid_size

	# Draw horizontal lines
	var y = min_y
	while y <= max_y:
		var sy = (y - top_left.y) * zoom
		draw_line(Vector2(0, sy), Vector2(window_size.x, sy), grid_color, 1)
		y += editor.grid_size






func _unhandled_input(event):
	if connecting_from and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		var target = _find_node_under_mouse(get_global_mouse_position())
		if target and target != connecting_from:
			# Set dependency in resource!
			_add_dependency(connecting_from, target)
		connecting_from = null

func _find_node_under_mouse(mouse_pos):
	for node in upgrade_nodes:
		var rect = Rect2(node.position, node.size)
		if rect.has_point(mouse_pos - self.position):
			return node
	return null

func _add_dependency(from_node, to_node):
	if from_node.upgrade_resource and to_node.upgrade_resource:
		if not to_node.upgrade_resource.prerequisites.has(from_node.upgrade_resource.resource_path):
			to_node.upgrade_resource.prerequisites.append(from_node.upgrade_resource.resource_path)
			print("Added dependency:", from_node.display_name, "->", to_node.display_name)
			queue_redraw()
