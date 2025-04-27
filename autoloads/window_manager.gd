extends Node

var open_windows: Dictionary = {} # key: WindowFrame, value: taskbar Button
var popup_registry: Dictionary = {}

var taskbar_container: Control = null
var start_panel = null

var focused_window: WindowFrame = null

# Preloaded app scenes
var app_registry := {
	"Grinderr": preload("res://components/apps/app_scenes/grinderr.tscn"),
	"BrokeRage": preload("res://components/apps/app_scenes/broke_rage.tscn"),
	"SigmaMail": preload("res://components/apps/app_scenes/sigma_mail.tscn"),
	"WorkForce": preload("res://components/apps/app_scenes/work_force.tscn"),
	"Minerr": preload("res://components/apps/app_scenes/minerr.tscn"),
	"Settings": preload("res://components/apps/app_scenes/settings.tscn"),
	"AIM": preload("res://components/apps/app_scenes/alpha_instant_messenger.tscn"),
	"LockedIn": preload("res://components/apps/app_scenes/locked_in.tscn"),
	"OwerView": preload("res://components/apps/app_scenes/ower_view.tscn"),
	"LifeStylist": preload("res://components/apps/app_scenes/life_stylist.tscn"),
}

var popup_scene_registry := {
	"BillPopupUI": preload("res://components/popups/bill_popup_ui.tscn"),
}

func _ready() -> void:
	print("✅ Registered apps:", app_registry.keys())

# --- MAIN WINDOW FUNCTIONS --- #

func register_window(window: WindowFrame, add_taskbar_icon := true) -> void:
	if open_windows.has(window):
		window.restore()
		call_deferred("focus_window", window)
		return

	if not window.is_inside_tree():
		get_tree().root.add_child(window)

	window.show()

	var icon_button = null
	if add_taskbar_icon:
		icon_button = _create_taskbar_icon(window)
	else:
		window.get_node("%MinimizeButton").visible = false

	open_windows[window] = icon_button
	call_deferred("focus_window", window)
	print("Registering window:", window.window_title)

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
	
	if window.window_state == window.WindowState.MINIMIZED:
		window.restore()

	var root = get_tree().root
	if window.get_parent() != root:
		window.get_parent().remove_child(window)
		root.add_child(window)
	root.move_child(window, root.get_child_count() - 1)

	var btn = open_windows.get(window)
	if is_instance_valid(btn):
		btn.button_pressed = true

# --- LAUNCHING --- #

func launch_app_by_name(app_name: String) -> void:
	var scene: PackedScene = app_registry.get(app_name)
	if scene:
		launch_pane(scene)
	else:
		push_error("App not found: %s" % app_name)

func launch_pane(scene: PackedScene) -> void:
	var pane := scene.instantiate() as Pane
	if not pane:
		push_error("Scene does not extend Pane!")
		return

	if not pane.allow_multiple:
		var existing_window := find_window_by_app(pane.window_title)
		if existing_window:
			focus_window(existing_window)
			pane.queue_free()
			return

	var window := preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame
	window.load_pane(pane)

	var screen_size = get_viewport().get_visible_rect().size
	var window_size = pane.default_window_size

	var x := 0.0
	if pane.default_position == "left":
		x = -screen_size.x / 3.0
	elif pane.default_position == "right":
		x = screen_size.x / 3.0

	x -= window_size.x / 2.0
	var y = -window_size.y / 2.0

	window.position = Vector2(x, y)

	register_window(window, pane.show_in_taskbar)

# --- TASKBAR --- #

func _create_taskbar_icon(window: WindowFrame) -> Button:
	if not taskbar_container:
		return null

	var icon_button := Button.new()
	icon_button.text = window.window_title
	icon_button.icon = window.icon if window.icon else null
	icon_button.custom_minimum_size = Vector2(100, 32)
	icon_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	icon_button.clip_text = true
	icon_button.toggle_mode = true
	icon_button.focus_mode = Control.FOCUS_NONE
	icon_button.theme = get_tree().root.theme

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

