#editor_canvas.gd
@tool
extends Control


signal node_selected(node)
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
				dragging_node = node
				drag_offset = event.position
			else:
				dragging_node = null
	elif event is InputEventMouseMotion:
		mouse_pos = event.position
		if dragging_node == node:
			node.position += event.relative

func _draw():
	if not get_parent().grid_enabled:
		return

	var sz = get_size()
	var gs = get_parent().grid_size

	var grid_color = Color(0.16, 0.16, 0.2, 0.42)

	# Draw vertical grid lines
	for x in range(0, int(sz.x / gs) + 2):
		var xpos = x * gs
		draw_line(Vector2(xpos, 0), Vector2(xpos, sz.y), grid_color, 1)
	# Draw horizontal grid lines
	for y in range(0, int(sz.y / gs) + 2):
		var ypos = y * gs
		draw_line(Vector2(0, ypos), Vector2(sz.x, ypos), grid_color, 1)





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
