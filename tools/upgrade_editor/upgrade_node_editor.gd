@tool
extends Panel
class_name UpgradeNodeEditor

signal output_circle_pressed(node, global_pos)
signal input_circle_pressed(node, global_pos)


@export var upgrade_resource: UpgradeResource
@export var display_name: String = ""
@export var is_major: bool = false

var _dragging := false
var _drag_start_mouse_pos := Vector2.ZERO
var _drag_start_node_pos := Vector2.ZERO

func _ready():
	self.size = Vector2(80, 40)
	%Label.text = display_name if display_name != "" else (upgrade_resource and upgrade_resource.resource_name or "Unset")
	modulate = Color(1.2, 1.2, 1.6) if is_major else Color(1, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_STOP
	%RedCircle.gui_input.connect(_on_output_circle_input)
	%GreenCircle.gui_input.connect(_on_input_circle_input)



func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			# Store the global mouse position and node position
			_drag_start_mouse_pos = get_global_mouse_position()
			_drag_start_node_pos = self.position
			# Bring to front
			var parent = get_parent()
			if parent:
				parent.move_child(self, parent.get_child_count() - 1)
		else:
			_dragging = false

	elif event is InputEventMouseMotion and _dragging:
		var current_mouse_pos = get_global_mouse_position()
		var delta = current_mouse_pos - _drag_start_mouse_pos
		self.position = _drag_start_node_pos + delta
		# Tell the editor tree has changed
		if owner and owner.has_method("on_tree_changed"):
			owner.on_tree_changed()

func _on_output_circle_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("output_circle_pressed", self, get_global_mouse_position())

func _on_input_circle_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("input_circle_pressed", self, get_global_mouse_position())
