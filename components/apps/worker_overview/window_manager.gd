extends Node

var open_windows: Dictionary = {} # key: WindowFrame, value: taskbar Button
var popup_registry: Dictionary = {}

var taskbar_container: Control = null
var start_panel = null

var focused_window: WindowFrame = null

# Preloaded app scenes, manually assigned
var app_registry := {
	"Minerr": preload("res://components/apps/app_scenes/minerr.tscn"),
	"Grinderr": preload("res://components/apps/app_scenes/grinderr.tscn"),
	"BrokeRage": preload("res://components/apps/app_scenes/broke_rage.tscn"),
	"SigmaMail": preload("res://components/apps/app_scenes/sigma_mail.tscn"),
	"Settings": preload("res://components/apps/app_scenes/settings.tscn"),
	"AIM": preload("res://components/apps/app_scenes/alpha_instant_messenger.tscn"),
	"LockedIn": preload("res://components/apps/app_scenes/locked_in.tscn"),
	"WorkForce": preload("res://components/apps/app_scenes/work_force.tscn"),
}

var popup_scene_registry := {
	"BillPopupUI": preload("res://components/popups/bill_popup_ui.tscn")
}


func _ready() -> void:
	print("✅ Registered apps:", app_registry.keys())


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
	print("📌 Registering window:", window.window_title)
	print("🪟 open_windows now:", open_windows.keys())



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

	# 🛠️ Re-add to root and move to front
	var root = get_tree().root
	if window.get_parent() != root:
		window.get_parent().remove_child(window)
		root.add_child(window)
	root.move_child(window, root.get_child_count() - 1)

	#window.grab_focus()

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

	# If only one instance is allowed, check for an existing window
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
	win.window_can_close = instance.window_can_close
	win.window_can_minimize = instance.window_can_minimize
	win.window_can_maximize = instance.window_can_maximize
	
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

func center_window(win: WindowFrame) -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var window_size := win.size
	if window_size == Vector2.ZERO:
		window_size = win.default_size
	win.position = (screen_size - window_size) / 2.0



## Specific subwindow launchers

func open_stock_popup(stock: Stock) -> void:
	var key = "stock:" + stock.symbol
	var existing = popup_registry.get(key)
	if existing and is_instance_valid(existing):
		focus_window(existing)
		print("focusing popup window: " + str(existing))
		return

	var popup := preload("res://components/popups/stock_popup_ui.tscn").instantiate()
	popup.call_deferred("setup", stock)

	var win := preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame
	win.window_title = "Stock: %s" % stock.symbol
	win.call_deferred("set_window_title", "Stock: $" + stock.symbol)
	win.icon = null
	win.default_size = popup.default_window_size
	win.get_node("%ContentPanel").add_child(popup)

	register_window(win, false)
	win.get_node("%MinimizeButton").visible = false
	
	var mouse_pos := get_viewport().get_mouse_position()
	var popup_size := win.default_size
	var screen_size := get_viewport().get_visible_rect().size
	var target_pos := mouse_pos.clamp(Vector2.ZERO, screen_size - popup_size)

	win.position = target_pos

	popup_registry[key] = win
	win.tree_exited.connect(func():
		if popup_registry.get(key) == win:
			popup_registry.erase(key)
	)
	call_deferred("focus_window", win)

func close_all_windows() -> void:
	var windows_to_close := open_windows.keys()
	for win in windows_to_close:
		close_window(win)

func launch_popup(popup: Control, window_title: String = "Popup", size: Vector2 = Vector2(400, 500)) -> void:
	var win := preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame

	win.window_title = window_title
	win.call_deferred("set_window_title", window_title)
	win.default_size = size
	win.window_can_minimize = false  # Optional
	win.window_can_maximize = false  # Optional
	win.get_node("%ContentPanel").add_child(popup)

	register_window(win, false)  # false = no taskbar icon

	center_window(win)



## -- Save/Load

