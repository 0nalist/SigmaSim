extends Window
class_name StartPanelWindow




func _input(event):
	if event.is_action_pressed("select"):
		if %StartPanel.visible:
			await get_tree().create_timer(.21).timeout
			close_start_panel()

func toggle_start_panel():
	if %StartPanel.visible:
		%StartPanel.hide()
	else:
		%StartPanel.popup()
		%StartPanel.position = Vector2(0, 259)


func close_start_panel():
	%StartPanel.hide()
