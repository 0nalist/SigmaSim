extends Control
class_name ChartComponent

@export var margins: Vector4 = Vector4(40, 20, 20, 40) # left, top, right, bottom
@export var grid_line_counts: Vector2i = Vector2i(4, 4)
@export var default_window_minutes: int = 30
@export var min_window_minutes: int = 5
@export var max_points_per_series: int = 512
@export var palette: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA, Color.CYAN]

var window_start_min: int = 0
var window_end_min: int = 0
var user_holds_window: bool = false

var _series: Dictionary = {} # id -> {label: String, color: Color, visible: bool}
var _dragging: bool = false
var _drag_last_mouse: Vector2 = Vector2.ZERO

func _ready() -> void:
	var now: int = TimeManager.get_now_minutes()
	window_end_min = now
	window_start_min = max(0, now - default_window_minutes)
	if HistoryManager and HistoryManager.has_signal("series_sampled"):
		HistoryManager.series_sampled.connect(_on_series_sampled)
	if TimeManager and TimeManager.has_signal("minute_passed"):
		TimeManager.minute_passed.connect(_on_minute_passed)
	queue_redraw()

func add_series(id: StringName, label: String = "", color: Color = Color.TRANSPARENT) -> void:
	if color == Color.TRANSPARENT:
		color = _color_from_id(id)
	_series[id] = {"label": label, "color": color, "visible": true}
	queue_redraw()

func remove_series(id: StringName) -> void:
	_series.erase(id)
	queue_redraw()

func set_series_visible(id: StringName, visible: bool) -> void:
	if _series.has(id):
		var entry: Dictionary = _series[id]
		entry["visible"] = visible
		_series[id] = entry
		queue_redraw()

func clear_series() -> void:
	_series.clear()
	queue_redraw()

func _color_from_id(id: StringName) -> Color:
	if palette.is_empty():
		return Color.WHITE
	var idx: int = int(hash(id)) % palette.size()
	if idx < 0:
		idx += palette.size()
	return palette[idx]

func _on_series_sampled(_id: StringName, _t_minute: int) -> void:
	if not user_holds_window:
		_follow_now_and_clamp()
		queue_redraw()

func _on_minute_passed(_total_minutes: int) -> void:
	if not user_holds_window:
		_follow_now_and_clamp()
		queue_redraw()

func _follow_now_and_clamp() -> void:
	var now: int = TimeManager.get_now_minutes()
	var span: int = window_end_min - window_start_min
	if span < min_window_minutes:
		span = min_window_minutes
	window_end_min = now
	window_start_min = max(0, now - span)
	_clamp_window()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var plot: Rect2 = _plot_rect()
			if plot.has_point(event.position):
				var focus_t: int = _time_from_x(event.position.x, plot)
				var span: int = max(min_window_minutes, window_end_min - window_start_min)
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					span = max(min_window_minutes, span - max(1, span / 10))
				else:
					var max_span: int = max(1, TimeManager.get_now_minutes())
					span = min(max_span, span + max(1, span / 10))
				_set_span_centered(span, focus_t)
				user_holds_window = true
				queue_redraw()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var plot: Rect2 = _plot_rect()
				if plot.has_point(event.position):
					_dragging = true
					_drag_last_mouse = event.position
					user_holds_window = true
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var plot: Rect2 = _plot_rect()
		var dx: int = int(round(event.position.x - _drag_last_mouse.x))
		var span: int = max(1, window_end_min - window_start_min)
		var minutes_per_pixel: float = float(span) / max(1.0, plot.size.x)   # <-- typed
		var delta_min: int = int(round(-dx * minutes_per_pixel))
		_pan_by(delta_min)
		_drag_last_mouse = event.position
		queue_redraw()

func _plot_rect() -> Rect2:
	return Rect2(
		margins.x,
		margins.y,
		max(1.0, size.x - margins.x - margins.z),
		max(1.0, size.y - margins.y - margins.w)
	)

func _time_from_x(x: float, plot: Rect2) -> int:
	var span: int = max(1, window_end_min - window_start_min)
	var rel: float = (x - plot.position.x) / max(1.0, plot.size.x)   # <-- typed
	if rel < 0.0:
		rel = 0.0
	if rel > 1.0:
		rel = 1.0
	return window_start_min + int(round(rel * float(span)))

func _pan_by(delta_min: int) -> void:
	window_start_min += delta_min
	window_end_min += delta_min
	_clamp_window()

func _set_span_centered(new_span: int, focus_time: int) -> void:
	new_span = max(min_window_minutes, new_span)
	var span: int = max(1, window_end_min - window_start_min)
	var left_rel: float = 0.5
	if span > 0:
		left_rel = float(focus_time - window_start_min) / float(span)
		left_rel = clamp(left_rel, 0.0, 1.0)
	var new_left: int = focus_time - int(round(left_rel * float(new_span)))
	var new_right: int = new_left + new_span
	window_start_min = new_left
	window_end_min = new_right
	_clamp_window()

