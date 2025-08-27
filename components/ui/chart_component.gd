extends Control
class_name ChartComponent

const DEBUG_HISTORY := false
const AXIS_FONT_SIZE := 11

@export_category("Appearance")
@export var margins: Vector4 = Vector4(40, 20, 20, 40) # left, top, right, bottom
@export var grid_line_counts: Vector2i = Vector2i(4, 4)
@export var palette: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA, Color.CYAN]

@export_category("Sampling & Data")
@export var default_window_minutes: int = 30
@export var min_window_minutes: int = 5
@export var max_points_per_series: int = 512
@export var extend_last_sample: bool = true

@export_category("Behavior")
@export var autoscroll: bool = true
@export var autoscroll_locked: bool = true
@export var autoscroll_hold_timeout_sec: float = 3.0
@export var lock_y_min: bool = true
@export var lock_x_min: bool = false

@export_category("Polling")
@export var poll_hz: int = 20
@export var always_poll: bool = true

var window_start_min: int = 0
var window_end_min: int = 0
var user_holds_window: bool = false

var _series: Dictionary = {} # id -> {label: String, color: Color, visible: bool}
var _dragging: bool = false
var _drag_last_mouse: Vector2 = Vector2.ZERO

# Dirty/tempo
var _needs_redraw: bool = true
var _poll_accum: float = 0.0
var _poll_interval: float = 0.05
var _last_user_input_time: float = 0.0
var _last_now_seen: int = -1
var _computed_left_margin: float = margins.x

func _ready() -> void:
	var now: int = TimeManager.get_now_minutes()
	window_end_min = now
	if lock_x_min:
		window_start_min = 0
	else:
		window_start_min = max(0, now - default_window_minutes)
	_last_now_seen = now

	_poll_interval = 1.0 / float(max(1, poll_hz))

	if HistoryManager and HistoryManager.has_signal("series_sampled"):
		HistoryManager.series_sampled.connect(_on_series_sampled)
	if TimeManager and TimeManager.has_signal("minute_passed"):
		TimeManager.minute_passed.connect(_on_minute_passed)

	_needs_redraw = true
	queue_redraw()

func _process(delta: float) -> void:
	if not always_poll and not _has_signals():
		return
	_poll_accum += delta
	if _poll_accum >= _poll_interval:
		_poll_accum -= _poll_interval

		# only let user hold override when not locked
		if autoscroll and not autoscroll_locked and user_holds_window:
			var now_secs: float = Time.get_ticks_msec() / 1000.0
			var idle: float = now_secs - _last_user_input_time
			if idle >= autoscroll_hold_timeout_sec:
				user_holds_window = false

		var now_min: int = TimeManager.get_now_minutes()
		if autoscroll and (autoscroll_locked or not user_holds_window):
			if now_min != _last_now_seen:
				_follow_now_and_clamp()
				_needs_redraw = true
		_last_now_seen = now_min

		if _needs_redraw:
			_needs_redraw = false
			queue_redraw()

func _has_signals() -> bool:
	var has_hist: bool = false
	if HistoryManager:
		has_hist = HistoryManager.has_signal("series_sampled")
	var has_time: bool = false
	if TimeManager:
		has_time = TimeManager.has_signal("minute_passed")
	return has_hist or has_time

func set_autoscroll(on: bool, locked: bool = false) -> void:
	autoscroll = on
	autoscroll_locked = locked
	if autoscroll:
		user_holds_window = false
		_follow_now_and_clamp()
		_needs_redraw = true
		queue_redraw()

func add_series(id: StringName, label: String = "", color: Color = Color.TRANSPARENT) -> void:
	var col_out: Color = color
	if col_out == Color.TRANSPARENT:
		col_out = _color_from_id(id)
	var entry: Dictionary = {"label": label, "color": col_out, "visible": true}
	_series[id] = entry
	_needs_redraw = true
	queue_redraw()

func remove_series(id: StringName) -> void:
	_series.erase(id)
	_needs_redraw = true
	queue_redraw()

func set_series_visible(id: StringName, visible: bool) -> void:
	if _series.has(id):
		var s: Dictionary = _series[id]
		s["visible"] = visible
		_series[id] = s
		_needs_redraw = true
		queue_redraw()

func clear_series() -> void:
	_series.clear()
	_needs_redraw = true
	queue_redraw()

func _color_from_id(id: StringName) -> Color:
	if palette.is_empty():
		return Color.WHITE
	var idx: int = int(hash(id)) % palette.size()
	if idx < 0:
		idx += palette.size()
	return palette[idx]

# ---- Signals ----

