extends Control
class_name ChartComponent

@export var margins: Vector4 = Vector4(40, 20, 20, 40) # left, top, right, bottom
@export var grid_line_counts: Vector2i = Vector2i(4, 4)
@export var default_window_seconds: float = 30.0
@export var max_points_per_series: int = 256
@export var palette: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA, Color.CYAN]

var window_end_time: float = 0.0
var window_span: float
var user_holds_window: bool = false

var _series: Dictionary = {}
var _dragging: bool = false
var _drag_last_mouse: Vector2 = Vector2.ZERO

func _ready() -> void:
	window_span = default_window_seconds
	window_end_time = Time.get_ticks_msec() / 1000.0
	if HistoryManager and HistoryManager.has_signal("series_sampled"):
		HistoryManager.series_sampled.connect(_on_series_sampled)
	queue_redraw()

func add_series(id: StringName, label: String = "", color: Color = Color.TRANSPARENT) -> void:
	if color == Color.TRANSPARENT:
		color = _color_from_id(id)
	_series[id] = {
		"label": label,
		"color": color,
		"visible": true,
	}
	queue_redraw()

func remove_series(id: StringName) -> void:
	_series.erase(id)
	queue_redraw()

func set_series_visible(id: StringName, visible: bool) -> void:
	if _series.has(id):
		_series[id].visible = visible
		queue_redraw()

func clear_series() -> void:
	_series.clear()
	queue_redraw()

func _color_from_id(id: StringName) -> Color:
	if palette.is_empty():
		return Color.WHITE
	var idx = int(hash(id)) % palette.size()
	if idx < 0:
		idx += palette.size()
	return palette[idx]

func _on_series_sampled(_id: StringName, t: float) -> void:
	if not user_holds_window:
		window_end_time = t
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var plot = _plot_rect()
			if plot.has_point(event.position):
				var zoom := 0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1
				var mouse_t = _time_from_x(event.position.x, plot)
				window_span *= zoom
				var start_t = window_end_time - window_span
				var rel = (mouse_t - start_t) / window_span
				window_end_time = mouse_t + (1.0 - rel) * window_span
				user_holds_window = true
				queue_redraw()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var plot = _plot_rect()
				if plot.has_point(event.position):
					_dragging = true
					_drag_last_mouse = event.position
					user_holds_window = true
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var plot = _plot_rect()
		var dx = event.position.x - _drag_last_mouse.x
		var seconds_per_pixel = window_span / max(plot.size.x, 1.0)
		window_end_time -= dx * seconds_per_pixel
		_drag_last_mouse = event.position
		queue_redraw()

func _plot_rect() -> Rect2:
	return Rect2(margins.x, margins.y, max(1.0, size.x - margins.x - margins.z), max(1.0, size.y - margins.y - margins.w))

func _time_from_x(x: float, plot: Rect2) -> float:
	var start_t = window_end_time - window_span
	return start_t + ((x - plot.position.x) / plot.size.x) * window_span

func _draw() -> void:
	var plot = _plot_rect()
	var t_start = window_end_time - window_span
	var t_end = window_end_time
	
	var min_y := INF
	var max_y := -INF
	for id in _series.keys():
		var s = _series[id]
		if not s.visible:
			continue
		var data: PackedVector2Array = HistoryManager.get_series_window_line(id, t_start, t_end, max_points_per_series)
		for p in data:
			if p.y < min_y:
				min_y = p.y
			if p.y > max_y:
				max_y = p.y
	if min_y == INF:
		min_y = 0.0
		max_y = 1.0
	if min_y == max_y:
		max_y += 1.0
	var padding = (max_y - min_y) * 0.1
	min_y -= padding
	max_y += padding
	
	_draw_grid(plot, t_start, min_y, max_y)
	_draw_series(plot, t_start, min_y, max_y)
	_draw_legend(plot)

func _draw_grid(plot: Rect2, t_start: float, min_y: float, max_y: float) -> void:
	var font = ThemeDB.fallback_font
	var gx = grid_line_counts.x
	var gy = grid_line_counts.y
	for i in range(gx + 1):
		var x = plot.position.x + i * plot.size.x / gx
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.position.y + plot.size.y), Color(0.2, 0.2, 0.2))
		var t = t_start + i * window_span / gx
		var text = "%.1f" % t
		var ts = font.get_string_size(text)
		draw_string(font, Vector2(x - ts.x / 2, plot.position.y + plot.size.y + ts.y + 2), text)
	for j in range(gy + 1):
		var y = plot.position.y + j * plot.size.y / gy
		draw_line(Vector2(plot.position.x, y), Vector2(plot.position.x + plot.size.x, y), Color(0.2, 0.2, 0.2))
		var v = max_y - j * (max_y - min_y) / gy
		var text = "%.2f" % v
		var ts = font.get_string_size(text)
		draw_string(font, Vector2(plot.position.x - ts.x - 4, y + ts.y / 2), text)

func _draw_series(plot: Rect2, t_start: float, min_y: float, max_y: float) -> void:
	var y_span = max_y - min_y
	for id in _series.keys():
		var s = _series[id]
		if not s.visible:
			continue
		var raw: PackedVector2Array = HistoryManager.get_series_window_line(id, t_start, t_start + window_span, max_points_per_series)
		if raw.is_empty():
			continue
		if raw.size() == 1:
			var p = raw[0]
			var x = plot.position.x + (p.x - t_start) / window_span * plot.size.x
			var y = plot.position.y + (1.0 - (p.y - min_y) / y_span) * plot.size.y
			draw_circle(Vector2(x, y), 2, s.color)
			continue
		var pts: PackedVector2Array
		pts.resize(raw.size())
		for i in range(raw.size()):
			var p = raw[i]
			var x = plot.position.x + (p.x - t_start) / window_span * plot.size.x
			var y = plot.position.y + (1.0 - (p.y - min_y) / y_span) * plot.size.y
			pts[i] = Vector2(x, y)
		draw_polyline(pts, s.color)

func _draw_legend(plot: Rect2) -> void:
	var font = ThemeDB.fallback_font
	var offset = Vector2(4, 4)
	var y := 0.0
	for id in _series.keys():
		var s = _series[id]
		if not s.visible:
			continue
		draw_rect(Rect2(plot.position + offset + Vector2(0, y), Vector2(10, 10)), s.color, true)
		var label = s.label if s.label != "" else String(id)
		draw_string(font, plot.position + offset + Vector2(14, y + 10), label)
		y += 14
