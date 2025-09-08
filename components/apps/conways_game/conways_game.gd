
extends Pane
class_name ConwaysGame

@export var cell_size: int = 10
@export var step_interval: float = 0.1

@onready var play_pause_button: Button = %PlayPauseButton
@onready var reset_button: Button = %ResetButton
@onready var speed_slider: HSlider = %SpeedSlider

var grid: Dictionary = {}
var running: bool = false
var time_accum: float = 0.0
var offset: Vector2 = Vector2.ZERO
var panning: bool = false
var dragging: bool = false
var last_drag_cell: Vector2i = Vector2i.ZERO

func _ready() -> void:
	play_pause_button.pressed.connect(_on_play_pause_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	speed_slider.value = step_interval
	speed_slider.value_changed.connect(_on_speed_slider_value_changed)
	_update_play_pause_text()

func _process(delta: float) -> void:
	if running:
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
				draw_rect(Rect2(pos, Vector2(float(cell_size), float(cell_size))), Color.WHITE, true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var cell: Vector2i = _screen_to_grid(mb.position)
				_toggle_cell(cell)
				dragging = true
				last_drag_cell = cell
			else:
				dragging = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			cell_size += 1
			if cell_size < 1:
				cell_size = 1
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			cell_size -= 1
			if cell_size < 1:
				cell_size = 1
			queue_redraw()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if dragging:
			var cell: Vector2i = _screen_to_grid(mm.position)
			if cell != last_drag_cell:
				_toggle_cells_along_line(last_drag_cell, cell)
				last_drag_cell = cell
		elif panning:
			offset += mm.relative
			queue_redraw()

func _advance_generation() -> void:
	var neighbor_counts: Dictionary = {}
	for cell in grid.keys():
		var neighbors: Array = [
			cell + Vector2i(-1, -1),
			cell + Vector2i(0, -1),
			cell + Vector2i(1, -1),
			cell + Vector2i(-1, 0),
			cell + Vector2i(1, 0),
			cell + Vector2i(-1, 1),
			cell + Vector2i(0, 1),
			cell + Vector2i(1, 1)
		]
		for n in neighbors:
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
	queue_redraw()

func _toggle_cell(cell: Vector2i) -> void:
	var alive: bool = grid.get(cell, false)
	if alive:
			grid.erase(cell)
	else:
			grid[cell] = true
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
		_toggle_cell(Vector2i(x, y))


func _on_play_pause_pressed() -> void:
	running = !running
	_update_play_pause_text()

func _on_reset_pressed() -> void:
	running = false
	grid.clear()
	time_accum = 0.0
	_update_play_pause_text()
	queue_redraw()

func _on_speed_slider_value_changed(value: float) -> void:
	step_interval = value

func _update_play_pause_text() -> void:
	if running:
		play_pause_button.text = "PAUSE"
	else:
		play_pause_button.text = "PLAY"

func _screen_to_grid(pos: Vector2) -> Vector2i:
	var gx: int = int(floor((pos.x - offset.x) / float(cell_size)))
	var gy: int = int(floor((pos.y - offset.y) / float(cell_size)))
	return Vector2i(gx, gy)
