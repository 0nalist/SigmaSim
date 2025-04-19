extends Panel
class_name StartPanelWindow

@onready var app_list_container: VBoxContainer = %AppListContainer


func _ready() -> void:
	for app_name in WindowManager.app_registry.keys():
		var app_scene: PackedScene = WindowManager.app_registry[app_name]
		var preview = app_scene.instantiate()

		if not (preview is BaseAppUI):
			push_error("App scene must extend BaseAppUI: " + str(app_scene))
			continue


		## TODO: Create AppButton scene to replace this, allow more fine control
		var button := Button.new()
		button.text = preview.app_title
		button.icon = preview.app_icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		#button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		#button.add_theme_constant_override("icon_margin", 16)
		button.add_theme_font_size_override("font_size", 10)
		button.expand_icon = false
		button.focus_mode = Control.FOCUS_NONE
		button.theme = preload("res://assets/windows_95_theme.tres")

		# ✅ Uniform button size
		button.custom_minimum_size = Vector2(160, 40)

		# ✅ Uniform icon size (scaling via TextureRect child)
		var icon_texture := TextureRect.new()
		icon_texture.texture = preview.app_icon
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.custom_minimum_size = Vector2(24, 24)
		icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		button.icon = null  # prevent default icon layout
		button.add_child(icon_texture)
		icon_texture.position = Vector2(8, 8)  # fine-tune alignment if needed

		button.pressed.connect(func():
			launch_app(app_name)
		)

		app_list_container.add_child(button)
		preview.queue_free()



func toggle_start_panel() -> void:
	if visible:
		hide()
	else:
		#popup() #window behavior
		show()
		position = Vector2(0, 259)




func launch_app(app_name: String) -> void:
	#hide()
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
