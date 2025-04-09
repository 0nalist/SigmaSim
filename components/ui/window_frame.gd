extends Panel
class_name WindowFrame

@export var icon: Texture # Optional, for taskbar or title bar
@export var default_size: Vector2 = Vector2(640, 480)

@export var minimized_size: Vector2 = Vector2(200, 40)
@export var minimized_position: Vector2 = Vector2(10, 10)
@export var animation_duration: float = 0.1

var window_title: String = "Window"

enum WindowState { NORMAL, MINIMIZED, MAXIMIZED }

var window_state: WindowState = WindowState.NORMAL
var previous_state: WindowState = WindowState.NORMAL
var last_position: Vector2
var last_size: Vector2

const MIN_VISIBLE_AREA: Vector2 = Vector2(80, 40) # Allow the top-left 80x40 to stay onscreen

var resize_margin := 8
var is_resizing := false
var resize_dir := Vector2.ZERO
var resize_start_mouse := Vector2.ZERO
var resize_start_size := Vector2.ZERO
var resize_start_pos := Vector2.ZERO
var min_window_size := Vector2(50, 10)



## ---------------------------- ##
##         UI Elements         ##
## ---------------------------- ##

@onready var favicon: TextureRect = %Favicon
@onready var title_label: Label = %TitleLabel
@onready var header: HBoxContainer = $VBoxContainer/MarginContainer/Header
@onready var minimize_button: Button = $VBoxContainer/MarginContainer/Header/MinimizeButton
@onready var maximize_button: Button = $VBoxContainer/MarginContainer/Header/MaximizeButton
@onready var close_button: Button = $VBoxContainer/MarginContainer/Header/CloseButton
@onready var content_panel: ScrollContainer = %ContentPanel

## ---------------------------- ##
##         Initialization      ##
## ---------------------------- ##

func _ready() -> void:
	
	# UI Setup
	minimize_button.pressed.connect(func():
		if WindowManager and WindowManager.has_method("get_taskbar_icon_center"):
			var icon_center := WindowManager.get_taskbar_icon_center(self)
			minimize(icon_center)
		else:
			minimize()  # fallback if manager not available
	)
	maximize_button.pressed.connect(toggle_maximize)
	close_button.pressed.connect(_on_close_pressed)
	header.gui_input.connect(_on_header_input)
	
	if icon:
		favicon.texture = icon
	
	call_deferred("_apply_default_window_size_and_position")

func _apply_default_window_size_and_position():
	if size == Vector2.ZERO or size == Vector2(1, 1):
		size = default_size

	position = get_viewport_rect().size / 2 - size / 2
	position += Vector2(randi() % 40 - 20, randi() % 40 - 20)

## ---------------------------- ##
##         Movement            ##
## ---------------------------- ##

func _process(_delta: float) -> void:
	if not is_resizing:
		return
	var viewport_size = get_viewport_rect().size
	var mouse_delta := get_global_mouse_position() - resize_start_mouse
	var new_size := resize_start_size
	var new_pos := resize_start_pos

	# Resize horizontally
	if resize_dir.x != 0:
		new_size.x += mouse_delta.x * resize_dir.x
		if resize_dir.x == -1:
			new_pos.x = resize_start_pos.x + mouse_delta.x
	# Resize vertically
	if resize_dir.y != 0:
		new_size.y += mouse_delta.y * resize_dir.y
		if resize_dir.y == -1:
			new_pos.y = resize_start_pos.y + mouse_delta.y

	# Clamp size
	new_size.x = max(new_size.x, min_window_size.x)
	new_size.y = max(new_size.y, min_window_size.y)

	# Ensure part of window stays visible on screen
	var min_visible_x = MIN_VISIBLE_AREA.x
	var min_visible_y = MIN_VISIBLE_AREA.y

	# Clamp LEFT: don't allow entire window to be dragged rightward offscreen via resizing left
	if resize_dir.x == -1 and new_pos.x + new_size.x < min_visible_x:
		new_pos.x = min_visible_x - new_size.x

	# Clamp TOP: same for vertical
	if resize_dir.y == -1 and new_pos.y + new_size.y < min_visible_y:
		new_pos.y = min_visible_y - new_size.y

	# Clamp RIGHT: don’t let resize move the left edge too far right
	if resize_dir.x == 1 and new_pos.x > viewport_size.x - min_visible_x:
		new_size.x = max(min_window_size.x, viewport_size.x - new_pos.x)

	# Clamp BOTTOM:
	if resize_dir.y == 1 and new_pos.y > viewport_size.y - min_visible_y:
		new_size.y = max(min_window_size.y, viewport_size.y - new_pos.y)

	# Apply final values
	size = new_size
	global_position = new_pos



