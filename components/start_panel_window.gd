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

		var title = preview.window_title
		var icon_path := ""
		if preview.window_icon:
			icon_path = preview.window_icon.resource_path

		# --- Create Button --- #
		var button := Button.new()
		button.text = title
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

		button.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				var actions: Array = []
				var action_open: ContextAction = ContextAction.new()
				action_open.id = 0
				action_open.label = "Open"
				action_open.method = "launch_app"
				action_open.args = [app_name]
				actions.append(action_open)
				var action_shortcut: ContextAction = ContextAction.new()
				action_shortcut.id = 1
				action_shortcut.label = "Create Shortcut"
				action_shortcut.method = "_ctx_create_shortcut"
				action_shortcut.args = [app_name, title, icon_path]
				actions.append(action_shortcut)
				ContextMenuManager.open_for(self, event.global_position, actions)
				button.accept_event()
		)

		app_list_container.add_child(button)
		preview.queue_free()

func add_app_button(app_name: String) -> void:
	if not WindowManager.start_apps.has(app_name):
		return
	var app_scene: PackedScene = WindowManager.start_apps[app_name]
	var preview = app_scene.instantiate()
	if not (preview is Pane):
		push_error("App scene must extend Pane: " + str(app_scene))
		return
	var title = preview.window_title
	var icon_path := ""
	if preview.window_icon:
		icon_path = preview.window_icon.resource_path
	var button := Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_NONE
	button.theme = preload("res://assets/themes/windows_95_theme.tres")
	button.custom_minimum_size = Vector2(160, 40)
	button.add_theme_font_size_override("font_size", 10)
	if preview.window_icon:
		var icon_texture := TextureRect.new()
		icon_texture.texture = preview.window_icon
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.custom_minimum_size = Vector2(24, 24)
		icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		button.add_child(icon_texture)
		icon_texture.position = Vector2(8, 8)
		button.icon = null
	button.pressed.connect(func():
		launch_app(app_name)
	)
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var actions: Array = []
			var action_open: ContextAction = ContextAction.new()
			action_open.id = 0
			action_open.label = "Open"
			action_open.method = "launch_app"
			action_open.args = [app_name]
			actions.append(action_open)
			var action_shortcut: ContextAction = ContextAction.new()
			action_shortcut.id = 1
			action_shortcut.label = "Create Shortcut"
			action_shortcut.method = "_ctx_create_shortcut"
			action_shortcut.args = [app_name, title, icon_path]
			actions.append(action_shortcut)
			ContextMenuManager.open_for(self, event.global_position, actions)
			button.accept_event()
	)
	app_list_container.add_child(button)
	preview.queue_free()

func rebuild() -> void:
	for child in app_list_container.get_children():
		child.queue_free()
	for app_name in WindowManager.start_apps.keys():
		add_app_button(app_name)

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

func _ctx_create_shortcut(app_name: String, title: String, icon_path: String) -> void:
	DesktopLayoutManager.create_app_shortcut(app_name, title, icon_path, Vector2.ZERO)

func _on_settings_button_pressed() -> void:
	launch_app("Settings")

func _on_sleep_button_pressed() -> void:
	TimeManager.sleep_for(480)

func _on_mouse_exited() -> void:
	pass
	#if visible:
	#       hide()

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


func _on_soft_wares_button_pressed() -> void:
	WindowManager.launch_app_by_name("SoftWares")
