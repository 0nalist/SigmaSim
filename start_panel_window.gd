extends Window
class_name StartPanelWindow

@onready var app_list_container: VBoxContainer = %AppListContainer


func _ready() -> void:
	for app_name in WindowManager.app_registry.keys():
		var app_scene: PackedScene = WindowManager.app_registry[app_name]
		var preview = app_scene.instantiate()

		if not (preview is BaseAppUI):
			push_error("App scene must extend BaseAppUI: " + str(app_scene))
			continue

		var button := Button.new()
		button.text = preview.app_title
		button.icon = preview.app_icon
		button.theme = preload("res://assets/windows_95_theme.tres")

		button.pressed.connect(func():
			launch_app(app_name)
		)

		app_list_container.add_child(button)
		preview.queue_free()


func toggle_start_panel() -> void:
	if visible:
		hide()
	else:
		popup()
		position = Vector2(0, 259)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select") and visible:
		await get_tree().create_timer(0.21).timeout
		hide()


func launch_app(app_name: String) -> void:
	hide()
	WindowManager.launch_app_by_name(app_name)


func _on_settings_button_pressed() -> void:
	launch_app("Settings")
