#@tool
extends Panel
class_name UpgradeNodeEditor

signal node_deleted(node)
signal dependencies_cleared(node)
signal output_circle_pressed(node, global_pos)
signal input_circle_pressed(node, global_pos)

@export var tool_mode: bool = false

@export var upgrade_resource: UpgradeResource
@export var display_name: String = ""
@export var is_major: bool = false

var outgoing_dependencies: Array = [] # Array of node references (nodes that this node points to)
var incoming_dependencies: Array = [] # Array of node references (nodes that point to this node)


var _dragging := false
var _drag_start_mouse_pos := Vector2.ZERO
var _drag_start_node_pos := Vector2.ZERO

func _ready():
	#self.size = Vector2(80, 40)
	if upgrade_resource:
		if upgrade_resource.upgrade_name != "":
			display_name = upgrade_resource.upgrade_name
		else:
			display_name = upgrade_resource.resource_name
	else:
		display_name = "Unset"
	%Label.text = display_name
	modulate = Color(1.2, 1.2, 1.6) if is_major else Color(1, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_STOP
	%RedCircle.gui_input.connect(_on_output_circle_input)
	%GreenCircle.gui_input.connect(_on_input_circle_input)
	%DeleteButton.pressed.connect(_on_delete_pressed)
	%ClearDepsButton.pressed.connect(_on_clear_deps_pressed)
	
	%DeleteButton.visible = tool_mode
	%ClearDepsButton.visible = tool_mode
	%RedCircle.visible = tool_mode
	%GreenCircle.visible = tool_mode


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start_mouse_pos = get_global_mouse_position()
			_drag_start_node_pos = self.position
			var parent = get_parent()
			if parent:
				parent.move_child(self, parent.get_child_count() - 1)
		else:
			_dragging = false

	elif event is InputEventMouseMotion and _dragging:
		# Convert mouse delta from screen to canvas space
		var editor = get_parent().get_parent() # UpgradeTreeEditor
		var zoom = 1.0
		var pan = Vector2.ZERO
		if editor:
			zoom = editor.zoom if "zoom" in editor else 1.0
			pan = editor.pan_offset if "pan_offset" in editor else Vector2.ZERO

		# Mouse delta in canvas space
		var current_mouse_pos = get_global_mouse_position()
		var delta = (current_mouse_pos - _drag_start_mouse_pos) / zoom
		var new_pos = _drag_start_node_pos + delta
		# Snap to grid if enabled
		if editor and editor.snap_enabled:
			var grid_size = editor.grid_size
			# Snap center point to grid
			var center = new_pos + self.size * 0.5
			center = Vector2(
				round(center.x / grid_size) * grid_size,
				round(center.y / grid_size) * grid_size
			)
			new_pos = center - self.size * 0.5
		self.position = new_pos


		if editor and editor.has_method("on_tree_changed"):
			editor.on_tree_changed()

func _on_output_circle_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("output_circle_pressed", self, get_global_mouse_position())

func _on_input_circle_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("input_circle_pressed", self, get_global_mouse_position())

func set_upgrade_resource(new_resource: UpgradeResource):
	upgrade_resource = new_resource
	if upgrade_resource:
		if upgrade_resource.upgrade_name != "":
			display_name = upgrade_resource.upgrade_name
		else:
			display_name = upgrade_resource.resource_name
		%Label.text = display_name
		# Update prerequisites
		upgrade_resource.prerequisites.clear()
		for node in incoming_dependencies:
			if node.upgrade_resource and node.upgrade_resource.resource_path != "":
				var prereq_path = node.upgrade_resource.resource_path
				if not upgrade_resource.prerequisites.has(prereq_path):
					upgrade_resource.prerequisites.append(prereq_path)
	else:
		display_name = "Unset"
		%Label.text = "Unset"



func _on_delete_pressed():
	emit_signal("node_deleted", self)

func _on_clear_deps_pressed():
	emit_signal("dependencies_cleared", self)


func get_dependencies() -> Array:
	# Return all outgoing dependency nodes
	return outgoing_dependencies.duplicate()

func add_dependency(dep_node):
	# Add a dependency if not present, and update both sides
	if not outgoing_dependencies.has(dep_node):
		outgoing_dependencies.append(dep_node)
	if not dep_node.incoming_dependencies.has(self):
		dep_node.incoming_dependencies.append(self)
