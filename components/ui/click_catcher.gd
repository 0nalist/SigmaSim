extends Control
class_name ClickCatcher

signal clicked_outside(position: Vector2)

func _ready() -> void:
	#mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		emit_signal("clicked_outside", event.global_position)