func _on_series_sampled(_id: StringName, _t_minute: int) -> void:
	if autoscroll and (autoscroll_locked or not user_holds_window):
		_follow_now_and_clamp()
	_needs_redraw = true

func _on_minute_passed(_total_minutes: int) -> void:
	if autoscroll and (autoscroll_locked or not user_holds_window):
		var changed: bool = _follow_now_and_clamp()
		if changed:
			_needs_redraw = true

# Snap right edge to now and preserve span; returns true if window changed
func _follow_now_and_clamp() -> bool:
	var now: int = TimeManager.get_now_minutes()
	var old_start: int = window_start_min
	var old_end: int = window_end_min

	if lock_x_min:
		window_start_min = 0
		window_end_min = now
	else:
		var span: int = window_end_min - window_start_min
		if span < min_window_minutes:
			span = min_window_minutes
		window_end_min = now
		window_start_min = max(0, now - span)

	_clamp_window()
	return window_start_min != old_start or window_end_min != old_end


# ---- Input (zoom & pan) ----

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event

		# Mouse wheel: zoom
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var plot: Rect2 = _plot_rect()
			# Only react if the cursor is over the plot
			if not plot.has_point(mb.position):
				return

			_mark_user_activity()

			# When x-min is locked, always show [0, now] and ignore span math
			if lock_x_min:
				window_start_min = 0
				window_end_min = TimeManager.get_now_minutes()
				_clamp_window()
				if autoscroll_locked:
					user_holds_window = false
					_follow_now_and_clamp()
				else:
					user_holds_window = true
				_needs_redraw = true
				queue_redraw()
				return

			# Normal zoom behavior (x not locked)
			var focus_t: int = _time_from_x(mb.position.x, plot)
			var span: int = max(min_window_minutes, window_end_min - window_start_min)

			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				span = max(min_window_minutes, span - max(1, span / 10))
			else:
				var max_span: int = max(1, TimeManager.get_now_minutes())
				span = min(max_span, span + max(1, span / 10))

			_set_span_centered(span, focus_t)

			if autoscroll_locked:
				user_holds_window = false
				_follow_now_and_clamp()
			else:
				user_holds_window = true

			_needs_redraw = true
			queue_redraw()

		# Mouse left: start/stop drag panning (blocked if autoscroll/x-lock)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var plot2: Rect2 = _plot_rect()
				if plot2.has_point(mb.position):
					if not autoscroll_locked and not lock_x_min:
						_dragging = true
						_drag_last_mouse = mb.position
						user_holds_window = true
			else:
				_dragging = false

	elif event is InputEventMouseMotion and _dragging:
		var mm: InputEventMouseMotion = event
		_mark_user_activity()
		var plot3: Rect2 = _plot_rect()
		var dx: int = int(round(mm.position.x - _drag_last_mouse.x))
		var span2: int = max(1, window_end_min - window_start_min)
		var minutes_per_pixel: float = float(span2) / max(1.0, plot3.size.x)
		var delta_min: int = int(round(-dx * minutes_per_pixel))
		_pan_by(delta_min)
		_drag_last_mouse = mm.position
		_needs_redraw = true
		queue_redraw()


func _mark_user_activity() -> void:
	_last_user_input_time = Time.get_ticks_msec() / 1000.0

# ---- Window math ----

func _plot_rect() -> Rect2:
        return Rect2(
                _computed_left_margin,
                margins.y,
                max(1.0, size.x - _computed_left_margin - margins.z),
                max(1.0, size.y - margins.y - margins.w)
        )

func _time_from_x(x: float, plot: Rect2) -> int:
	var span: int = max(1, window_end_min - window_start_min)
	var rel: float = (x - plot.position.x) / max(1.0, plot.size.x)
	if rel < 0.0:
		rel = 0.0
	if rel > 1.0:
		rel = 1.0
	return window_start_min + int(round(rel * float(span)))

func _pan_by(delta_min: int) -> void:
	if autoscroll_locked or lock_x_min:
		return
	if delta_min == 0:
		return
	window_start_min += delta_min
	window_end_min += delta_min
	_clamp_window()

func _set_span_centered(new_span: int, focus_time: int) -> void:
	var span: int = new_span
	if span < min_window_minutes:
		span = min_window_minutes
	var cur_span: int = max(1, window_end_min - window_start_min)
	var left_rel: float = 0.5
	if cur_span > 0:
		left_rel = float(focus_time - window_start_min) / float(cur_span)
		if left_rel < 0.0:
			left_rel = 0.0
		if left_rel > 1.0:
			left_rel = 1.0
	var new_left: int = focus_time - int(round(left_rel * float(span)))
	var new_right: int = new_left + span
	window_start_min = new_left
	window_end_min = new_right
	_clamp_window()

