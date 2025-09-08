extends Node

@export var target_pane: Pane


func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed:
				var ev: InputEventKey = event as InputEventKey
				if ev.keycode == KEY_SPACE:
						TraumaManager.hit_global(0.6)
				if ev.keycode == KEY_T and target_pane != null:
						TraumaManager.hit_pane(target_pane, 0.6)
				if ev.keycode == KEY_W and target_pane != null:
						TraumaManager.hit_window_frame(target_pane, 0.6)
