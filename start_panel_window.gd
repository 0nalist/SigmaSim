extends Window
class_name StartPanelWindow

@onready var app_list_container: VBoxContainer = %AppListContainer
#@onready var settings_window: BaseAppUI = %SettingsWindow

@export var app_list: Array[PackedScene] = [
	preload("res://components/apps/grinderr/grinderr_window.tscn"),
	preload("res://components/apps/broke_rage/broke_rage_ui.tscn"),
	preload("res://components/apps/sigma_mail/sigma_mail_window.tscn"),
	#preload("res://settings_window.tscn"),

]

func _ready() -> void:
	for app_scene in app_list:
		var preview = app_scene.instantiate()

		if not (preview is BaseAppUI):
			push_error("App scene must extend BaseAppUI: " + str(app_scene))
			continue

		var button := Button.new()
		button.text = preview.app_title
		button.icon = preview.app_icon
		button.theme = preload("res://assets/windows_95_theme.tres")
		button.pressed.connect(func(): launch_app(app_scene))
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

func launch_app(app_scene: PackedScene) -> void:
	hide()

	var app_ui = app_scene.instantiate()

	if not (app_ui is BaseAppUI):
		push_error("App UI must extend BaseAppUI: " + str(app_ui))
		return

	var win := preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame
	win.call_deferred("set_window_title", app_ui.app_title)
	win.icon = app_ui.app_icon

	if app_ui.has_signal("title_updated"):
		app_ui.title_updated.connect(win.set_window_title)

	win.get_node("%ContentPanel").add_child(app_ui)
	WindowManager.register_window(win)


func _on_settings_button_pressed() -> void:
	launch_app(preload("res://settings_window.tscn"))
