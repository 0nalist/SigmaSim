#settings_window.gd
extends BaseAppUI

@onready var fullscreen_check_box: CheckBox = %FullscreenCheckBox
@onready var windowed_check_box: CheckBox = %WindowedCheckBox
@onready var autosave_check_box: CheckBox = %AutosaveCheckBox


func _ready() -> void:
	update_checked_mode()
	app_title = "Settings"
	emit_signal("title_updated", app_title)
	# Disable fullscreen if running in embedded mode
	if OS.has_feature("editor") or DisplayServer.get_name() == "headless":
		fullscreen_check_box.disabled = true
	#%SiggyButton.toggled_on = Siggy.toggled_on
	autosave_check_box.button_pressed = TimeManager.autosave_enabled


func update_checked_mode() -> void:
	var mode = DisplayServer.window_get_mode()
	match mode:
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			fullscreen_check_box.button_pressed = true
			windowed_check_box.button_pressed = false
		DisplayServer.WINDOW_MODE_WINDOWED:
			fullscreen_check_box.button_pressed = false
			windowed_check_box.button_pressed = true
		_:
			# Handle other modes if needed
			fullscreen_check_box.button_pressed = false
			windowed_check_box.button_pressed = true



func _on_fullscreen_check_box_pressed() -> void:
	if fullscreen_check_box.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		windowed_check_box.button_pressed = false


func _on_windowed_check_box_pressed() -> void:
	if windowed_check_box.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_check_box.button_pressed = false


func _on_check_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_siggy_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%SiggyButton.text = "Never ever show me Siggy ever again"
	else:
		%SiggyButton.text = "Siggy. Please come back. I miss you"
	

func _on_autosave_check_box_toggled(toggled_on: bool) -> void:
	TimeManager.autosave_enabled = toggled_on