func _clamp_window() -> void:
	var now: int = TimeManager.get_now_minutes()

	if lock_x_min:
		window_start_min = 0

	# Keep inside [0, now]
	if window_start_min < 0:
		var shift: int = -window_start_min
		window_start_min += shift
		window_end_min += shift
	if window_end_min > now:
		var shift2: int = window_end_min - now
		window_start_min -= shift2
		window_end_min -= shift2

	# Enforce minimum span
	if window_end_min < window_start_min + min_window_minutes:
		window_end_min = window_start_min + min_window_minutes

	# If right bound still beyond now, reapply with left guard
	if window_end_min > now:
		window_end_min = now
		if lock_x_min:
			window_start_min = 0
		else:
			window_start_min = max(0, window_end_min - min_window_minutes)

	# Left bound final guard
	if window_start_min < 0:
		window_start_min = 0
		window_end_min = max(window_start_min + min_window_minutes, window_end_min)

# ---- Anchored series builder ----

func _left_anchor_at(id: StringName, start_min: int) -> Dictionary:
		var before: Dictionary = HistoryManager.get_value_at_or_before(id, start_min)
		var after: Dictionary = HistoryManager.get_first_value_in_or_after(id, start_min)
		var before_found: bool = bool(before.get("found", false))
		var after_found: bool = bool(after.get("found", false))
		var res: Dictionary = {"found": false, "v": 0.0}
		if before_found and after_found:
				var t_b: int = int(before.get("t", 0))
				var t_a: int = int(after.get("t", 0))
				if t_b == start_min:
						res = {"found": true, "v": float(before.get("v", 0.0))}
				elif t_a == start_min:
						res = {"found": true, "v": float(after.get("v", 0.0))}
				elif t_b != t_a:
						var alpha: float = float(start_min - t_b) / float(t_a - t_b)
						var v_b: float = float(before.get("v", 0.0))
						var v_a: float = float(after.get("v", 0.0))
						var interp: float = v_b + (v_a - v_b) * alpha
						res = {"found": true, "v": interp}
				else:
						res = {"found": true, "v": float(before.get("v", 0.0))}
		elif before_found:
				res = {"found": true, "v": float(before.get("v", 0.0))}
		elif after_found:
				res = {"found": true, "v": float(after.get("v", 0.0))}
		return res

func _build_series_with_anchors(id: StringName, start_min: int, end_min: int) -> PackedVector2Array:
		var raw: PackedVector2Array = HistoryManager.get_series_window_line(id, start_min, end_min, max_points_per_series)
		var prev_dbg: Dictionary = {}
		if DEBUG_HISTORY:
			prev_dbg = HistoryManager.get_value_at_or_before(id, start_min)

		if DEBUG_HISTORY:
				var preview_raw: Array = []
				for i in range(min(5, raw.size())):
						preview_raw.append(raw[i])
				print("_build_series_with_anchors id=%s start=%d end=%d prev=%s raw_first=%s" % [id, start_min, end_min, prev_dbg, preview_raw])
		var left: Dictionary = _left_anchor_at(id, start_min)
		var out: PackedVector2Array = raw
		if bool(left.get("found", false)):
				if out.size() == 0 or int(out[0].x) > start_min:
						var tmp: PackedVector2Array = PackedVector2Array()
						tmp.resize(out.size() + 1)
						tmp[0] = Vector2(float(start_min), float(left.get("v", 0.0)))
						for i in range(out.size()):
								tmp[i + 1] = out[i]
						out = tmp
		elif out.size() == 0:
				return PackedVector2Array()

		if extend_last_sample:
			var right_val: float = 0.0
			if bool(left.get("found", false)):
				right_val = float(left.get("v", 0.0))
			if out.size() > 0:
				right_val = out[out.size() - 1].y
			if out.size() == 0 or int(out[out.size() - 1].x) < end_min:
				out.push_back(Vector2(float(end_min), right_val))

		if DEBUG_HISTORY:
				var preview_out: Array = []
				for i in range(min(5, out.size())):
						preview_out.append(out[i])
				print("_build_series_with_anchors anchored_first=%s" % [preview_out])
		return out

# ---- Y-bounds computation (uses anchored series) ----

