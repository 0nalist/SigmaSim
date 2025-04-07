extends Window
class_name StartPanelWindow

@onready var app_list_container: VBoxContainer = %AppListContainer

@export var app_list: Array[Dictionary] = [
	{
		"name": "Grinderr",
		"scene": preload("res://components/apps/grinderr/grinderr_window.tscn")
	},
	{
		"name": "BrokeRage",
		"scene": preload("res://components/apps/broke_rage/broke_rage_window.tscn")
	}
]

func _ready():
	for app in app_list:
		var button = Button.new()
		button.text = app.name

		var preview_instance = app.scene.instantiate()
		if preview_instance is DesktopWindow:
			button.icon = preview_instance.icon
			button.theme = preload("res://assets/windows_95_theme.tres")
			preview_instance.queue_free()

		#button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func():
			launch_or_focus_app(app.name, app.scene)
		)
		app_list_container.add_child(button)



func _input(event):
	if event.is_action_pressed("select"):
		if %StartPanel.visible:
			await get_tree().create_timer(.21).timeout
			close_start_panel()

func launch_or_focus_app(id: String, scene: PackedScene):
	close_start_panel()
	
	if WindowManager.open_windows.has(id):
		var win = WindowManager.open_windows[id]
		win.show()
		win.raise()
		win.grab_focus()
	else:
		var window = scene.instantiate() as Window
		WindowManager.register_window(window, id)




func toggle_start_panel():
	if %StartPanel.visible:
		%StartPanel.hide()
	else:
		%StartPanel.popup()
		%StartPanel.position = Vector2(0, 259)


func close_start_panel():
	%StartPanel.hide()
