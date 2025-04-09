extends Node

var open_windows: Dictionary = {} # key: WindowFrame, value: taskbar Button
var taskbar_container: Control = null
var start_panel: Window = null

var focused_window: WindowFrame = null

func register_window(window: WindowFrame) -> void:
	if not window:
		push_error("Cannot register null window.")
		return

	if open_windows.has(window):
		window.restore()
		focus_window(window)
		return

	if not window.is_inside_tree():
		get_tree().root.add_child(window)

	window.show()

	var icon_button := _create_taskbar_icon(window)
	open_windows[window] = icon_button

	# Focus the new window
	focus_window(window)

	if start_panel and start_panel.visible:
		start_panel.hide()

func close_window(window: WindowFrame) -> void:
	if open_windows.has(window):
		var icon = open_windows[window]
		if is_instance_valid(icon):
			icon.queue_free()
		open_windows.erase(window)

		if focused_window == window:
			focused_window = null

		window.queue_free()

func focus_window(window: WindowFrame) -> void:
	if focused_window == window:
		return

	# Unfocus previous window
	if is_instance_valid(focused_window):
		focused_window.on_unfocus()
		var prev_btn = open_windows.get(focused_window)
		if is_instance_valid(prev_btn):
			prev_btn.button_pressed = false

	# Focus new one
	focused_window = window
	window.on_focus()
	get_tree().root.move_child(window, get_tree().root.get_child_count() - 1)
	window.grab_focus()

	# Update taskbar button
	var btn = open_windows.get(window)
	if is_instance_valid(btn):
		btn.button_pressed = true

func _create_taskbar_icon(window: WindowFrame) -> Button:
	if not taskbar_container:
		return null

	var icon_button := Button.new()
	icon_button.text = window.window_title
	icon_button.icon = window.icon if window.icon else null
	icon_button.add_theme_constant_override("icon_max_width", 32)
	icon_button.toggle_mode = true
	icon_button.focus_mode = Control.FOCUS_NONE

	icon_button.pressed.connect(func():
		if window.visible:
			focus_window(window)
		else:
			window.show()
			focus_window(window)
	)

	window.visibility_changed.connect(func():
		icon_button.button_pressed = window.visible and focused_window == window
	)

	window.tree_exited.connect(func():
		close_window(window)
	)

	taskbar_container.add_child(icon_button)
	return icon_button

func find_window_by_app(app_class_name: String) -> WindowFrame:
	for win in open_windows.keys():
		var content = win.get_node("VBoxContainer/ContentPanel").get_child(0)
		if content and content.get_class() == app_class_name:
			return win
	return null
