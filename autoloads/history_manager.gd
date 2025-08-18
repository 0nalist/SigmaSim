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
        data.tiers.append(line)
    _series[id] = data
    emit_signal("series_registered", id)

func add_sample(id: StringName, t_seconds: float, value: float) -> void:
    if not _series.has(id):
        register_series(id)
    var tiers = _series[id].tiers
    _line_push(tiers[0], 0, t_seconds, value)
    for i in range(1, TIER_CONFIG.size()):
        var prev_line = tiers[i - 1]
        var next_line = tiers[i]
        var last_prev_time = _line_last_time(prev_line)
        var last_prev_value = _line_last_value(prev_line)
        var last_next_time = _line_last_time(next_line)
        if last_prev_time - last_next_time >= TIER_CONFIG[i].dt:
            _line_push(next_line, i, last_prev_time, last_prev_value)
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
    var line = _series[id].tiers[tier_index]
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
