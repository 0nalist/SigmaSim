extends Panel
class_name StartPanelWindow

@onready var app_list_container: VBoxContainer = %AppListContainer

@export var siggy_scene: PackedScene

signal save_pressed
signal load_pressed

var listening_for_clicks := false


func _ready() -> void:
	hide()
	for app_name in WindowManager.start_apps.keys():
		var app_scene: PackedScene = WindowManager.start_apps[app_name]
		var preview = app_scene.instantiate()
	
		if not (preview is Pane):
			push_error("App scene must extend Pane: " + str(app_scene))
			continue

		# --- Create Button --- #
		var button := Button.new()
		button.text = preview.window_title
		button.focus_mode = Control.FOCUS_NONE
		button.theme = preload("res://assets/themes/windows_95_theme.tres")
		button.custom_minimum_size = Vector2(160, 40)
		button.add_theme_font_size_override("font_size", 10)

		# --- Add Icon --- #
		if preview.window_icon:
			var icon_texture := TextureRect.new()
			icon_texture.texture = preview.window_icon
			icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_texture.custom_minimum_size = Vector2(24, 24)
			icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			button.add_child(icon_texture)
			icon_texture.position = Vector2(8, 8)  # slight padding if needed
			button.icon = null  # Make sure no built-in button icon

		button.pressed.connect(func():
			launch_app(app_name)
		)

		app_list_container.add_child(button)
		preview.queue_free()


func _input(event: InputEvent) -> void:
	if listening_for_clicks and event is InputEventMouseButton and event.pressed:
		# Check if the click is outside the StartPanel bounds
		if not Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
			hide()
			listening_for_clicks = false

func toggle_start_panel() -> void:
	if visible:
		hide()
	else:
		listening_for_clicks = true
		show()
		




func launch_app(app_name: String) -> void:
	WindowManager.launch_app_by_name(app_name)


func _on_settings_button_pressed() -> void:
	launch_app("Settings")


func _on_sleep_button_pressed() -> void:
	TimeManager.sleep_for(480)


func _on_mouse_exited() -> void:
	pass
	#if visible:
	#	hide()


func _on_sleep_button_2_pressed() -> void:
	TimeManager.sleep_for(8640)


func _on_siggy_button_pressed() -> void:
	var siggy = siggy_scene.instantiate()
	get_tree().get_root().add_child(siggy)


func _on_logout_button_pressed() -> void:
	GameManager._on_pause_logout()


func _on_save_button_pressed() -> void:
	save_pressed.emit()


func _on_load_button_pressed() -> void:
	load_pressed.emit()
