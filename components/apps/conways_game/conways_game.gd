
extends Pane
class_name ConwaysGame

@export var cell_size: int = 10
@export var step_interval: float = 0.1
@export var living_color: Color = Color.WHITE

@onready var play_pause_button: Button = %PlayPauseButton
@onready var reset_button: Button = %ResetButton
@onready var speed_slider: HSlider = %SpeedSlider
@onready var color_picker: ColorPickerButton = %ColorPicker
@onready var generation_label: Label = %GenerationLabel
@onready var population_label: Label = %PopulationLabel

var grid: Dictionary = {}
var running: bool = false
var time_accum: float = 0.0
var offset: Vector2 = Vector2.ZERO
var panning: bool = false
var dragging: bool = false
var last_drag_cell: Vector2i = Vector2i.ZERO
var generation: int = 0

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1)
]

func _ready() -> void:

	play_pause_button.pressed.connect(_on_play_pause_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	speed_slider.value = speed_slider.max_value - step_interval
	speed_slider.value_changed.connect(_on_speed_slider_value_changed)
	color_picker.color = living_color
	color_picker.color_changed.connect(_on_color_picker_color_changed)
	_update_play_pause_text()
	_update_labels()


func _process(delta: float) -> void:
	if running:
			if step_interval <= 0.0:
					_advance_generation()
			else:
					time_accum += delta
					while time_accum >= step_interval:
							time_accum -= step_interval
							_advance_generation()

func _draw() -> void:
	var viewport_size: Vector2 = get_size()
	var min_x: int = int(floor(-offset.x / float(cell_size)))
	var min_y: int = int(floor(-offset.y / float(cell_size)))
	var max_x: int = int(ceil((viewport_size.x - offset.x) / float(cell_size)))
	var max_y: int = int(ceil((viewport_size.y - offset.y) / float(cell_size)))
	for cell in grid.keys():
		var alive: bool = grid[cell]
		if alive:
			if cell.x >= min_x and cell.x <= max_x and cell.y >= min_y and cell.y <= max_y:
				var pos: Vector2 = offset + Vector2(float(cell.x), float(cell.y)) * float(cell_size)
				draw_rect(Rect2(pos, Vector2(float(cell_size), float(cell_size))), living_color, true)

func _input(event: InputEvent) -> void:
	# Only handle input if this pane is focused and under the mouse
	if window_frame != WindowManager.focused_window:
		return

	var hovered: Control = get_viewport().gui_get_hovered_control()
	var mouse_inside: bool = false
	if hovered == self:
		mouse_inside = true
	elif hovered != null:
		mouse_inside = self.is_ancestor_of(hovered)
	else:
		# Fallback: treat as inside only if the cursor is within this Control's rect
		var local_pos_fallback: Vector2 = get_local_mouse_position()
		mouse_inside = get_rect().has_point(local_pos_fallback)

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and mouse_inside:
				var local_pos: Vector2 = get_local_mouse_position()
				var cell: Vector2i = _screen_to_grid(local_pos)
				_toggle_cell(cell)
				dragging = true
				last_drag_cell = cell
			elif not mb.pressed:
				dragging = false

		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_inside:
				panning = mb.pressed

		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			if mouse_inside:
				var mouse_pos: Vector2 = get_local_mouse_position()
				var world_pos: Vector2 = (mouse_pos - offset) / float(cell_size)
				cell_size += 1
				if cell_size < 1:
					cell_size = 1
				offset = mouse_pos - world_pos * float(cell_size)
				queue_redraw()

		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			if mouse_inside:
				var mouse_pos: Vector2 = get_local_mouse_position()
				var world_pos: Vector2 = (mouse_pos - offset) / float(cell_size)
				cell_size -= 1
				if cell_size < 1:
					cell_size = 1
				offset = mouse_pos - world_pos * float(cell_size)
				queue_redraw()

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if dragging:
			var local_pos: Vector2 = get_local_mouse_position()
			var cell: Vector2i = _screen_to_grid(local_pos)
			if cell != last_drag_cell:
				_toggle_cells_along_line(last_drag_cell, cell)
				last_drag_cell = cell
		elif panning:
			offset += mm.relative
			queue_redraw()

func _advance_generation() -> void:
	var neighbor_counts: Dictionary = {}
	for cell in grid.keys():
		for offset in NEIGHBOR_OFFSETS:
			var n: Vector2i = cell + offset
			var count: int = neighbor_counts.get(n, 0)
			neighbor_counts[n] = count + 1
		neighbor_counts[cell] = neighbor_counts.get(cell, 0)
	var new_grid: Dictionary = {}
	for cell in neighbor_counts.keys():
		var count: int = neighbor_counts[cell]
		var alive: bool = grid.has(cell)
		if alive:
			if count == 2 or count == 3:
				new_grid[cell] = true
		else:
			if count == 3:
				new_grid[cell] = true
	grid = new_grid
	generation += 1
	_update_labels()
	queue_redraw()

func _toggle_cell(cell: Vector2i, update_labels: bool = true) -> void:
	var alive: bool = grid.get(cell, false)
	if alive:
		grid.erase(cell)
	else:
		grid[cell] = true
	if update_labels:
		_update_labels()
	queue_redraw()

func _toggle_cells_along_line(start: Vector2i, end: Vector2i) -> void:
	var x0: int = start.x
	var y0: int = start.y
	var x1: int = end.x
	var y1: int = end.y
	
	var dx: int = abs(x1 - x0)
	var sx: int = -1
	if x0 < x1:
		sx = 1

	var dy: int = -abs(y1 - y0)
	var sy: int = -1
	if y0 < y1:
		sy = 1

	var err: int = dx + dy
	var x: int = x0
	var y: int = y0

	while x != x1 or y != y1:
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
		_toggle_cell(Vector2i(x, y), false)
	_update_labels()


func _on_play_pause_pressed() -> void:
	running = !running
	_update_play_pause_text()

func _on_reset_pressed() -> void:
	running = false
	grid.clear()
	time_accum = 0.0
	generation = 0
	_update_play_pause_text()
	_update_labels()
	queue_redraw()

func _on_speed_slider_value_changed(value: float) -> void:
	step_interval = speed_slider.max_value - value
	time_accum = 0.0

func _on_color_picker_color_changed(color: Color) -> void:
	living_color = color
	queue_redraw()

func _update_play_pause_text() -> void:
	if running:
		play_pause_button.text = "PAUSE"
	else:
		play_pause_button.text = "PLAY"

func _update_labels() -> void:
	generation_label.text = "Generation: %d" % generation
	population_label.text = "Population: %d" % grid.size()

func _screen_to_grid(pos: Vector2) -> Vector2i:
	var gx: int = int(floor((pos.x - offset.x) / float(cell_size)))
	var gy: int = int(floor((pos.y - offset.y) / float(cell_size)))
	return Vector2i(gx, gy)