func get_save_data() -> Array:
	var window_data := []

	for win in open_windows.keys():
		var app = win.get_node("VBoxContainer/ContentPanel").get_child(0)
		if app == null:
			continue

		# Identify the app by matching scene path
		var scene_path = app.scene_file_path if app.has_method("get_scene_file_path") else app.get_script().resource_path

		# Find registry key from scene path
		var app_name := ""
		for key in app_registry:
			if app_registry[key].resource_path == scene_path:
				app_name = key
				break

		if app_name == "":
			continue  # skip unknown apps

		window_data.append({
			"app_name": app_name,
			"position": SaveManager.vector2_to_dict(win.position),
			"size": SaveManager.vector2_to_dict(win.size),
			"minimized": not win.visible,
			"icon_path": win.icon.resource_path if win.icon else "",
		})

	return window_data


func load_from_data(window_data: Array) -> void:
	close_all_windows()

	for entry in window_data:
		var app_name = entry.get("app_name", "")
		if not app_registry.has(app_name):
			continue

		var scene = app_registry[app_name]
		var instance = scene.instantiate()
		var win := preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame

		print("🔁 Restoring app:", app_name)

		var restored_size = SaveManager.dict_to_vector2(entry.get("size", {}), instance.default_window_size)
		var restored_position = SaveManager.dict_to_vector2(entry.get("position", {}))

		get_tree().root.add_child(win)

		win.size = restored_size
		win.position = restored_position
		win.default_size = restored_size
		var icon_path = entry.get("icon_path", "")
		if icon_path != "":
			var icon = load(icon_path)
			if icon:
				win.icon = icon
				print("set icon")
		else:
			win.icon = instance.app_icon
			print("set app icon")
		win.window_title = instance.app_title
		win.call_deferred("set_window_title", instance.app_title)
		win.window_can_close = instance.window_can_close
		win.window_can_minimize = instance.window_can_minimize
		win.window_can_maximize = instance.window_can_maximize

		win.get_node("%ContentPanel").add_child(instance)

		register_window(win)

		if entry.get("minimized", false):
			win.hide()

func get_popup_save_data() -> Array:
	var popup_data := []

	for win in open_windows.keys():
		var content = win.get_node("VBoxContainer/ContentPanel").get_child(0)
		if content is BasePopupUI and content.has_method("get_custom_save_data"):
			var popup_type = content.popup_type
			print("📦 Saving popup type:", popup_type)

			popup_data.append({
				"type": popup_type,
				"position": SaveManager.vector2_to_dict(win.position),
				"size": SaveManager.vector2_to_dict(win.size),
				"can_close": win.window_can_close,
				"can_minimize": win.window_can_minimize,
				"can_maximize": win.window_can_maximize,
				"icon_path": win.icon.resource_path if win.icon else "",
				"custom_data": content.get_custom_save_data(),
			})
	return popup_data

func load_popups_from_data(popup_data: Array) -> void:
	for entry in popup_data:
		var type = entry.get("type", "")
		if not popup_scene_registry.has(type):
			print("❌ Unknown popup type:", type)
			continue

		var scene = popup_scene_registry[type]
		var popup = scene.instantiate()

		var win := preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame
		win.get_node("%ContentPanel").add_child(popup)

		# Add to tree before assigning position/size
		get_tree().root.add_child(win)

		var restored_size = SaveManager.dict_to_vector2(entry.get("size", {}), popup.default_window_size)
		var restored_position = SaveManager.dict_to_vector2(entry.get("position", {}))
		win.size = restored_size
		win.position = restored_position
		win.default_size = restored_size

		# ✅ Restore window properties
		win.window_can_close = entry.get("can_close", win.window_can_close)
		win.window_can_minimize = entry.get("can_minimize", win.window_can_minimize)
		win.window_can_maximize = entry.get("can_maximize", win.window_can_maximize)
		var icon_path = entry.get("icon_path", "")
		if icon_path != "":
			var icon = load(icon_path)
			if icon:
				win.icon = icon
		register_window(win, false)

		if popup.has_method("load_custom_save_data"):
			popup.load_custom_save_data(entry.get("custom_data", {}))

		if popup.has_method("get_window_title"):
			win.call_deferred("set_window_title", popup.get_window_title())
		else:
			win.window_title = "Popup"
