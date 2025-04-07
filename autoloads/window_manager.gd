extends Node

var open_windows: Dictionary = {} # key: window unique ID or name
var taskbar_container: Node = null # set this from UI
var start_panel: Node = null # set this from main scene or via singleton

func register_window(window: Window, id: String) -> void:
	# Avoid duplicate windows
	if open_windows.has(id):
		open_windows[id].raise()
		open_windows[id].grab_focus()
		return

	# Show the window
	if not window.is_inside_tree():
		get_tree().get_root().add_child(window)

	window.show()
	window.grab_focus()

	open_windows[id] = window
	_create_taskbar_icon(id, window)

	# Close StartPanel if needed
	if start_panel and start_panel.visible:
		start_panel.hide()


func close_window(id: String) -> void:
	if open_windows.has(id):
		open_windows[id].hide()
		_remove_taskbar_icon(id)
		open_windows.erase(id)


func _create_taskbar_icon(id: String, window: Window) -> void:
	if not taskbar_container: return

	var icon_button = Button.new()
	icon_button.text = id
	icon_button.toggle_mode = true
	icon_button.pressed.connect(func():
		if window.visible:
			window.hide()
		else:
			window.show()
			window.grab_focus()
	)
	taskbar_container.add_child(icon_button)
	window.visibility_changed.connect(func():
		icon_button.button_pressed = window.visible
	)
	window.tree_exited.connect(func():
		close_window(id)
	)


func _remove_taskbar_icon(id: String) -> void:
	for child in taskbar_container.get_children():
		if child is Button and child.text == id:
			child.queue_free()
