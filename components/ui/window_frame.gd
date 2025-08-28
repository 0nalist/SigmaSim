extends PanelContainer
class_name WindowFrame

@export var icon: Texture
@export var default_size: Vector2 = Vector2(640, 480)
@export var minimized_size: Vector2 = Vector2(100, 40)
@export var minimized_position: Vector2 = Vector2(10, 10)
@export var animation_duration: float = 0.15

@export var window_can_close: bool = true
@export var window_can_minimize: bool = true
@export var window_can_maximize: bool = true

var _windowless_mode := false
@export var windowless_mode: bool = false:
	set(value):
		print("SETTING WINDOWLESS MODE: ", value, " for window ", self)
		_set_windowless_mode(value)
	get:
		return _windowless_mode

var window_title: String = "Window"
var pane: Pane

enum WindowState { NORMAL, MINIMIZED, MAXIMIZED }

var window_state: WindowState = WindowState.NORMAL
var previous_state: WindowState = WindowState.NORMAL
var last_position: Vector2
var last_size: Vector2
var normal_position: Vector2
var normal_size: Vector2

const MIN_VISIBLE_AREA: Vector2 = Vector2(80, 40)
const SNAP_MARGIN: int = 20
var resize_margin := 8
var is_resizing := false
var resize_dir := Vector2.ZERO
var resize_start_mouse := Vector2.ZERO
var resize_start_size := Vector2.ZERO
var resize_start_pos := Vector2.ZERO
var min_window_size := Vector2(120, 50)

var is_dragging := false
var drag_offset := Vector2.ZERO

@onready var favicon: TextureRect = %Favicon
@onready var title_label: RichTextLabel = %TitleLabel
@onready var header: HBoxContainer = %Header
@onready var header_container: PanelContainer = %HeaderContainer
@onready var upgrade_button: Button = %UpgradeButton
@onready var minimize_button: Button = %MinimizeButton
@onready var maximize_button: Button = %MaximizeButton
@onready var close_button: Button = %CloseButton
@onready var content_panel: ScrollContainer = %ContentPanel



func _ready() -> void:
	refresh_window_controls()

	upgrade_button.visible = false

	minimize_button.pressed.connect(
		func():
			if WindowManager and WindowManager.has_method("get_taskbar_icon_center"):
				var icon_center = WindowManager.get_taskbar_icon_center(self)
				minimize(icon_center)
			else:
				minimize()
	)
	PortfolioManager.cash_updated.connect(_on_relevant_stat_changed)
	#UpgradeManager.upgrade_unlocked.connect(_on_relevant_stat_changed) #not implemented yet TODO
	UpgradeManager.upgrade_purchased.connect(_on_relevant_stat_changed)


	maximize_button.pressed.connect(toggle_maximize)
	close_button.pressed.connect(_on_close_pressed)
	header.gui_input.connect(_on_header_input)
	
	call_deferred("_apply_default_window_size_and_position")
	call_deferred("_finalize_window_size")
	if windowless_mode:
		call_deferred("_setup_windowless_drag")

func _unhandled_input(event: InputEvent) -> void:
	if WindowManager == null or WindowManager.focused_window != self:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.ctrl_pressed and (key_event.keycode == KEY_W or key_event.keycode == KEY_Q):
			if window_can_close:
				_on_close_pressed()





func _finalize_window_size():
	if pane and default_size != Vector2.ZERO:
		size = default_size
		#min_size = default_size

