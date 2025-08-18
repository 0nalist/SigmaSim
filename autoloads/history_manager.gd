extends Node
# Autoload: HistoryManager

signal series_registered(id: StringName)
signal series_sampled(id: StringName, t_minute: int)

# All dt/horizon values are in MINUTES.
const TIER_CONFIG := [
	{"dt": 1, "horizon": 60, "capacity": 2048},          # 1h @ 1-min
	{"dt": 5, "horizon": 24 * 60, "capacity": 2048},      # 1d @ 5-min
	{"dt": 60, "horizon": 14 * 24 * 60, "capacity": 2048} # 14d @ 1-hr
]

var _series: Dictionary = {} # id -> {"tiers":[{"line":{...},"candles":{...}}, ...]}

func register_series(id: StringName) -> void:
	if _series.has(id):
		return
	var tiers: Array = []
	for cfg in TIER_CONFIG:
		var cap: int = int(cfg.capacity)
		var line := {
			"times": PackedInt32Array(),
			"values": PackedFloat32Array(),
			"head": 0,
			"size": 0,
			"capacity": cap
		}
		line.times.resize(cap)
		line.values.resize(cap)
		var candles := {
			"t_open": PackedInt32Array(),
			"t_close": PackedInt32Array(),
			"open": PackedFloat32Array(),
			"high": PackedFloat32Array(),
			"low": PackedFloat32Array(),
			"close": PackedFloat32Array(),
			"head": 0,
			"size": 0,
			"capacity": cap
		}
		candles.t_open.resize(cap)
		candles.t_close.resize(cap)
		candles.open.resize(cap)
		candles.high.resize(cap)
		candles.low.resize(cap)
		candles.close.resize(cap)
		tiers.append({"line": line, "candles": candles})
	_series[id] = {"tiers": tiers}
	emit_signal("series_registered", id)

func add_sample(id: StringName, t_minute: int, value: float) -> void:
	if not _series.has(id):
		register_series(id)
	var tiers: Array = _series[id].tiers
	_line_push(tiers[0].line, 0, t_minute, value)
	_candle_update(tiers[0].candles, 0, t_minute, value)
	for i in range(1, TIER_CONFIG.size()):
		var prev_line: Dictionary = tiers[i - 1].line
		var next_line: Dictionary = tiers[i].line
		var next_candles: Dictionary = tiers[i].candles
		var last_prev_time: int = _line_last_time(prev_line)
		if last_prev_time == -2147483648:
			break
		var last_next_time: int = _line_last_time(next_line)
		var need_push: bool = false
		if last_next_time == -2147483648:
			need_push = true
		elif last_prev_time - last_next_time >= int(TIER_CONFIG[i].dt):
			need_push = true
		if need_push:
			var last_prev_value: float = _line_last_value(prev_line)
			_line_push(next_line, i, last_prev_time, last_prev_value)
			_candle_update(next_candles, i, last_prev_time, last_prev_value)
	emit_signal("series_sampled", id, t_minute)

func get_series_window_line(id: StringName, t_start_min: int, t_end_min: int, max_points: int = 1024) -> PackedVector2Array:
	if not _series.has(id):
		return PackedVector2Array()
	if t_end_min <= t_start_min:
		return PackedVector2Array()
	var window_len: int = t_end_min - t_start_min
	var tier_index: int = 0
	for i in range(TIER_CONFIG.size()):
		var approx: int = window_len / int(TIER_CONFIG[i].dt)
		if approx <= max_points or i == TIER_CONFIG.size() - 1:
			tier_index = i
			break
	var line: Dictionary = _series[id].tiers[tier_index].line
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(line.size):
		var idx: int = (line.head + i) % line.capacity
		var t: int = line.times[idx]
		if t < t_start_min:
			continue
		if t > t_end_min:
			break
		out.append(Vector2(float(t), line.values[idx]))
	if out.size() > max_points:
		var stride: int = int(ceil(float(out.size()) / float(max_points)))
		var thinned: PackedVector2Array = PackedVector2Array()
		for j in range(0, out.size(), stride):
			thinned.append(out[j])
		out = thinned
	return out

