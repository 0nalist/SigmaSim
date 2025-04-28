extends Node

var open_windows: Dictionary = {} # key: WindowFrame, value: taskbar Button
var popup_registry: Dictionary = {}

var taskbar_container: Control = null
var start_panel = null

var focused_window: WindowFrame = null

# Preloaded apps
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

var start_apps := {
	"Grinderr": preload("res://components/apps/app_scenes/grinderr.tscn"),
	"BrokeRage": preload("res://components/apps/app_scenes/broke_rage.tscn"),
	"SigmaMail": preload("res://components/apps/app_scenes/sigma_mail.tscn"),
	"WorkForce": preload("res://components/apps/app_scenes/work_force.tscn"),
	"Minerr": preload("res://components/apps/app_scenes/minerr.tscn"),
	"AIM": preload("res://components/apps/app_scenes/alpha_instant_messenger.tscn"),
	"LockedIn": preload("res://components/apps/app_scenes/locked_in.tscn"),
	"OwerView": preload("res://components/apps/app_scenes/ower_view.tscn"),
	"LifeStylist": preload("res://components/apps/app_scenes/life_stylist.tscn"),
}


func _ready() -> void:
	print("✅ Registered apps:", app_registry.keys())

# --- Main window functions --- #

func register_window(window: WindowFrame, add_taskbar_icon := true) -> void:
	if open_windows.has(window):
		window.restore()
		call_deferred("focus_window", window)
		return

	get_tree().root.add_child(window)
	window.show()

	var icon_button = null
	if add_taskbar_icon:
		icon_button = _create_taskbar_icon(window)
	else:
		window.get_node("%MinimizeButton").visible = false

	open_windows[window] = icon_button
	call_deferred("focus_window", window)

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

	bring_to_top(window)

	# ✨ SMART: Only reassert stay_on_top windows if necessary
	var focused_index = root.get_children().find(window)

	for win in open_windows.keys():
		if win != window and win.pane and win.pane.stay_on_top:
			var win_index = root.get_children().find(win)
			if win_index < focused_index:
				bring_to_top(win)

	var btn = open_windows.get(window)
	if is_instance_valid(btn):
		btn.button_pressed = true




func bring_to_top(window: WindowFrame) -> void:
	var root = get_tree().root
	if not is_instance_valid(window) or window.get_parent() != root:
		return

	if window.pane and window.pane.stay_on_top:
		# If stay_on_top, move to very top
		root.move_child(window, root.get_child_count() - 1)
	else:
		# Find the highest non-stay_on_top window
		var children = root.get_children()
		var insert_index = 0  # Default to very bottom

		for i in range(root.get_child_count() - 1, -1, -1):
			var child = children[i]
			if child is WindowFrame and child.pane and not child.pane.stay_on_top:
				insert_index = i + 1
				break

		root.move_child(window, insert_index)




func close_window(window: WindowFrame) -> void:
	if open_windows.has(window):
		var icon = open_windows[window]
		if is_instance_valid(icon):
			icon.queue_free()
		open_windows.erase(window)

	if focused_window == window:
		focused_window = null

	window.queue_free()




# --- Launchers --- #

func launch_app_by_name(app_name: String) -> void:
	var scene: PackedScene = app_registry.get(app_name)
	if scene:
		launch_pane(scene)
	else:
		push_error("App not found: %s" % app_name)

func launch_pane(scene: PackedScene) -> void:
	print("launch pane scene: " + str(scene))
	var pane := scene.instantiate() as Pane
	if not pane:
		push_error("Scene does not extend Pane!")
		return

	if not pane.allow_multiple:
		var existing = find_window_by_app(pane.window_title)
		if existing:
			focus_window(existing)
			pane.queue_free()
			return

	var window := WindowFrame.instantiate_for_pane(pane)
	register_window(window, pane.show_in_taskbar)
	call_deferred("autoposition_window", window)
	
	register_window(window, pane.show_in_taskbar)


