extends Resource
class_name MarketEvent

# Target asset symbol and type ("stock" or "crypto")
@export var target_symbol: String = ""
@export var target_type: String = "crypto"

# Randomized start delay in minutes relative to schedule() call
@export var start_min_minutes: int = 0
@export var start_max_minutes: int = 0

# Pump phase configuration
@export var pump_duration_min: int = 0
@export var pump_duration_max: int = 0
@export var pump_multiplier_min: float = 1.0
@export var pump_multiplier_max: float = 1.0

# Dump phase configuration
@export var dump_duration_min: int = 0
@export var dump_duration_max: int = 0
@export var dump_multiplier_min: float = 1.0
@export var dump_multiplier_max: float = 1.0

# Internal state
var _start_time: int = -1
var _pump_end_time: int = -1
var _dump_end_time: int = -1
var _starting_price: float = 0.0
var _pump_multiplier: float = 1.0
var _dump_multiplier: float = 1.0

enum State { PENDING, PUMPING, DUMPING, FINISHED }
var _state: State = State.PENDING

# Schedule the event using current time and RNG for randomness
func schedule(now_minutes: int, rng: RandomNumberGenerator) -> void:
    var start_delay = rng.randi_range(start_min_minutes, start_max_minutes)
    _start_time = now_minutes + start_delay
    var pump_duration = rng.randi_range(pump_duration_min, pump_duration_max)
    var dump_duration = rng.randi_range(dump_duration_min, dump_duration_max)
    _pump_end_time = _start_time + pump_duration
    _dump_end_time = _pump_end_time + dump_duration
    _pump_multiplier = rng.randf_range(pump_multiplier_min, pump_multiplier_max)
    _dump_multiplier = rng.randf_range(dump_multiplier_min, dump_multiplier_max)
    _state = State.PENDING

func is_active() -> bool:
    return _state == State.PUMPING or _state == State.DUMPING

func is_finished() -> bool:
    return _state == State.FINISHED

# Process the event, updating the asset price if necessary
func process(now_minutes: int, asset) -> void:
    if _state == State.FINISHED:
        return

    if _state == State.PENDING and now_minutes >= _start_time:
        _state = State.PUMPING
        _starting_price = asset.price

    if _state == State.PUMPING:
        var target_price = _starting_price * _pump_multiplier
        var t = float(now_minutes - _start_time) / max(1.0, float(_pump_end_time - _start_time))
        t = clamp(t, 0.0, 1.0)
        var new_price = lerp(_starting_price, target_price, t)
        var prev = asset.price
        asset.price = new_price
        asset.last_price = prev
        if asset.price_history.size() > 0:
            asset.price_history[asset.price_history.size() - 1] = asset.price
        else:
            asset.price_history.append(asset.price)
        asset.all_time_high = max(asset.all_time_high, asset.price)
        if now_minutes >= _pump_end_time:
            _state = State.DUMPING

    elif _state == State.DUMPING:
        var pump_price = _starting_price * _pump_multiplier
        var target_price = _starting_price * _dump_multiplier
        var t = float(now_minutes - _pump_end_time) / max(1.0, float(_dump_end_time - _pump_end_time))
        t = clamp(t, 0.0, 1.0)
        var new_price = lerp(pump_price, target_price, t)
        var prev = asset.price
        asset.price = new_price
        asset.last_price = prev
        if asset.price_history.size() > 0:
            asset.price_history[asset.price_history.size() - 1] = asset.price
        else:
            asset.price_history.append(asset.price)
        asset.all_time_high = max(asset.all_time_high, asset.price)
        if now_minutes >= _dump_end_time:
            _state = State.FINISHED
