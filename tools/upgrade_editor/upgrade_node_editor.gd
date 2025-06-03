@tool
extends Panel
class_name UpgradeNodeEditor

@export var upgrade_resource: UpgradeResource
@export var display_name: String = ""
@export var is_major: bool = false

var _dragging := false
var _drag_offset := Vector2.ZERO

func _ready():
	self.size = Vector2(80, 40)
	%Label.text = display_name if display_name != "" else (upgrade_resource and upgrade_resource.resource_name or "Unset")
	modulate = Color(1.2, 1.2, 1.6) if is_major else Color(1, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_STOP



func _on_gui_input(event: InputEvent) -> void:
	print("node touched!")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = event.position
			# Bring this node to front (top of stacking order)
			var parent = get_parent()
			if parent:
				parent.move_child(self, parent.get_child_count() - 1)
		else:
			_dragging = false

	elif event is InputEventMouseMotion and _dragging:
		# Move the node, keeping the offset where we grabbed it
		self.position += event.relative
		# Tell the editor tree has changed (if owner is set)
		if owner and owner.has_method("on_tree_changed"):
			owner.on_tree_changed()