func launch_pane_instance(pane: Pane, setup_args: Variant = null) -> void:
	print("launch pane instance : " + str(pane))
	var window := WindowFrame.instantiate_for_pane(pane)
	register_window(window, pane.show_in_taskbar)
	
	if setup_args != null and pane.has_method("setup_custom"):
		pane.call_deferred("setup_custom", setup_args)

	call_deferred("autoposition_window", window)


func launch_popup(popup_scene: PackedScene, unique_key: String, setup_args: Variant = null) -> void:
	if popup_scene == null:
		push_error("launch_popup called with null scene")
		return

	# Check if popup already exists
	var existing_window = find_popup_by_key(unique_key)
	if existing_window:
		focus_window(existing_window)
		return

	# Otherwise, create new popup
	var popup_pane = popup_scene.instantiate() as Pane
	popup_pane.unique_popup_key = unique_key

	var window = WindowFrame.instantiate_for_pane(popup_pane)
	register_window(window, popup_pane.show_in_taskbar)

	if setup_args != null and popup_pane.has_method("setup"):
		popup_pane.call_deferred("setup", setup_args)

	call_deferred("autoposition_window", window)




func autoposition_window(window: WindowFrame) -> void:
	if is_instance_valid(window):
		window.autoposition()


# --- Taskbar --- #

func _create_taskbar_icon(window: WindowFrame) -> Button:
	if not taskbar_container:
		return null

	var icon_button = Button.new()
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

# --- Helpers --- #

func get_taskbar_icon_center(window: WindowFrame) -> Vector2:
	var btn = open_windows.get(window)
	if btn and is_instance_valid(btn):
		return btn.get_global_position() + btn.size / 2
	return window.global_position

func get_taskbar_height() -> int:
	return taskbar_container.size.y if is_instance_valid(taskbar_container) else 0

func find_window_by_app(title: String) -> WindowFrame:
	for win in open_windows.keys():
		if win.pane and win.pane.window_title == title:
			return win
	return null

func find_popup_by_key(key: String) -> WindowFrame:
	for win in open_windows.keys():
		if win.pane and win.pane.unique_popup_key == key:
			return win
	return null



func center_window(win: WindowFrame) -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var window_size = win.size
	if window_size == Vector2.ZERO:
		window_size = win.default_size
	win.position = (screen_size - window_size) / 2.0

# --- Closing --- #

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
	close_all_windows()
	open_windows.clear()
	popup_registry.clear()
	focused_window = null

# --- Save / Load --- #

# --- Save / Load ---
func get_save_data() -> Array:
	var window_data = []
	for win in open_windows.keys():
		var pane = win.pane
		if not pane or pane.is_popup:
			continue  # Bill popups handled by BillManager separately

		var scene_path = pane.scene_file_path if pane.has_method("get_scene_file_path") else pane.get_script().resource_path

		window_data.append({
			"scene_path": scene_path,
			"position": SaveManager.vector2_to_dict(win.position),
			"size": SaveManager.vector2_to_dict(win.size),
			"minimized": not win.visible,
			"custom_data": pane.get_custom_save_data() if pane.has_method("get_custom_save_data") else {},
		})
	return window_data

func load_from_data(window_data: Array) -> void:
	reset()

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

		register_window(window, pane.show_in_taskbar)

		var restored_size = SaveManager.dict_to_vector2(entry.get("size", {}), pane.default_window_size)
		var restored_position = SaveManager.dict_to_vector2(entry.get("position", {}))

		# IMPORTANT: Set position and size AFTER registering
		window.set_deferred("size", restored_size)
		window.set_deferred("position", restored_position)
		window.default_size = restored_size

		if entry.get("minimized", false):
			window.hide()

		if pane.has_method("load_custom_save_data"):
			pane.load_custom_save_data(entry.get("custom_data", {}))