func _clamp_window() -> void:
	var now: int = TimeManager.get_now_minutes()
	if window_start_min < 0:
		var shift: int = -window_start_min
		window_start_min += shift
		window_end_min += shift
	if window_end_min > now:
		var shift2: int = window_end_min - now
		window_start_min -= shift2
		window_end_min -= shift2
	if window_end_min < window_start_min + min_window_minutes:
		window_end_min = window_start_min + min_window_minutes
	if window_end_min > now:
		window_end_min = now
		window_start_min = max(0, window_end_min - min_window_minutes)
	if window_start_min < 0:
		window_start_min = 0
		window_end_min = max(window_start_min + min_window_minutes, window_end_min)

func _draw() -> void:
	var plot: Rect2 = _plot_rect()
	var span: int = max(1, window_end_min - window_start_min)
	var min_y: float = INF
	var max_y: float = -INF

	for id in _series.keys():
		var s: Dictionary = _series[id]
		if not s["visible"]:
			continue
		var data: PackedVector2Array = HistoryManager.get_series_window_line(id, window_start_min, window_end_min, max_points_per_series)
		for p in data:
			if p.y < min_y:
				min_y = p.y
			if p.y > max_y:
				max_y = p.y

	if min_y == INF:
		min_y = 0.0
		max_y = 1.0
	if min_y == max_y:
		max_y = min_y + 1.0

	var padding: float = (max_y - min_y) * 0.1
	min_y -= padding
	max_y += padding

	_draw_grid(plot, min_y, max_y, span)
	_draw_series(plot, min_y, max_y)
	_draw_legend(plot)

func _draw_grid(plot: Rect2, min_y: float, max_y: float, span: int) -> void:
	var gx: int = grid_line_counts.x
	var gy: int = grid_line_counts.y

	for i in range(gx + 1):
		var x: float = plot.position.x + float(i) * plot.size.x / float(gx)
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.position.y + plot.size.y), Color(0.2, 0.2, 0.2))
		var t: int = window_start_min + int(round(float(i) * float(span) / float(gx)))  # <-- typed
		var label: String = str(t) + "m"                                               # <-- typed
		var size_px: Vector2 = ThemeDB.fallback_font.get_string_size(label)
		draw_string(ThemeDB.fallback_font, Vector2(x - size_px.x / 2.0, plot.position.y + plot.size.y + size_px.y + 2.0), label)

	for j in range(gy + 1):
		var y: float = plot.position.y + float(j) * plot.size.y / float(gy)
		draw_line(Vector2(plot.position.x, y), Vector2(plot.position.x + plot.size.x, y), Color(0.2, 0.2, 0.2))
		var v: float = max_y - float(j) * (max_y - min_y) / float(gy)
		var text: String = String.num(v, 2)
		var ts: Vector2 = ThemeDB.fallback_font.get_string_size(text)
		draw_string(ThemeDB.fallback_font, Vector2(plot.position.x - ts.x - 4.0, y + ts.y / 2.0), text)

func _draw_series(plot: Rect2, min_y: float, max_y: float) -> void:
	var y_span: float = max_y - min_y
	var span: int = max(1, window_end_min - window_start_min)
	for id in _series.keys():
		var s: Dictionary = _series[id]
		if not s["visible"]:
			continue
		var raw: PackedVector2Array = HistoryManager.get_series_window_line(id, window_start_min, window_end_min, max_points_per_series)
		if raw.is_empty():
			continue
		var pts: PackedVector2Array = PackedVector2Array()
		pts.resize(raw.size())
		for i in range(raw.size()):
			var p: Vector2 = raw[i]
			var x: float = plot.position.x + (float(p.x) - float(window_start_min)) / float(span) * plot.size.x
			var y: float = plot.position.y + (1.0 - (p.y - min_y) / y_span) * plot.size.y
			pts[i] = Vector2(x, y)
		if pts.size() == 1:
			draw_circle(pts[0], 2.0, s["color"])
		else:
			draw_polyline(pts, s["color"])

func _draw_legend(plot: Rect2) -> void:
	var font: Font = ThemeDB.fallback_font
	var offset: Vector2 = Vector2(4, 4)
	var y: float = 0.0
	for id in _series.keys():
		var s: Dictionary = _series[id]
		if not s["visible"]:
			continue
		draw_rect(Rect2(plot.position + offset + Vector2(0, y), Vector2(10, 10)), s["color"], true)
		var label: String = s["label"]               # <-- typed
		if label == "":
			label = String(id)
		draw_string(font, plot.position + offset + Vector2(14, y + 10), label)
		y += 14.0
