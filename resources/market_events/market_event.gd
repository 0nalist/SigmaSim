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

# Log current market prices for debugging
func _print_market_snapshot(label: String) -> void:
	var stock_parts: Array = []
	for s in MarketManager.stock_market.values():
		stock_parts.append("%s:%.2f" % [s.symbol, s.price])
	var crypto_parts: Array = []
	for c in MarketManager.crypto_market.values():
		crypto_parts.append("%s:%.2f" % [c.symbol, c.price])
	print("market snapshot " + label + ": stocks=" + ", ".join(stock_parts) + " cryptos=" + ", ".join(crypto_parts))


# Schedule the event using current time and RNG for randomness
func schedule(now_minutes: int, rng: RandomNumberGenerator) -> void:
	var start_delay: int = rng.randi_range(start_min_minutes, start_max_minutes)
	_start_time = now_minutes + start_delay
	var pump_duration: int = rng.randi_range(pump_duration_min, pump_duration_max)
	var dump_duration: int = rng.randi_range(dump_duration_min, dump_duration_max)
	_pump_end_time = _start_time + pump_duration
	_dump_end_time = _pump_end_time + dump_duration
	_pump_multiplier = rng.randf_range(pump_multiplier_min, pump_multiplier_max)
	_dump_multiplier = rng.randf_range(dump_multiplier_min, dump_multiplier_max)
	_state = State.PENDING

	print("market event scheduled:",
		" symbol=", target_symbol,
		" type=", target_type,
		" start_time=", _start_time,
		" pump_end=", _pump_end_time,
		" dump_end=", _dump_end_time,
		" pump_mult=", _pump_multiplier,
		" dump_mult=", _dump_multiplier
	)

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
		print("market event start:",
			" symbol=", target_symbol,
			" type=", target_type,
			" pump_mult=", _pump_multiplier,
			" dump_mult=", _dump_multiplier,
			" pump_dur=", _pump_end_time - _start_time,
			" dump_dur=", _dump_end_time - _pump_end_time,
			" starting_price=", _starting_price,
			" time=", now_minutes
		)
		_print_market_snapshot("start")

	if _state == State.PUMPING:
		var target_price: float = _starting_price * _pump_multiplier
		var t: float = float(now_minutes - _start_time) / max(1.0, float(_pump_end_time - _start_time))
		t = clamp(t, 0.0, 1.0)
		var new_price: float = lerp(_starting_price, target_price, t)
		var prev: float = asset.price
		asset.price = max(snapped(new_price, 0.01), 0.01)
		asset.last_price = prev
		if asset.price_history.size() > 0:
				asset.price_history[asset.price_history.size() - 1] = asset.price
		else:
				asset.price_history.append(asset.price)
		asset.all_time_high = max(asset.all_time_high, asset.price)

		print("market event pumping:",
			" symbol=", target_symbol,
			" prev_price=", prev,
			" new_price=", asset.price,
			" target=", target_price,
			" t=", t,
			" time=", now_minutes
		)

		if now_minutes >= _pump_end_time:
			_state = State.DUMPING
			print("market event peak:",
				" symbol=", target_symbol,
				" price=", asset.price,
				" time=", now_minutes
			)
			_print_market_snapshot("peak")

	elif _state == State.DUMPING:
		var pump_price: float = _starting_price * _pump_multiplier
		var target_price: float = _starting_price * _dump_multiplier
		var t: float = float(now_minutes - _pump_end_time) / max(1.0, float(_dump_end_time - _pump_end_time))
		t = clamp(t, 0.0, 1.0)
		var new_price: float = lerp(pump_price, target_price, t)
		var prev: float = asset.price
		asset.price = max(snapped(new_price, 0.01), 0.01)
		asset.last_price = prev
		if asset.price_history.size() > 0:
				asset.price_history[asset.price_history.size() - 1] = asset.price
		else:
				asset.price_history.append(asset.price)
		asset.all_time_high = max(asset.all_time_high, asset.price)

		print("market event dumping:",
			" symbol=", target_symbol,
			" prev_price=", prev,
			" new_price=", asset.price,
			" target=", target_price,
			" t=", t,
			" time=", now_minutes
		)

		if now_minutes >= _dump_end_time:
			_state = State.FINISHED
			print("market event end:",
				" symbol=", target_symbol,
				" final_price=", asset.price,
				" time=", now_minutes
			)
			_print_market_snapshot("end")
