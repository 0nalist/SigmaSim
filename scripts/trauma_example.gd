extends Node

@export var target_control: Control


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var ev: InputEventKey = event as InputEventKey
		if ev.keycode == KEY_SPACE:
			TraumaManager.hit_global(0.6)
		if ev.keycode == KEY_T and target_control != null:
			TraumaManager.hit_pane(target_control, 0.6)