# --- HELPERS --- #

func get_taskbar_icon_center(window: WindowFrame) -> Vector2:
	var btn = open_windows.get(window)
	if btn and is_instance_valid(btn):
		return btn.get_global_position() + btn.size / 2
	return window.global_position

func get_taskbar_height() -> int:
	return taskbar_container.size.y if is_instance_valid(taskbar_container) else 0

func find_window_by_app(title: String) -> WindowFrame:
	for win in open_windows.keys():
		var pane = win.pane
		if pane and pane.window_title == title:
			return win
	return null

func center_window(win: WindowFrame) -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var window_size := win.size
	if window_size == Vector2.ZERO:
		window_size = win.default_size
	win.position = (screen_size - window_size) / 2.0

# --- SPECIFIC POPUPS --- #

func open_stock_popup(stock: Stock) -> void:
	var key = "stock:" + stock.symbol
	var existing = popup_registry.get(key)
	if existing and is_instance_valid(existing):
		focus_window(existing)
		return

	var popup := preload("res://components/popups/stock_popup_ui.tscn").instantiate()
	popup.call_deferred("setup", stock)

	var window := preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame
	window.load_pane(popup)

	register_window(window, false)

	var mouse_pos := get_viewport().get_mouse_position()
	var popup_size := window.default_size
	var screen_size := get_viewport().get_visible_rect().size
	var target_pos := mouse_pos.clamp(Vector2.ZERO, screen_size - popup_size)

	window.position = target_pos

	popup_registry[key] = window
	window.tree_exited.connect(func():
		if popup_registry.get(key) == window:
			popup_registry.erase(key)
	)
	call_deferred("focus_window", window)

# --- CLOSING --- #

func close_all_windows() -> void:
	for win in open_windows.keys():
		close_window(win)

func close_all_apps() -> void:
	for win in open_windows.keys():
		if win.pane and not win.pane.is_popup:
			close_window(win)

func close_all_popups() -> void:
	for win in open_windows.keys():
		if win.pane and win.pane.is_popup:
			close_window(win)

func reset() -> void:
	open_windows.clear()
	popup_registry.clear()
	close_all_windows()
	focused_window = null

## --- Save --- ##

func get_save_data() -> Array:
	var window_data := []

	for win in open_windows.keys():
		if not win.is_inside_tree():
			continue

		var pane = win.pane
		if not pane:
			continue

		var scene_path = pane.scene_file_path if pane.has_method("get_scene_file_path") else pane.get_script().resource_path

		window_data.append({
			"scene_path": scene_path,
			"position": SaveManager.vector2_to_dict(win.position),
			"size": SaveManager.vector2_to_dict(win.size),
			"minimized": not win.visible,
			"custom_data": pane.get_custom_save_data() if pane.has_method("get_custom_save_data") else {},
		})

	return window_data


## --- Load --- ##

func load_from_data(window_data: Array) -> void:
	close_all_windows()

	for entry in window_data:
		var scene_path = entry.get("scene_path", "")
		if scene_path == "":
			continue

		var scene = load(scene_path)
		if not scene:
			push_error("Could not load scene at path: %s" % scene_path)
			continue

		var pane = scene.instantiate() as Pane
		if not pane:
			push_error("Loaded scene does not extend Pane!")
			continue

		var window = preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame
		window.load_pane(pane)

		var restored_size = SaveManager.dict_to_vector2(entry.get("size", {}), pane.default_window_size)
		var restored_position = SaveManager.dict_to_vector2(entry.get("position", {}))

		window.size = restored_size
		window.position = restored_position
		window.default_size = restored_size

		if entry.get("minimized", false):
			window.hide()

		# Restore custom pane data
		if pane.has_method("load_custom_save_data"):
			pane.load_custom_save_data(entry.get("custom_data", {}))

		register_window(window, pane.show_in_taskbar)
