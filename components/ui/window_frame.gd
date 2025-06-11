extends Panel
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
@export var windowless_mode: bool:
	set(value):
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
var resize_margin := 8
var is_resizing := false
var resize_dir := Vector2.ZERO
var resize_start_mouse := Vector2.ZERO
var resize_start_size := Vector2.ZERO
var resize_start_pos := Vector2.ZERO
var min_window_size := Vector2(120, 50)

@onready var favicon: TextureRect = %Favicon
@onready var title_label: Label = %TitleLabel
@onready var header: HBoxContainer = %Header
@onready var upgrade_button: Button = %UpgradeButton
@onready var minimize_button: Button = %MinimizeButton
@onready var maximize_button: Button = %MaximizeButton
@onready var close_button: Button = %CloseButton
@onready var content_panel: ScrollContainer = %ContentPanel



func _ready() -> void:
	refresh_window_controls()

	upgrade_button.visible = false

	minimize_button.pressed.connect(func():
		if WindowManager and WindowManager.has_method("get_taskbar_icon_center"):
			var icon_center = WindowManager.get_taskbar_icon_center(self)
			minimize(icon_center)
		else:
			minimize()
	)
	PortfolioManager.cash_updated.connect(_on_relevant_stat_changed)
	UpgradeManager.upgrade_unlocked.connect(_on_relevant_stat_changed)
	UpgradeManager.upgrade_purchased.connect(_on_relevant_stat_changed)


	maximize_button.pressed.connect(toggle_maximize)
	close_button.pressed.connect(_on_close_pressed)
	header.gui_input.connect(_on_header_input)

	call_deferred("_apply_default_window_size_and_position")

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
	pane.window_title_changed.connect(_on_pane_window_title_changed)
	pane.window_icon_changed.connect(_on_window_icon_changed)
	call_deferred("_set_content", pane)

func _set_content(new_content: Control) -> void:
	for child in content_panel.get_children():
		child.queue_free()
	content_panel.add_child(new_content)
	_update_upgrade_button_state()

func _set_windowless_mode(enabled: bool) -> void:
	_windowless_mode = enabled

	# Hide or show frame UI
	header.visible = not enabled
	minimize_button.visible = not enabled and window_can_minimize
	maximize_button.visible = not enabled and window_can_maximize
	#close_button.visible = not enabled and window_can_close

	# Adjust content margins/padding
	#content_panel.margin_top = 0 if enabled else DEFAULT_MARGIN


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

	var max_position = Vector2(screen_size.x - size.x, screen_size.y - size.y - taskbar_height)

	position = position.clamp(Vector2.ZERO, max_position)


func _process(_delta: float) -> void:
	if not is_resizing:
		return

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

func _on_header_input(event: InputEvent) -> void:
	if is_resizing:
		return

	if pane == null:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if WindowManager and WindowManager.has_method("focus_window"):
			WindowManager.focus_window(self)

	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if pane.user_movable: # 👈 ADD THIS CHECK
			position += event.relative
			_clamp_to_screen()

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

func _on_relevant_stat_changed(_x = null):
	_update_upgrade_button_state()


func _update_upgrade_button_state() -> void:
	if not pane or not pane.upgrade_pane:
		upgrade_button.visible = false
		return

	var upgrades = UpgradeManager.get_upgrades_by_source(pane.window_title)
	
	var any_available := false
	for upgrade in upgrades:
		if UpgradeManager.is_unlocked(upgrade.upgrade_id) and not UpgradeManager.is_purchased(upgrade.upgrade_id):
			var cost = upgrade.get_current_cost()
			if PortfolioManager.cash >= cost:
				any_available = true
				break

	upgrade_button.visible = true
	upgrade_button.flat = not any_available



func set_window_title(title: String) -> void:
	if title_label:
		title_label.text = title


func _on_upgrade_button_pressed() -> void:
	if not pane or not pane.upgrade_pane:
		return

	var popup_key := pane.window_title + "::upgrade"

	var existing := WindowManager.find_popup_by_key(popup_key)
	if existing:
		WindowManager.focus_window(existing)
		return

	WindowManager.launch_popup(pane.upgrade_pane, popup_key)
