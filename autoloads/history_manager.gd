extends Node
# Autoload: HistoryManager

const DEBUG_HISTORY := false

signal series_registered(id: StringName)
signal series_sampled(id: StringName, t_minute: int)

# -------------------- NEW: persistence config --------------------
@export var persist_to_disk: bool = true
@export var persist_path: String = "user://history.dat"
@export var persist_every_minutes: int = 10

const HISTORY_FILE_VERSION := 1

var _minutes_since_persist: int = 0
# ---------------------------------------------------------------

# All dt/horizon values are in MINUTES.
const TIER_CONFIG := [
	{"dt": 1, "horizon": 60, "capacity": 2048},          # 1h @ 1-min
	{"dt": 5, "horizon": 24 * 60, "capacity": 2048},      # 1d @ 5-min
	{"dt": 60, "horizon": 14 * 24 * 60, "capacity": 2048} # 14d @ 1-hr
]

var _series: Dictionary = {} # id -> {"tiers":[{"line":{...},"candles":{...}}, ...]}

func _ready() -> void:
	# Try loading persistent history first
	if persist_to_disk:
		_load_from_disk_safe()
	# Keep a live minute ticker to auto-save
	if Engine.has_singleton("TimeManager"):
		var tm = Engine.get_singleton("TimeManager")
		if tm and tm.has_signal("minute_passed"):
			tm.minute_passed.connect(_on_minute_tick)

# --- persistence: autosave driver ---
func _on_minute_tick(_mins_since_midnight: int) -> void:
		if not persist_to_disk:
				return
		_minutes_since_persist += 1
		if _minutes_since_persist >= max(1, persist_every_minutes):
				_minutes_since_persist = 0
				_save_to_disk_safe()



# -------------------- PUBLIC API --------------------

func reset() -> void:
	_series.clear()
	_minutes_since_persist = 0
	if persist_to_disk and FileAccess.file_exists(persist_path):
		DirAccess.remove_absolute(persist_path)


