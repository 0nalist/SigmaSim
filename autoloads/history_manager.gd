extends Node

signal series_registered(id: StringName)
signal series_sampled(id: StringName, t: float)

const TIER_CONFIG := [
	{"dt": 0.1, "horizon": 30.0, "capacity": 512},
	{"dt": 1.0, "horizon": 300.0, "capacity": 512},
	{"dt": 10.0, "horizon": 3600.0, "capacity": 512},
]

var _series: Dictionary = {}

func register_series(id: StringName) -> void:
	if _series.has(id):
		return
	var data := {
		"tiers": []
	}
	for cfg in TIER_CONFIG:
		var line := {
			"times": PackedFloat32Array(),
			"values": PackedFloat32Array(),
			"head": 0,
			"size": 0,
			"capacity": int(cfg.capacity),
		}
		line.times.resize(line.capacity)
		line.values.resize(line.capacity)
		var candles := {
			"t_open": PackedFloat32Array(),
			"t_close": PackedFloat32Array(),
			"open": PackedFloat32Array(),
			"high": PackedFloat32Array(),
			"low": PackedFloat32Array(),
			"close": PackedFloat32Array(),
			"head": 0,
			"size": 0,
			"capacity": int(cfg.capacity),
		}
		candles.t_open.resize(candles.capacity)
		candles.t_close.resize(candles.capacity)
		candles.open.resize(candles.capacity)
		candles.high.resize(candles.capacity)
		candles.low.resize(candles.capacity)
		candles.close.resize(candles.capacity)
		data.tiers.append({
			"line": line,
			"candles": candles,
		})
	_series[id] = data
	emit_signal("series_registered", id)

func add_sample(id: StringName, t_seconds: float, value: float) -> void:
	if not _series.has(id):
		register_series(id)
	var tiers = _series[id].tiers
	_line_push(tiers[0].line, 0, t_seconds, value)
	_candle_update(tiers[0].candles, 0, t_seconds, value)
	for i in range(1, TIER_CONFIG.size()):
		var prev_line = tiers[i - 1].line
		var next_line = tiers[i].line
		var next_candles = tiers[i].candles
		var last_prev_time = _line_last_time(prev_line)
		var last_prev_value = _line_last_value(prev_line)
		var last_next_time = _line_last_time(next_line)
		if last_prev_time - last_next_time >= TIER_CONFIG[i].dt:
			_line_push(next_line, i, last_prev_time, last_prev_value)
			_candle_update(next_candles, i, last_prev_time, last_prev_value)
		else:
			break
	emit_signal("series_sampled", id, t_seconds)

func get_series_window_line(id: StringName, t_start: float, t_end: float, max_points: int = 1024) -> PackedVector2Array:
	if not _series.has(id):
		return PackedVector2Array()
	var window_len = t_end - t_start
	var tier_index = 0
	for i in range(TIER_CONFIG.size()):
		var approx = window_len / TIER_CONFIG[i].dt
		if approx <= max_points or i == TIER_CONFIG.size() - 1:
			tier_index = i
			break
	var line = _series[id].tiers[tier_index].line
	var out := PackedVector2Array()
	for i in range(line.size):
		var idx = (line.head + i) % line.capacity
		var t = line.times[idx]
		if t < t_start:
			continue
		if t > t_end:
			break
		out.append(Vector2(t, line.values[idx]))
	if out.size() > max_points:
		var stride = ceili(float(out.size()) / float(max_points))
		var thinned := PackedVector2Array()
		for j in range(0, out.size(), stride):
			thinned.append(out[j])
		out = thinned
	return out

func get_series_window_candles(id: StringName, t_start: float, t_end: float, max_candles: int = 512) -> Array[Dictionary]:
	if not _series.has(id):
		return []
	var window_len = t_end - t_start
	var tier_index = 0
	for i in range(TIER_CONFIG.size()):
		var approx = window_len / TIER_CONFIG[i].dt
		if approx <= max_candles or i == TIER_CONFIG.size() - 1:
			tier_index = i
			break
	var candles = _series[id].tiers[tier_index].candles
	var out: Array = []
	for i in range(candles.size):
		var idx = (candles.head + i) % candles.capacity
		var t_open = candles.t_open[idx]
		if t_open < t_start:
			continue
		if t_open > t_end:
			break
		var d := {
			"t_open": t_open,
			"t_close": candles.t_close[idx],
			"open": candles.open[idx],
			"high": candles.high[idx],
			"low": candles.low[idx],
			"close": candles.close[idx],
		}
		out.append(d)
	if out.size() > max_candles:
		var stride = ceili(float(out.size()) / float(max_candles))
		var thinned: Array = []
		for j in range(0, out.size(), stride):
			thinned.append(out[j])
		out = thinned
	return out

func newest_timestamp(id: StringName) -> float:
	if not _series.has(id):
		return -INF
	return _line_last_time(_series[id].tiers[0].line)

func _line_push(line: Dictionary, tier_index: int, t: float, value: float) -> void:
	var idx = (line.head + line.size) % line.capacity
	if line.size < line.capacity:
		line.times[idx] = t
		line.values[idx] = value
		line.size += 1
	else:
		line.times[line.head] = t
		line.values[line.head] = value
		line.head = (line.head + 1) % line.capacity
	_line_prune(line, tier_index, t)

func _line_prune(line: Dictionary, tier_index: int, current_t: float) -> void:
	var horizon = TIER_CONFIG[tier_index].horizon
	while line.size > 0:
		var oldest = line.times[line.head]
		if current_t - oldest > horizon:
			line.head = (line.head + 1) % line.capacity
			line.size -= 1
		else:
			break

func _line_last_time(line: Dictionary) -> float:
	if line.size == 0:
		return -INF
	var idx = (line.head + line.size - 1) % line.capacity
	return line.times[idx]

func _line_last_value(line: Dictionary) -> float:
	if line.size == 0:
		return 0.0
	var idx = (line.head + line.size - 1) % line.capacity
	return line.values[idx]

func _candle_update(candles: Dictionary, tier_index: int, t: float, value: float) -> void:
	var dt = TIER_CONFIG[tier_index].dt
	var bucket_start = floor(t / dt) * dt
	var bucket_end = bucket_start + dt
	if candles.size == 0:
		_candle_push(candles, tier_index, bucket_start, bucket_end, value, value, value, value)
		return
	var last_idx = (candles.head + candles.size - 1) % candles.capacity
	var last_open = candles.t_open[last_idx]
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
	# else: ignore out-of-order sample

func _candle_push(candles: Dictionary, tier_index: int, t_open: float, t_close: float, open: float, high: float, low: float, close: float) -> void:
	var idx = (candles.head + candles.size) % candles.capacity
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

func _candle_prune(candles: Dictionary, tier_index: int, current_t: float) -> void:
	var horizon = TIER_CONFIG[tier_index].horizon
	while candles.size > 0:
		var oldest = candles.t_close[candles.head]
		if current_t - oldest > horizon:
			candles.head = (candles.head + 1) % candles.capacity
			candles.size -= 1
		else:
			break