func _compute_y_bounds() -> Vector2:
	var min_y: float = 0.0
	if not lock_y_min:
		min_y = INF
	var max_y: float = -INF

	for id in _series.keys():
		var s: Dictionary = _series[id]
		var vis: bool = bool(s.get("visible", true))
		if not vis:
			continue

		var with_anchors: PackedVector2Array = _build_series_with_anchors(id, window_start_min, window_end_min)
		for p in with_anchors:
			if lock_y_min:
				if p.y > max_y:
					max_y = p.y
			else:
				if p.y < min_y:
					min_y = p.y
				if p.y > max_y:
					max_y = p.y

	if max_y == -INF:
		max_y = 1.0
	if not lock_y_min and min_y == INF:
		min_y = 0.0
	if max_y <= min_y:
		max_y = min_y + 1.0

        var padding: float = (max_y - min_y) * 0.1
        return Vector2(min_y, max_y + padding)

func _compute_left_margin(min_y: float, max_y: float) -> float:
        var gy: int = grid_line_counts.y
        var max_w: float = 0.0
        for j in range(gy + 1):
                var v: float = max_y - float(j) * (max_y - min_y) / float(gy)
                var text: String = String.num(v, 2)
                var ts: Vector2 = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, AXIS_FONT_SIZE)
                if ts.x > max_w:
                        max_w = ts.x
        return max(margins.x, max_w + 4.0)

# ---- Rendering ----

func _draw() -> void:
        var span: int = max(1, window_end_min - window_start_min)

        var bounds: Vector2 = _compute_y_bounds()
        var min_y: float = bounds.x
        var max_y: float = bounds.y
        _computed_left_margin = _compute_left_margin(min_y, max_y)
        var plot: Rect2 = _plot_rect()
        var y_span: float = max_y - min_y

        _draw_grid(plot, min_y, max_y, span)
        _draw_series(plot, min_y, max_y, y_span, span)
        _draw_legend(plot)

func _draw_grid(plot: Rect2, min_y: float, max_y: float, span: int) -> void:
	var gx: int = grid_line_counts.x
	var gy: int = grid_line_counts.y

	for i in range(gx + 1):
		var x: float = plot.position.x + float(i) * plot.size.x / float(gx)
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.position.y + plot.size.y), Color(0.2, 0.2, 0.2))
		var t: int = window_start_min + int(round(float(i) * float(span) / float(gx)))
                var label: String = str(t) + "m"
                var size_px: Vector2 = ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, AXIS_FONT_SIZE)
                draw_string(ThemeDB.fallback_font, Vector2(x - size_px.x / 2.0, plot.position.y + plot.size.y + size_px.y + 2.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, AXIS_FONT_SIZE)

	for j in range(gy + 1):
		var y: float = plot.position.y + float(j) * plot.size.y / float(gy)
		draw_line(Vector2(plot.position.x, y), Vector2(plot.position.x + plot.size.x, y), Color(0.2, 0.2, 0.2))
		var v: float = max_y - float(j) * (max_y - min_y) / float(gy)
                var text: String = String.num(v, 2)
                var ts: Vector2 = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, AXIS_FONT_SIZE)
                draw_string(ThemeDB.fallback_font, Vector2(plot.position.x - ts.x - 4.0, y + ts.y / 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, AXIS_FONT_SIZE)

func _draw_series(plot: Rect2, min_y: float, max_y: float, y_span: float, span: int) -> void:
	for id in _series.keys():
		var s: Dictionary = _series[id]
		var vis: bool = bool(s.get("visible", true))
		if not vis:
			continue

		var raw: PackedVector2Array = _build_series_with_anchors(id, window_start_min, window_end_min)
		if raw.is_empty():
			continue

		var pts: PackedVector2Array = PackedVector2Array()
		pts.resize(raw.size())
		for i in range(raw.size()):
			var p: Vector2 = raw[i]
			var x: float = plot.position.x + (float(p.x) - float(window_start_min)) / float(span) * plot.size.x
			var y: float = plot.position.y + (1.0 - (p.y - min_y) / y_span) * plot.size.y
			pts[i] = Vector2(x, y)

		var color: Color = s.get("color", Color.WHITE)
		if pts.size() == 1:
			draw_circle(pts[0], 2.0, color)
		else:
			draw_polyline(pts, color)

func _draw_legend(plot: Rect2) -> void:
	var font: Font = ThemeDB.fallback_font
	var offset: Vector2 = Vector2(4, 4)
	var y: float = 0.0
	for id in _series.keys():
		var s: Dictionary = _series[id]
		var vis: bool = bool(s.get("visible", true))
		if not vis:
			continue
		var color: Color = Color.WHITE
		if s.has("color"):
			color = s["color"]
		draw_rect(Rect2(plot.position + offset + Vector2(0, y), Vector2(10, 10)), color, true)
		var label: String = ""
		if s.has("label"):
			label = String(s["label"])
		if label == "":
			label = String(id)
		draw_string(font, plot.position + offset + Vector2(14, y + 10.0), label)
		y += 14.0
