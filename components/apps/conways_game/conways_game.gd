
extends Pane
class_name ConwaysGame

@export var cell_size: int = 10
@export var step_interval: float = 0.1
@export var living_color: Color = Color.WHITE

@onready var play_pause_button: Button = %PlayPauseButton
@onready var reset_button: Button = %ResetButton
@onready var speed_slider: HSlider = %SpeedSlider
@onready var color_picker: ColorPickerButton = %ColorPicker

# Packed array of currently living cells.
var cells: PackedVector2Array = PackedVector2Array()
var running: bool = false
var time_accum: float = 0.0
var offset: Vector2 = Vector2.ZERO
var panning: bool = false
var dragging: bool = false
var last_drag_cell: Vector2i = Vector2i.ZERO

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
        for cell_vec in cells:
                var cell: Vector2i = Vector2i(cell_vec)
                if cell.x >= min_x and cell.x <= max_x and cell.y >= min_y and cell.y <= max_y:
                        var pos: Vector2 = offset + Vector2(cell) * float(cell_size)
                        draw_rect(Rect2(pos, Vector2(float(cell_size), float(cell_size))), living_color, true)

func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var local_pos := get_local_mouse_position()
				var cell: Vector2i = _screen_to_grid(local_pos)
				_toggle_cell(cell)
				dragging = true
				last_drag_cell = cell
			else:
				dragging = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			var mouse_pos := get_local_mouse_position()
			var world_pos := (mouse_pos - offset) / float(cell_size)
			cell_size += 1
			if cell_size < 1:
				cell_size = 1
			offset = mouse_pos - world_pos * float(cell_size)
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			var mouse_pos := get_local_mouse_position()
			var world_pos := (mouse_pos - offset) / float(cell_size)
			cell_size -= 1
			if cell_size < 1:
				cell_size = 1
			offset = mouse_pos - world_pos * float(cell_size)
			queue_redraw()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if dragging:
			var local_pos := get_local_mouse_position()
			var cell: Vector2i = _screen_to_grid(local_pos)
			if cell != last_drag_cell:
				_toggle_cells_along_line(last_drag_cell, cell)
				last_drag_cell = cell
		elif panning:
			offset += mm.relative
			queue_redraw()


func _advance_generation() -> void:
        var neighbor_counts: Dictionary = {}
        for cell_vec in cells:
                var cell: Vector2i = Vector2i(cell_vec)
                for offset in NEIGHBOR_OFFSETS:
                        var n: Vector2i = cell + offset
                        var count: int = neighbor_counts.get(n, 0)
                        neighbor_counts[n] = count + 1
                neighbor_counts[cell] = neighbor_counts.get(cell, 0)
        var new_cells: PackedVector2Array = PackedVector2Array()
        for cell in neighbor_counts.keys():
                var count: int = neighbor_counts[cell]
                var alive: bool = cells.has(Vector2(cell))
                if alive:
                        if count == 2 or count == 3:
                                new_cells.append(Vector2(cell))
                else:
                        if count == 3:
                                new_cells.append(Vector2(cell))
        cells = new_cells
        queue_redraw()

func _toggle_cell(cell: Vector2i) -> void:
        var idx: int = cells.find(Vector2(cell))
        if idx != -1:
                cells.remove_at(idx)
        else:
                cells.append(Vector2(cell))
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
        cells.clear()
        time_accum = 0.0
        _update_play_pause_text()
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

func _screen_to_grid(pos: Vector2) -> Vector2i:
	var gx: int = int(floor((pos.x - offset.x) / float(cell_size)))
	var gy: int = int(floor((pos.y - offset.y) / float(cell_size)))
	return Vector2i(gx, gy)
