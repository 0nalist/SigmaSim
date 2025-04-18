extends Panel
class_name WindowFrame

@export var icon: Texture
@export var default_size: Vector2 = Vector2(640, 480)
@export var minimized_size: Vector2 = Vector2(200, 40)
@export var minimized_position: Vector2 = Vector2(10, 10)
@export var animation_duration: float = 0.1

@export var window_can_close: bool = true
@export var window_can_minimize: bool = true
@export var window_can_maximize: bool = true

var window_title: String = "Window"

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
@onready var header: HBoxContainer = $VBoxContainer/MarginContainer/Header
@onready var minimize_button: Button = $VBoxContainer/MarginContainer/Header/MinimizeButton
@onready var maximize_button: Button = $VBoxContainer/MarginContainer/Header/MaximizeButton
@onready var close_button: Button = $VBoxContainer/MarginContainer/Header/CloseButton
@onready var content_panel: ScrollContainer = %ContentPanel


func _ready() -> void:
	refresh_window_controls()
	
	minimize_button.pressed.connect(func():
		if WindowManager and WindowManager.has_method("get_taskbar_icon_center"):
			var icon_center := WindowManager.get_taskbar_icon_center(self)
			minimize(icon_center)
		else:
			minimize()
	)

	maximize_button.pressed.connect(toggle_maximize)
	close_button.pressed.connect(_on_close_pressed)
	header.gui_input.connect(_on_header_input)

	if icon:
		favicon.texture = icon
		favicon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		favicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		favicon.custom_minimum_size = Vector2(16, 16)

	call_deferred("_apply_default_window_size_and_position")

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
	var window_size = size
	position = position.clamp(Vector2.ZERO, screen_size - window_size)


func _process(_delta: float) -> void:
	if not is_resizing:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_delta := get_global_mouse_position() - resize_start_mouse
	var new_size := resize_start_size
	var new_pos := resize_start_pos

	if resize_dir.x != 0:
		var new_width = resize_start_size.x + mouse_delta.x * resize_dir.x
		new_size.x = max(new_width, min_window_size.x)

	if resize_dir.x == -1:
		new_pos.x = resize_start_pos.x + mouse_delta.x
		if new_size.x <= min_window_size.x:
			new_pos.x = resize_start_pos.x + (resize_start_size.x - min_window_size.x)

	if resize_dir.y != 0:
		var new_height = resize_start_size.y + mouse_delta.y * resize_dir.y
		new_size.y = max(new_height, min_window_size.y)

	if resize_dir.y == -1:
		new_pos.y = resize_start_pos.y + mouse_delta.y
		if new_size.y <= min_window_size.y:
			new_pos.y = resize_start_pos.y + (resize_start_size.y - min_window_size.y)

	# Clamp resizing so that no edge can go off-screen
	if new_pos.x < 0:
		var overshoot_x = -new_pos.x
		new_pos.x = 0
		new_size.x = max(min_window_size.x, new_size.x - overshoot_x)

	if new_pos.y < 0:
		var overshoot_y = -new_pos.y
		new_pos.y = 0
		new_size.y = max(min_window_size.y, new_size.y - overshoot_y)

	if new_pos.x + new_size.x > viewport_size.x:
		new_size.x = max(min_window_size.x, viewport_size.x - new_pos.x)

	if new_pos.y + new_size.y > viewport_size.y:
		new_size.y = max(min_window_size.y, viewport_size.y - new_pos.y)

	size = new_size
	global_position = new_pos


func _on_header_input(event: InputEvent) -> void:
	if is_resizing:
		return

	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		position += event.relative
		_clamp_to_viewport()


func _clamp_to_viewport() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var min_x = viewport_size.x - MIN_VISIBLE_AREA.x
	var min_y = viewport_size.y - MIN_VISIBLE_AREA.y

	if position.x + size.x < MIN_VISIBLE_AREA.x:
		position.x = MIN_VISIBLE_AREA.x - size.x
	if position.x > min_x:
		position.x = min_x
	if position.y + size.y < MIN_VISIBLE_AREA.y:
		position.y = MIN_VISIBLE_AREA.y - size.y
	if position.y > min_y:
		position.y = min_y


func _gui_input(event: InputEvent) -> void:
	#if window_state != WindowState.NORMAL:
	if window_state == WindowState.MINIMIZED:
		return

	if event is InputEventMouseButton and event.pressed:
		if WindowManager.has_method("focus_window"):
			WindowManager.focus_window(self)

	var local_mouse := get_local_mouse_position()
	var w := size.x
	var h := size.y
	var dir := Vector2.ZERO

	if local_mouse.x >= w - resize_margin:
		dir.x = 1
	elif local_mouse.x <= resize_margin:
		dir.x = -1
	if local_mouse.y >= h - resize_margin:
		dir.y = 1
	elif local_mouse.y <= resize_margin:
		dir.y = -1

	if dir != Vector2.ZERO:
		if dir == Vector2(1, 1) or dir == Vector2(-1, -1):
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		elif dir == Vector2(-1, 1) or dir == Vector2(1, -1):
			mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		elif dir.x != 0:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		else:
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW

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
		var taskbar_height = 0

		if WindowManager and WindowManager.has_method("get_taskbar_height"):
			taskbar_height = WindowManager.get_taskbar_height() + 14

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
		position = Vector2.ZERO
		size = get_viewport().get_visible_rect().size
		window_state = WindowState.MAXIMIZED

	_clamp_to_viewport()


func unmaximize() -> void:
	global_position = normal_position
	size = normal_size
	window_state = WindowState.NORMAL
	_clamp_to_viewport()


func on_focus():
	modulate = Color(1, 1, 1, 1)


func on_unfocus():
	modulate = Color(0.9, 0.9, 0.9, 1)


func _on_close_pressed() -> void:
	if WindowManager.has_method("close_window"):
		WindowManager.close_window(self)
	else:
		queue_free()


func set_window_title(title: String) -> void:
	window_title = title
	if title_label:
		title_label.text = title
