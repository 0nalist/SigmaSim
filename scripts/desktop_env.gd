extends Control


@onready var start_panel: Window = %StartPanel


func _ready() -> void:
	hide_all_windows_and_panels()

func _input(event):
	if event:
		if event.is_action_pressed("ui_cancel"):
			get_tree().quit()
		#if event.is_action_pressed("select"):
		#	if %StartPanel.visible:
		#		await get_tree().create_timer(.25).timeout
		#		%StartPanel.hide()

func hide_all_windows_and_panels():
	%StartPanel.hide()
	%BrokeRageWindow.hide()
	%GrinderrWindow.hide()
	%TrashWindow.hide()
	%SigmaMailWindow.hide()

#func close_start_panel():
	#%StartPanel.hide()


# ------------------- #
# Start Menu Buttons
# ------------------- #

func _on_start_button_pressed() -> void:
	%StartPanel.toggle_start_panel()

#func toggle_start_panel():
#	%StartPanel.visible = not %StartPanel.visible
#	if %StartPanel.visible:
#		%StartPanel.grab_focus()

func _on_broke_rage_button_pressed() -> void:
	open_broke_rage()

func open_broke_rage():
	%BrokeRageWindow.show()
	%BrokeRageWindow.grab_focus()

func _on_grinderr_button_pressed() -> void:
	open_grinderr()

func open_grinderr():
	%GrinderrWindow.show()
	%GrinderrWindow.grab_focus()

func _on_sigma_mail_button_pressed() -> void:
	%SigmaMailWindow.show()
	%SigmaMailWindow.grab_focus()

func _on_trash_button_pressed() -> void:
	%TrashWindow.show()
	%TrashWindow.grab_focus()



# Move these functions later probably
