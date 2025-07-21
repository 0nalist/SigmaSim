extends Control
class_name ClickToDismiss

signal clicked_outside

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	visible = false

func show_dismiss_area():
	visible = true

func hide_dismiss_area():
	visible = false

func gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		visible = false
		if owner:
			owner.hide()
		emit_signal("clicked_outside")