func get_series_window_candles(id: StringName, t_start_min: int, t_end_min: int, max_candles: int = 512) -> Array[Dictionary]:
	if not _series.has(id):
		return []
	if t_end_min <= t_start_min:
		return []
	var window_len: int = t_end_min - t_start_min
	var tier_index: int = 0
	for i in range(TIER_CONFIG.size()):
		var approx: int = window_len / int(TIER_CONFIG[i].dt)
		if approx <= max_candles or i == TIER_CONFIG.size() - 1:
			tier_index = i
			break
	var candles: Dictionary = _series[id].tiers[tier_index].candles
	var out: Array[Dictionary] = []
	for i in range(candles.size):
		var idx: int = (candles.head + i) % candles.capacity
		var t_open: int = candles.t_open[idx]
		if t_open < t_start_min:
			continue
		if t_open > t_end_min:
			break
		var d: Dictionary = {
			"t_open": t_open,
			"t_close": candles.t_close[idx],
			"open": candles.open[idx],
			"high": candles.high[idx],
			"low": candles.low[idx],
			"close": candles.close[idx]
		}
		out.append(d)
	if out.size() > max_candles:
		var stride: int = int(ceil(float(out.size()) / float(max_candles)))
		var thinned: Array[Dictionary] = []
		for j in range(0, out.size(), stride):
			thinned.append(out[j])
		out = thinned
	return out

func newest_timestamp(id: StringName) -> int:
	if not _series.has(id):
		return -2147483648
	return _line_last_time(_series[id].tiers[0].line)

# ---------- Internal ring-buffer helpers ----------

func _line_push(line: Dictionary, tier_index: int, t: int, value: float) -> void:
	var idx: int = (line.head + line.size) % line.capacity
	if line.size < line.capacity:
		line.times[idx] = t
		line.values[idx] = value
		line.size += 1
	else:
		line.times[line.head] = t
		line.values[line.head] = value
		line.head = (line.head + 1) % line.capacity
	_line_prune(line, tier_index, t)

func _line_prune(line: Dictionary, tier_index: int, current_t: int) -> void:
	var horizon: int = int(TIER_CONFIG[tier_index].horizon)
	while line.size > 0:
		var oldest: int = line.times[line.head]
		if current_t - oldest > horizon:
			line.head = (line.head + 1) % line.capacity
			line.size -= 1
		else:
			break

func _line_last_time(line: Dictionary) -> int:
	if line.size == 0:
		return -2147483648
	var idx: int = (line.head + line.size - 1) % line.capacity
	return line.times[idx]

func _line_last_value(line: Dictionary) -> float:
	if line.size == 0:
		return 0.0
	var idx: int = (line.head + line.size - 1) % line.capacity
	return line.values[idx]

func _candle_update(candles: Dictionary, tier_index: int, t: int, value: float) -> void:
	var dt: int = int(TIER_CONFIG[tier_index].dt)
	var bucket_start: int = (t / dt) * dt
	var bucket_end: int = bucket_start + dt
	if candles.size == 0:
		_candle_push(candles, tier_index, bucket_start, bucket_end, value, value, value, value)
		return
	var last_idx: int = (candles.head + candles.size - 1) % candles.capacity
	var last_open: int = candles.t_open[last_idx]
	if bucket_start == last_open:
		candles.t_close[last_idx] = bucket_end
		candles.close[last_idx] = value
		if value > candles.high[last_idx]:
			candles.high[last_idx] = value
		if value < candles.low[last_idx]:
			candles.low[last_idx] = value
		_candle_prune(candles, tier_index, t)
	elif bucket_start > last_open:
		_candle_push(candles, tier_index, bucket_start, bucket_end, value, value, value, value)

func _candle_push(candles: Dictionary, tier_index: int, t_open: int, t_close: int, open: float, high: float, low: float, close: float) -> void:
	var idx: int = (candles.head + candles.size) % candles.capacity
	if candles.size < candles.capacity:
		candles.t_open[idx] = t_open
		candles.t_close[idx] = t_close
		candles.open[idx] = open
		candles.high[idx] = high
		candles.low[idx] = low
		candles.close[idx] = close
		candles.size += 1
	else:
		candles.t_open[candles.head] = t_open
		candles.t_close[candles.head] = t_close
		candles.open[candles.head] = open
		candles.high[candles.head] = high
		candles.low[candles.head] = low
		candles.close[candles.head] = close
		candles.head = (candles.head + 1) % candles.capacity
	_candle_prune(candles, tier_index, t_open)

func _candle_prune(candles: Dictionary, tier_index: int, current_t: int) -> void:
	var horizon: int = int(TIER_CONFIG[tier_index].horizon)
	while candles.size > 0:
		var oldest_close: int = candles.t_close[candles.head]
		if current_t - oldest_close > horizon:
			candles.head = (candles.head + 1) % candles.capacity
			candles.size -= 1
		else:
			break