func _on_header_input(event: InputEvent) -> void:
	if is_resizing:
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		position += event.relative
		_clamp_to_viewport()

func _clamp_to_viewport() -> void:
	var viewport_size = get_viewport_rect().size

	# Left clamp: allow most of the window to hang off, but leave MIN_VISIBLE_AREA.x visible
	var min_x = viewport_size.x - MIN_VISIBLE_AREA.x
	if position.x + size.x < MIN_VISIBLE_AREA.x:
		position.x = MIN_VISIBLE_AREA.x - size.x

	# Right clamp: don't allow the left edge to move too far right
	if position.x > min_x:
		position.x = min_x

	# Top clamp: leave MIN_VISIBLE_AREA.y visible
	var min_y = viewport_size.y - MIN_VISIBLE_AREA.y
	if position.y + size.y < MIN_VISIBLE_AREA.y:
		position.y = MIN_VISIBLE_AREA.y - size.y

	# Bottom clamp
	if position.y > min_y:
		position.y = min_y

func _gui_input(event: InputEvent) -> void:
	if window_state != WindowState.NORMAL:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if WindowManager.has_method("focus_window"):
			WindowManager.focus_window(self)
	
	var local_mouse := get_local_mouse_position()
	var w := size.x
	var h := size.y

	# Determine resize direction
	var dir := Vector2.ZERO
	if local_mouse.x >= w - resize_margin:
		dir.x = 1
	elif local_mouse.x <= resize_margin:
		dir.x = -1
	if local_mouse.y >= h - resize_margin:
		dir.y = 1
	elif local_mouse.y <= resize_margin:
		dir.y = -1

	# Set cursor shape
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

	# Handle mouse press to start resizing
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and dir != Vector2.ZERO:
			is_resizing = true
			resize_dir = dir
			resize_start_mouse = get_global_mouse_position()
			resize_start_size = size
			resize_start_pos = global_position
		elif not event.pressed:
			is_resizing = false


## ---------------------------- ##
##       Window Behaviors      ##
## ---------------------------- ##

func minimize(target_position: Vector2 = global_position) -> void:
	print("Saving last position:", global_position)
	if window_state == WindowState.MINIMIZED:
		return

	# 🧠 Use global_position instead of position
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
	# Special case: if we just unminimized from maximized
	if window_state == WindowState.MINIMIZED:
		show()
		window_state = previous_state

	# Now toggle based on current state
	if window_state == WindowState.MAXIMIZED:
		unmaximize()
	else:
		if window_state == WindowState.NORMAL:
			last_position = position
			last_size = size

		position = Vector2.ZERO
		size = get_viewport_rect().size
		window_state = WindowState.MAXIMIZED


func restore() -> void:
	print("Restoring to:", last_position)

	if window_state != WindowState.MINIMIZED:
		return

	show()
	window_state = previous_state

	if previous_state == WindowState.NORMAL:
		global_position = last_position
		size = last_size
	elif previous_state == WindowState.MAXIMIZED:
		# Restore to full-screen if we minimized from maximized
		position = Vector2.ZERO
		size = get_viewport_rect().size
		window_state = WindowState.MAXIMIZED

	_clamp_to_viewport()


func unmaximize() -> void:
	global_position = last_position
	size = last_size
	window_state = WindowState.NORMAL
	_clamp_to_viewport()

func on_focus():
	modulate = Color(1, 1, 1, 1) # or highlight header, etc.

func on_unfocus():
	modulate = Color(0.9, 0.9, 0.9, 1)

func _on_close_pressed() -> void:
	# Let the WindowManager handle cleanup if available
	if WindowManager.has_method("close_window"):
		WindowManager.close_window(self)
	else:
		queue_free()

func set_window_title(title: String) -> void:
	window_title = title
	if title_label:
		title_label.text = title