func register_series(id: StringName) -> void:
	if _series.has(id):
		return

	var tiers: Array = []
	for cfg in TIER_CONFIG:
		var cap: int = int(cfg.capacity)

		var line: Dictionary = {
			"times": PackedInt32Array(),
			"values": PackedFloat32Array(),
			"head": 0,
			"size": 0,
			"capacity": cap
		}
		var lt: PackedInt32Array = line["times"]
		var lv: PackedFloat32Array = line["values"]
		lt.resize(cap)
		lv.resize(cap)
		line["times"] = lt
		line["values"] = lv

		var candles: Dictionary = {
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
		var c_to: PackedInt32Array = candles["t_open"]
		var c_tc: PackedInt32Array = candles["t_close"]
		var c_o: PackedFloat32Array = candles["open"]
		var c_h: PackedFloat32Array = candles["high"]
		var c_l: PackedFloat32Array = candles["low"]
		var c_c: PackedFloat32Array = candles["close"]
		c_to.resize(cap); c_tc.resize(cap); c_o.resize(cap)
		c_h.resize(cap); c_l.resize(cap); c_c.resize(cap)
		candles["t_open"] = c_to
		candles["t_close"] = c_tc
		candles["open"] = c_o
		candles["high"] = c_h
		candles["low"] = c_l
		candles["close"] = c_c

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

	var line: Dictionary = _series[id]["tiers"][tier_index]["line"]
	var out: PackedVector2Array = PackedVector2Array()

	var head: int = int(line["head"])
	var size_i: int = int(line["size"])
	var cap_i: int = int(line["capacity"])
	var times: PackedInt32Array = line["times"]
	var values: PackedFloat32Array = line["values"]

	for i in range(size_i):
		var idx: int = (head + i) % cap_i
		var t_i: int = times[idx]
		if t_i < t_start_min:
			continue
		if t_i > t_end_min:
			break
		out.append(Vector2(float(t_i), values[idx]))

		if out.size() > max_points:
			var stride: int = int(ceil(float(out.size()) / float(max_points)))
			var thinned: PackedVector2Array = PackedVector2Array()
			for j in range(0, out.size(), stride):
				thinned.append(out[j])
			if thinned.is_empty() or thinned[thinned.size() - 1].x != out[out.size() - 1].x:
				thinned.append(out[out.size() - 1])
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

	var candles: Dictionary = _series[id]["tiers"][tier_index]["candles"]
	var out: Array[Dictionary] = []

	var head: int = int(candles["head"])
	var size_i: int = int(candles["size"])
	var cap_i: int = int(candles["capacity"])

	var t_open: PackedInt32Array = candles["t_open"]
	var t_close: PackedInt32Array = candles["t_close"]
	var open: PackedFloat32Array = candles["open"]
	var high: PackedFloat32Array = candles["high"]
	var low: PackedFloat32Array = candles["low"]
	var close: PackedFloat32Array = candles["close"]

	for i in range(size_i):
		var idx: int = (head + i) % cap_i
		var o_t: int = t_open[idx]
		if o_t < t_start_min:
			continue
		if o_t > t_end_min:
			break
		var d: Dictionary = {
			"t_open": o_t,
			"t_close": t_close[idx],
			"open": open[idx],
			"high": high[idx],
			"low": low[idx],
			"close": close[idx]
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
	var cap_i: int = int(line["capacity"])
	var head: int = int(line["head"])
	var size_i: int = int(line["size"])

	var times: PackedInt32Array = line["times"]
	var values: PackedFloat32Array = line["values"]

	var idx: int = (head + size_i) % cap_i
	if size_i < cap_i:
		times[idx] = t
		values[idx] = value
		size_i += 1
	else:
		times[head] = t
		values[head] = value
		head = (head + 1) % cap_i

	line["times"] = times
	line["values"] = values
	line["head"] = head
	line["size"] = size_i

	_line_prune(line, tier_index, t)


func _line_prune(line: Dictionary, tier_index: int, current_t: int) -> void:
	var cap_i: int = int(line["capacity"])
	var head: int = int(line["head"])
	var size_i: int = int(line["size"])
	var times: PackedInt32Array = line["times"]

	var horizon: int = int(TIER_CONFIG[tier_index].horizon)
	while size_i > 0:
		var oldest: int = times[head]
		if current_t - oldest > horizon:
			head = (head + 1) % cap_i
			size_i -= 1
		else:
			break

	line["head"] = head
	line["size"] = size_i


func _line_last_time(line: Dictionary) -> int:
	var size_i: int = int(line["size"])
	if size_i == 0:
		return -2147483648
	var head: int = int(line["head"])
	var cap_i: int = int(line["capacity"])
	var times: PackedInt32Array = line["times"]
	var idx: int = (head + size_i - 1) % cap_i
	return times[idx]


func _line_last_value(line: Dictionary) -> float:
	var size_i: int = int(line["size"])
	if size_i == 0:
		return 0.0
	var head: int = int(line["head"])
	var cap_i: int = int(line["capacity"])
	var values: PackedFloat32Array = line["values"]
	var idx: int = (head + size_i - 1) % cap_i
	return values[idx]

func _candle_update(candles: Dictionary, tier_index: int, t: int, value: float) -> void:
	var dt: int = int(TIER_CONFIG[tier_index].dt)
	var bucket_start: int = (t / dt) * dt
	var bucket_end: int = bucket_start + dt

	var size_i: int = int(candles["size"])
	if size_i == 0:
		_candle_push(candles, tier_index, bucket_start, bucket_end, value, value, value, value)
		return

	var head: int = int(candles["head"])
	var cap_i: int = int(candles["capacity"])

	var t_open: PackedInt32Array = candles["t_open"]
	var t_close: PackedInt32Array = candles["t_close"]
	var open: PackedFloat32Array = candles["open"]
	var high: PackedFloat32Array = candles["high"]
	var low: PackedFloat32Array = candles["low"]
	var close: PackedFloat32Array = candles["close"]

	var last_idx: int = (head + size_i - 1) % cap_i
	var last_open: int = t_open[last_idx]

	if bucket_start == last_open:
		t_close[last_idx] = bucket_end
		close[last_idx] = value
		if value > high[last_idx]:
			high[last_idx] = value
		if value < low[last_idx]:
			low[last_idx] = value

		candles["t_close"] = t_close
		candles["high"] = high
		candles["low"] = low
		candles["close"] = close

		_candle_prune(candles, tier_index, t)
	elif bucket_start > last_open:
		_candle_push(candles, tier_index, bucket_start, bucket_end, value, value, value, value)


func _candle_push(candles: Dictionary, tier_index: int, t_open_v: int, t_close_v: int, open_v: float, high_v: float, low_v: float, close_v: float) -> void:
	var cap_i: int = int(candles["capacity"])
	var head: int = int(candles["head"])
	var size_i: int = int(candles["size"])

	var t_open: PackedInt32Array = candles["t_open"]
	var t_close: PackedInt32Array = candles["t_close"]
	var open: PackedFloat32Array = candles["open"]
	var high: PackedFloat32Array = candles["high"]
	var low: PackedFloat32Array = candles["low"]
	var close: PackedFloat32Array = candles["close"]

	var idx: int = (head + size_i) % cap_i
	if size_i < cap_i:
		t_open[idx] = t_open_v
		t_close[idx] = t_close_v
		open[idx] = open_v
		high[idx] = high_v
		low[idx] = low_v
		close[idx] = close_v
		size_i += 1
	else:
		t_open[head] = t_open_v
		t_close[head] = t_close_v
		open[head] = open_v
		high[head] = high_v
		low[head] = low_v
		close[head] = close_v
		head = (head + 1) % cap_i

	candles["t_open"] = t_open
	candles["t_close"] = t_close
	candles["open"] = open
	candles["high"] = high
	candles["low"] = low
	candles["close"] = close
	candles["head"] = head
	candles["size"] = size_i

	_candle_prune(candles, tier_index, t_open_v)


func _candle_prune(candles: Dictionary, tier_index: int, current_t: int) -> void:
	var cap_i: int = int(candles["capacity"])
	var head: int = int(candles["head"])
	var size_i: int = int(candles["size"])
	var t_close: PackedInt32Array = candles["t_close"]

	var horizon: int = int(TIER_CONFIG[tier_index].horizon)
	while size_i > 0:
		var oldest_close: int = t_close[head]
		if current_t - oldest_close > horizon:
			head = (head + 1) % cap_i
			size_i -= 1
		else:
			break

	candles["head"] = head
	candles["size"] = size_i

func get_latest_point(id: StringName) -> Vector2:
	if not _series.has(id):
		return Vector2(-INF, 0.0)
	var line: Dictionary = _series[id]["tiers"][0]["line"]
	var size_i: int = int(line["size"])
	if size_i == 0:
		return Vector2(-INF, 0.0)

	var head: int = int(line["head"])
	var cap_i: int = int(line["capacity"])
	var times: PackedInt32Array = line["times"]
	var values: PackedFloat32Array = line["values"]

	var idx: int = (head + size_i - 1) % cap_i
	return Vector2(float(times[idx]), values[idx])


# Returns { "found": bool, "t": int, "v": float } for the finest tier (tier 0).
func get_value_at_or_before(id: StringName, t_minute: int) -> Dictionary:
	var res: Dictionary = {"found": false, "t": -2147483648, "v": 0.0}
	if not _series.has(id):
		return res
	var line: Dictionary = _series[id]["tiers"][0]["line"]
	var size_i: int = int(line["size"])
	if size_i == 0:
		return res

	var head: int = int(line["head"])
	var cap_i: int = int(line["capacity"])
	var times: PackedInt32Array = line["times"]
	var values: PackedFloat32Array = line["values"]

	# Walk from newest backwards until <= t_minute (capacity is small; O(n) is fine)
	for i in range(size_i - 1, -1, -1):
		var idx: int = (head + i) % cap_i
		var t_i: int = times[idx]
		if t_i <= t_minute:
			res["found"] = true
			res["t"] = t_i
			res["v"] = values[idx]
			if DEBUG_HISTORY:
				print("get_value_at_or_before %s t=%d -> idx=%d t_i=%d v=%f" % [id, t_minute, idx, t_i, values[idx]])
			return res
	return res

func get_first_value_in_or_after(id: StringName, t_minute: int) -> Dictionary:
	var res: Dictionary = {"found": false, "t": -2147483648, "v": 0.0}
	if not _series.has(id):
		return res
	var line: Dictionary = _series[id]["tiers"][0]["line"]
	var size_i: int = int(line["size"])
	if size_i == 0:
		return res
	var head: int = int(line["head"])
	var cap_i: int = int(line["capacity"])
	var times: PackedInt32Array = line["times"]
	var values: PackedFloat32Array = line["values"]
	for i in range(size_i):
		var idx: int = (head + i) % cap_i
		var t_i: int = times[idx]
		if t_i >= t_minute:
			res["found"] = true
			res["t"] = t_i
			res["v"] = values[idx]
			if DEBUG_HISTORY:
					print("get_first_value_in_or_after %s t=%d -> idx=%d t_i=%d v=%f" % [id, t_minute, idx, t_i, values[idx]])
			return res
	return res



# -------------------- SAVE-SLOT API (for SaveManager) ----------
func get_save_data() -> Dictionary:
	var out: Dictionary = {"v": HISTORY_FILE_VERSION, "series": {}}
	for id in _series.keys():
		var tiers: Array = _series[id]["tiers"]
		var tiers_out: Array[Dictionary] = []
		for i in range(tiers.size()):
			var line: Dictionary = tiers[i]["line"]
			var candles: Dictionary = tiers[i]["candles"]
			var line_export: Dictionary = _export_line(line)
			var candle_export: Dictionary = _export_candles(candles)
			tiers_out.append({
				"line": line_export,
				"candles": candle_export
			})
		out["series"][String(id)] = {"tiers": tiers_out}
	return out

func load_from_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	var version: int = int(data.get("v", 0))
	var ser: Dictionary = data.get("series", {})
	_series.clear()
	for key in ser.keys():
		var id: StringName = StringName(key)
		var tiers_in: Array = ser[key].get("tiers", [])
		var built_tiers: Array[Dictionary] = []
		var limit: int = min(tiers_in.size(), TIER_CONFIG.size())
		for i in range(limit):
			var cfg: Dictionary = TIER_CONFIG[i]
			var cap: int = int(cfg["capacity"])
			var line: Dictionary = _make_empty_line(cap)
			var candles: Dictionary = _make_empty_candles(cap)
			_import_line(line, tiers_in[i].get("line", {}), i)
			_import_candles(candles, tiers_in[i].get("candles", {}), i)
			built_tiers.append({"line": line, "candles": candles})
		_series[id] = {"tiers": built_tiers}
	# Tell listeners that history is present (optional)
	emit_signal("series_registered", StringName("**reload**"))

# -------------------- DISK API (binary, compact) ----------------
func save_to_disk(path: String = persist_path) -> void:
	var dict: Dictionary = get_save_data()
	var bytes: PackedByteArray = var_to_bytes(dict)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_buffer(bytes)
		f.close()

func load_from_disk(path: String = persist_path) -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var bytes: PackedByteArray = f.get_buffer(f.get_length())
	f.close()
	var dict: Variant = bytes_to_var(bytes)
	if dict is Dictionary:
		load_from_data(dict)

# Safe wrappers (temp + swap)
func _save_to_disk_safe() -> void:
	if not persist_to_disk:
		return
	var path: String = persist_path
	var tmp: String = path + ".tmp"
	var dict: Dictionary = get_save_data()
	var bytes: PackedByteArray = var_to_bytes(dict)

	var f_tmp := FileAccess.open(tmp, FileAccess.WRITE)
	if f_tmp:
		f_tmp.store_buffer(bytes)
		f_tmp.close()
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		DirAccess.rename_absolute(tmp, path)

func _load_from_disk_safe() -> void:
	if not persist_to_disk:
		return
	if not FileAccess.file_exists(persist_path):
		return
	load_from_disk(persist_path)

# -------------- helpers: build/flatten ring buffers ------------
func _make_empty_line(cap: int) -> Dictionary:
        var line: Dictionary = {
                "times": PackedInt32Array(),
                "values": PackedFloat32Array(),
                "head": 0, "size": 0, "capacity": cap
        }

        var times: PackedInt32Array = line["times"]
        var values: PackedFloat32Array = line["values"]
        times.resize(cap)
        values.resize(cap)
        line["times"] = times
        line["values"] = values
        return line

func _make_empty_candles(cap: int) -> Dictionary:
        var c: Dictionary = {
                "t_open": PackedInt32Array(),
                "t_close": PackedInt32Array(),
                "open": PackedFloat32Array(),
                "high": PackedFloat32Array(),
                "low": PackedFloat32Array(),
                "close": PackedFloat32Array(),
                "head": 0, "size": 0, "capacity": cap
        }

        var t_open: PackedInt32Array = c["t_open"]
        var t_close: PackedInt32Array = c["t_close"]
        var open: PackedFloat32Array = c["open"]
        var high: PackedFloat32Array = c["high"]
        var low: PackedFloat32Array = c["low"]
        var close: PackedFloat32Array = c["close"]
        t_open.resize(cap)
        t_close.resize(cap)
        open.resize(cap)
        high.resize(cap)
        low.resize(cap)
        close.resize(cap)
        c["t_open"] = t_open
        c["t_close"] = t_close
        c["open"] = open
        c["high"] = high
        c["low"] = low
        c["close"] = close
        return c

func _export_line(line: Dictionary) -> Dictionary:
	var size_i: int = int(line["size"])
	var out_times: PackedInt32Array = PackedInt32Array()
	var out_vals: PackedFloat32Array = PackedFloat32Array()
	out_times.resize(size_i)
	out_vals.resize(size_i)

	var head: int = int(line["head"])
	var cap_i: int = int(line["capacity"])
	var times: PackedInt32Array = line["times"]
	var values: PackedFloat32Array = line["values"]

	for i in range(size_i):
		var idx: int = (head + i) % cap_i
		out_times[i] = times[idx]
		out_vals[i] = values[idx]
	return {"times": out_times, "values": out_vals}

func _import_line(line: Dictionary, src: Dictionary, tier_index: int) -> void:
	var times: PackedInt32Array = src.get("times", PackedInt32Array())
	var vals: PackedFloat32Array = src.get("values", PackedFloat32Array())
	var n: int = min(times.size(), vals.size())
	line["head"] = 0
	line["size"] = 0
	for i in range(n):
		_line_push(line, tier_index, times[i], vals[i])

func _export_candles(c: Dictionary) -> Dictionary:
	var n: int = int(c["size"])
	var t_open: PackedInt32Array = PackedInt32Array()
	var t_close: PackedInt32Array = PackedInt32Array()
	var open: PackedFloat32Array = PackedFloat32Array()
	var high: PackedFloat32Array = PackedFloat32Array()
	var low: PackedFloat32Array = PackedFloat32Array()
	var close: PackedFloat32Array = PackedFloat32Array()
	t_open.resize(n); t_close.resize(n); open.resize(n)
	high.resize(n); low.resize(n); close.resize(n)

	var head: int = int(c["head"])
	var cap_i: int = int(c["capacity"])
	var c_t_open: PackedInt32Array = c["t_open"]
	var c_t_close: PackedInt32Array = c["t_close"]
	var c_open: PackedFloat32Array = c["open"]
	var c_high: PackedFloat32Array = c["high"]
	var c_low: PackedFloat32Array = c["low"]
	var c_close: PackedFloat32Array = c["close"]

	for i in range(n):
		var idx: int = (head + i) % cap_i
		t_open[i] = c_t_open[idx]
		t_close[i] = c_t_close[idx]
		open[i] = c_open[idx]
		high[i] = c_high[idx]
		low[i] = c_low[idx]
		close[i] = c_close[idx]
	return {
		"t_open": t_open, "t_close": t_close,
		"open": open, "high": high, "low": low, "close": close
	}

func _import_candles(c: Dictionary, src: Dictionary, tier_index: int) -> void:
	var t_open: PackedInt32Array = src.get("t_open", PackedInt32Array())
	var t_close: PackedInt32Array = src.get("t_close", PackedInt32Array())
	var open: PackedFloat32Array = src.get("open", PackedFloat32Array())
	var high: PackedFloat32Array = src.get("high", PackedFloat32Array())
	var low: PackedFloat32Array = src.get("low", PackedFloat32Array())
	var close: PackedFloat32Array = src.get("close", PackedFloat32Array())

	var n: int = min(
		min(t_open.size(), t_close.size()),
		min(open.size(), high.size(), low.size(), close.size())
	)

	c["head"] = 0
	c["size"] = 0
	for i in range(n):
		_candle_push(c, tier_index, t_open[i], t_close[i], open[i], high[i], low[i], close[i])