func load_pane(new_pane: Pane) -> void:
	print("loading pane: " + str(new_pane))
	pane = new_pane
	if new_pane.window_icon:
		icon = new_pane.window_icon
	window_title = new_pane.window_title
	call_deferred("set_window_title", window_title)
	call_deferred("set_window_icon", icon)
	
	window_can_close = pane.window_can_close
	window_can_minimize = pane.window_can_minimize
	window_can_maximize = pane.window_can_maximize
	
	
	default_size = pane.default_window_size
	
	if pane.has_signal("request_resize_x_to"):
		# Clean up any previous connection first for robustness:
		if pane.request_resize_x_to.is_connected(_on_pane_resize_x_to):
			pane.request_resize_x_to.disconnect(_on_pane_resize_x_to)
		pane.request_resize_x_to.connect(_on_pane_resize_x_to)

	if pane.has_signal("request_resize_y_to"):
		if pane.request_resize_y_to.is_connected(_on_pane_resize_y_to):
			pane.request_resize_y_to.disconnect(_on_pane_resize_y_to)
		pane.request_resize_y_to.connect(_on_pane_resize_y_to)


	pane.window_title_changed.connect(_on_pane_window_title_changed)
	pane.window_icon_changed.connect(_on_window_icon_changed)
	call_deferred("_set_content", pane)

func _on_pane_resize_x_to(target_x: float, duration := 0.4):
	animate_resize_x(target_x, duration)

func _on_pane_resize_y_to(target_y: float, duration := 0.4):
	animate_resize_y(target_y, duration)

