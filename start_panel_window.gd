extends Window
class_name StartPanelWindow

func toggle_start_panel():
	if %StartPanel.visible:
		%StartPanel.hide()
	else:
		%StartPanel.popup()
		%StartPanel.position = Vector2(1, 259)
