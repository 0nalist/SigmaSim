extends Node

var open_windows: Dictionary = {} # key: WindowFrame, value: taskbar Button
var taskbar_container: Control = null
var start_panel: Window = null

var focused_window: WindowFrame = null

# Preloaded app scenes, manually assigned
var app_registry := {
	"Minerr": preload("res://components/apps/app_scenes/minerr.tscn"),
	"Grinderr": preload("res://components/apps/app_scenes/grinderr.tscn"),
	"BrokeRage": preload("res://components/apps/app_scenes/broke_rage.tscn"),
	"SigmaMail": preload("res://components/apps/app_scenes/sigma_mail.tscn"),
	"Settings": preload("res://components/apps/app_scenes/settings.tscn"),
	"AIM": preload("res://components/apps/app_scenes/alpha_instant_messenger.tscn"),
	"LockedIn": preload("res://components/apps/app_scenes/locked_in.tscn")
}


func _ready() -> void:
	print("✅ Registered apps:", app_registry.keys())


func register_window(window: WindowFrame) -> void:
	if open_windows.has(window):
		window.restore()
		focus_window(window)
		return

	if not window.is_inside_tree():
		get_tree().root.add_child(window)

	window.show()
	var icon_button := _create_taskbar_icon(window)
	open_windows[window] = icon_button
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

	if is_instance_valid(focused_window):
		focused_window.on_unfocus()
		var prev_btn = open_windows.get(focused_window)
		if is_instance_valid(prev_btn):
			prev_btn.button_pressed = false

	focused_window = window
	window.on_focus()
	get_tree().root.move_child(window, get_tree().root.get_child_count() - 1)
	window.grab_focus()

	var btn = open_windows.get(window)
	if is_instance_valid(btn):
		btn.button_pressed = true


func launch_app_by_name(app_name: String) -> void:
	var scene: PackedScene = app_registry.get(app_name)
	if scene == null:
		push_error("App not found in registry: '%s'" % app_name)
		return

	# Instantiate a temporary preview to check metadata (like only_one_instance_allowed)
	var preview := scene.instantiate()
	if not (preview is BaseAppUI):
		push_error("App '%s' does not extend BaseAppUI" % app_name)
		return

	# ✅ If only one instance is allowed, check for an existing window
	if preview.only_one_instance_allowed:
		var existing_window := find_window_by_app(app_name)
		if existing_window:
			focus_window(existing_window)
			preview.queue_free()
			return

	preview.queue_free()

	# --- Instantiate actual app ---
	var instance = scene.instantiate()
	var win = preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame

	win.icon = instance.app_icon
	win.window_title = instance.app_title
	win.call_deferred("set_window_title", instance.app_title)
	win.default_size = instance.default_window_size
	win.get_node("%ContentPanel").add_child(instance)

	# ✅ Position logic (center-relative)
	var screen_size := get_viewport().get_visible_rect().size
	var window_size = instance.default_window_size

	var x := 0.0
	match instance.default_position:
		"left":   x = -screen_size.x / 3.0
		"right":  x =  screen_size.x / 3.0
		"center", _: x = 0.0

	x -= window_size.x / 2.0
	var y = -window_size.y / 2.0

	win.position = Vector2(x, y)

	register_window(win)






func _create_taskbar_icon(window: WindowFrame) -> Button:
	if not taskbar_container:
		return null

	var icon_button := Button.new()
	icon_button.text = window.window_title
	icon_button.icon = window.icon if window.icon else null
	icon_button.add_theme_constant_override("icon_max_width", 32)
	icon_button.add_theme_font_size_override("font_size", 12)
	icon_button.custom_minimum_size = Vector2(100, 32)
	icon_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	icon_button.clip_text = true
	icon_button.toggle_mode = true
	icon_button.focus_mode = Control.FOCUS_NONE

	icon_button.pressed.connect(func():
		if window.visible and focused_window == window:
			var center = icon_button.get_global_position() + icon_button.size / 2
			window.minimize(center)
			icon_button.button_pressed = false
			focused_window = null
		else:
			window.restore()
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


# --- Helpers ---

func get_taskbar_icon_center(window: WindowFrame) -> Vector2:
	var btn = open_windows.get(window)
	if btn and is_instance_valid(btn):
		return btn.get_global_position() + btn.size / 2
	return window.global_position


func get_taskbar_height() -> int:
	return taskbar_container.size.y if is_instance_valid(taskbar_container) else 0


func find_window_by_app(title: String) -> WindowFrame:
	for win in open_windows.keys():
		var content = win.get_node("VBoxContainer/ContentPanel").get_child(0)
		if content != null and "app_title" in content and content.app_title == title:
			return win
	return null