func animate_resize_x(target_x: float, duration: float = 0.4):
	var new_size = size
	new_size.x = target_x
	var tween = create_tween()
	tween.tween_property(self, "size:x", target_x, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# You might want to clamp to screen, etc. as needed

func animate_resize_y(target_y: float, duration: float = 0.4):
	var tween = create_tween()
	tween.tween_property(self, "size:y", target_y, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_content(new_content: Control) -> void:
		for child in content_panel.get_children():
				child.queue_free()
		content_panel.add_child(new_content)

		# Only expose the upgrade button when the child pane actually
		# provides an upgrade pane.  This ensures windows that do not
		# support upgrades do not show an empty or misleading button.
		if new_content is Pane and new_content.upgrade_pane:
				upgrade_button.show()
				_update_upgrade_button_state()
		else:
				upgrade_button.hide()

		if windowless_mode:
				call_deferred("_setup_windowless_drag")

func _set_windowless_mode(enabled: bool) -> void:
	_windowless_mode = enabled

	# Hide or show frame UI
	header_container.visible = not enabled
	if enabled:
		_setup_windowless_drag()
	minimize_button.visible = not enabled and window_can_minimize
	maximize_button.visible = not enabled and window_can_maximize
	close_button.visible = not enabled and window_can_close

	# Adjust content margins/padding
	#content_panel.margin_top = 0 if enabled else DEFAULT_MARGIN

func _setup_windowless_drag():
	if not pane or not pane.has_method("get_drag_handle"):
		return

	var handle = pane.get_drag_handle()
	if not is_instance_valid(handle):
		return

	# This connects to the entire tab container
	handle.mouse_default_cursor_shape = Control.CURSOR_MOVE
	handle.gui_input.connect(_on_custom_drag_input)

	# 🔁 Connect to each tab button too
	for child in handle.get_children():
		if child is BaseButton:
			child.mouse_default_cursor_shape = Control.CURSOR_MOVE
			child.gui_input.connect(_on_custom_drag_input)


func _on_custom_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if WindowManager:
			WindowManager.focus_window(self)

	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		position += event.relative
		_clamp_to_screen()


func _on_window_icon_changed(new_icon: Texture) -> void:
	set_window_icon(new_icon)

func set_window_icon(new_icon: Texture) -> void:
	
	if not favicon:
		print("no favicon")
	
	if favicon:
		if new_icon:
			var img = new_icon.get_image().duplicate()
			img.resize(32, 32, Image.INTERPOLATE_LANCZOS) # modifies img directly

			var tex = ImageTexture.new()
			tex.set_image(img)

			favicon.texture = tex
			#print("favicon texture " + str(tex))
		else:
			favicon.texture = null
			#print("favicon texture null")





func _on_pane_window_title_changed(new_title: String) -> void:
	set_window_title(new_title)

static func instantiate_for_pane(pane: Pane) -> WindowFrame:
	var window := preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame
	window.load_pane(pane)
	
	window.call_deferred("set", "windowless_mode", pane.request_windowless_mode)

	
	return window

func autoposition() -> void:
	if not pane:
		return
	var screen_size = get_viewport().get_visible_rect().size
	var window_size = pane.default_window_size
	var center = screen_size / 2
	var x = center.x
	if pane.default_position == "left":
		x -= screen_size.x / 3.0
	elif pane.default_position == "right":
		x += screen_size.x / 3.0
	x -= window_size.x / 2.0
	var y = center.y - window_size.y / 2.0
	position = Vector2(x, y)

func refresh_window_controls() -> void:
	minimize_button.visible = window_can_minimize
	maximize_button.visible = window_can_maximize
	close_button.visible = window_can_close

func _apply_default_window_size_and_position():
	if size == Vector2.ZERO or size == Vector2(1, 1):
		size = default_size
	if position == Vector2.ZERO:
		call_deferred("_clamp_to_screen")

func _clamp_to_screen() -> void:
		await get_tree().process_frame
		var screen_size = get_viewport().get_visible_rect().size

		var taskbar_height = 0
		if WindowManager and WindowManager.has_method("get_taskbar_height"):
				taskbar_height = WindowManager.get_taskbar_height()

		var min_position = Vector2(SNAP_MARGIN - size.x, SNAP_MARGIN - size.y)
		var max_position = Vector2(screen_size.x - SNAP_MARGIN, screen_size.y - taskbar_height - SNAP_MARGIN)

		position = position.clamp(min_position, max_position)


func _process(_delta: float) -> void:
	if is_resizing:
		var mouse_delta := get_global_mouse_position() - resize_start_mouse
		var new_size := resize_start_size
		var new_pos := resize_start_pos

		if resize_dir.x != 0:
			new_size.x = max(resize_start_size.x + mouse_delta.x * resize_dir.x, min_window_size.x)
			if resize_dir.x == -1:
				new_pos.x = resize_start_pos.x + mouse_delta.x
		if resize_dir.y != 0:
			new_size.y = max(resize_start_size.y + mouse_delta.y * resize_dir.y, min_window_size.y)
			if resize_dir.y == -1:
				new_pos.y = resize_start_pos.y + mouse_delta.y

		size = new_size
		global_position = new_pos
		_clamp_to_screen()
	elif is_dragging:
		# Move window to mouse minus drag offset
		position = get_global_mouse_position() - drag_offset
		_clamp_to_screen()

func _on_header_input(event: InputEvent) -> void:
	if pane == null:
		return

	var global_mouse = get_global_mouse_position()
	var window_top = global_position.y
	var resizing_on_top = false
	if pane.user_resizable:
		resizing_on_top = (global_mouse.y - window_top) <= resize_margin

	if event is InputEventMouseMotion:
		if pane.user_resizable and resizing_on_top:
			header.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		else:
			header.mouse_default_cursor_shape = Control.CURSOR_ARROW
		# Drag handled in _process

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if WindowManager and WindowManager.has_method("focus_window"):
				WindowManager.focus_window(self)
			if pane.user_resizable and resizing_on_top:
				is_resizing = true
				resize_dir = Vector2(0, -1)
				resize_start_mouse = global_mouse
				resize_start_size = size
				resize_start_pos = global_position
				is_dragging = false
			elif pane.user_movable:
				is_dragging = true
				drag_offset = global_mouse - position
				is_resizing = false
		else:
			is_resizing = false
			is_dragging = false






func _gui_input(event: InputEvent) -> void:
	if window_state == WindowState.MINIMIZED:
		return

	if event is InputEventMouseButton and event.pressed and not is_resizing:
		if WindowManager and WindowManager.has_method("focus_window"):
			WindowManager.focus_window(self)

	var local_mouse = get_local_mouse_position()
	var dir = Vector2.ZERO

	if pane and pane.user_resizable:
		if local_mouse.x >= size.x - resize_margin:
			dir.x = 1
		elif local_mouse.x <= resize_margin:
			dir.x = -1
		if local_mouse.y >= size.y - resize_margin:
			dir.y = 1
		elif local_mouse.y <= resize_margin:
			dir.y = -1

	mouse_default_cursor_shape = Control.CURSOR_ARROW
	if dir != Vector2.ZERO:
		if dir == Vector2(1, 1) or dir == Vector2(-1, -1):
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		elif dir == Vector2(-1, 1) or dir == Vector2(1, -1):
			mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		elif dir.x != 0:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		else:
			mouse_default_cursor_shape = Control.CURSOR_VSIZE

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and dir != Vector2.ZERO:
			is_resizing = true
			resize_dir = dir
			resize_start_mouse = get_global_mouse_position()
			resize_start_size = size
			resize_start_pos = global_position
		elif not event.pressed:
			is_resizing = false

func minimize(target_position: Vector2 = global_position) -> void:
	if window_state == WindowState.MINIMIZED:
		return

	if window_state == WindowState.NORMAL:
		normal_position = global_position
		normal_size = size

	last_position = global_position
	last_size = size
	previous_state = window_state
	window_state = WindowState.MINIMIZED

	var tween = create_tween()
	tween.tween_property(self, "size", minimized_size, animation_duration)
	tween.parallel().tween_property(self, "global_position", target_position - minimized_size / 2, animation_duration)
	tween.finished.connect(_on_minimize_animation_finished)

func _on_minimize_animation_finished():
	hide()

func toggle_maximize() -> void:
	if window_state == WindowState.MINIMIZED:
		show()
		window_state = previous_state

	if window_state == WindowState.MAXIMIZED:
		unmaximize()
	else:
		if window_state == WindowState.NORMAL:
			normal_position = global_position
			normal_size = size

		var viewport_size = get_viewport().get_visible_rect().size
		var taskbar_height = WindowManager.get_taskbar_height() + 14 if WindowManager and WindowManager.has_method("get_taskbar_height") else 0

		global_position = Vector2.ZERO
		size = Vector2(viewport_size.x, viewport_size.y - taskbar_height)
		window_state = WindowState.MAXIMIZED

func restore() -> void:
	if window_state != WindowState.MINIMIZED:
		return

	show()
	window_state = previous_state
	if previous_state == WindowState.NORMAL:
		global_position = normal_position
		size = normal_size
	elif previous_state == WindowState.MAXIMIZED:
		global_position = Vector2.ZERO
		size = get_viewport().get_visible_rect().size

	_clamp_to_screen()

func unmaximize() -> void:
	global_position = normal_position
	size = normal_size
	window_state = WindowState.NORMAL
	_clamp_to_screen()

func on_focus():
	modulate = Color(1, 1, 1, 1)
	if window_state == WindowState.MINIMIZED:
		restore()

func on_unfocus():
	modulate = Color(0.9, 0.9, 0.9, 1)

func _on_close_pressed() -> void:
	if WindowManager.has_method("close_window"):
		WindowManager.close_window(self)
	else:
		queue_free()

func _on_relevant_stat_changed(_a = null, _b = null):
	_update_upgrade_button_state()


func _update_upgrade_button_state() -> void:
	if not pane or not pane.upgrade_pane:
		upgrade_button.hide()
		return

	var upgrades = UpgradeManager.get_upgrades_for_system(pane.window_title)

	var any_available := false
	for upgrade in upgrades:
		var id = upgrade.get("id")
		if not UpgradeManager.is_locked(id) and UpgradeManager.can_purchase(id):
			any_available = true
			break

	upgrade_button.visible = true
	upgrade_button.flat = not any_available



func set_window_title(title: String) -> void:
	if title_label:
		title_label.bbcode_enabled = true
		title_label.parse_bbcode(title)


func _on_upgrade_button_pressed() -> void:
	if not pane or not pane.upgrade_pane:
		return

	var popup_key := pane.window_title + "::upgrade"

	var existing := WindowManager.find_popup_by_key(popup_key)
	if existing:
		WindowManager.focus_window(existing)
		return

	WindowManager.launch_popup(pane.upgrade_pane, popup_key)
