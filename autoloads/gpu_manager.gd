extends Node
# Autoload name: GPUManager

signal gpus_changed
signal gpu_prices_changed
signal gpu_burned_out(index: int)
signal crypto_mined(crypto)
signal block_attempted(symbol: String)

# var mining_cooldowns := {}  # symbol -> float (remaining cooldown in minutes)

var next_block_time := {}  # symbol -> float (absolute in-game minute when next roll occurs)

# Hourly burnout scheduling
var scheduled_burns: Dictionary = {}
var last_batch_hour: int = -1
var batch_minute: int = 2

# Block attempt tracking
var attempts_window: Dictionary = {}
var attempts_totals: Dictionary = {}
var attempts_index: int = 0

# GPU Pricing
var gpu_base_price: float = 100.0
var current_gpu_price: float = gpu_base_price
var gpu_price_growth: float = 1.2  # price multiplier each purchase

var gpu_credit_requirement: float = 700


@export var base_power: int = 10
@export var overclock_power_multiplier: float = 1.5
@export var burnout_rate_per_tick: float = 5.0  # Burnout chance increase per tick of overclocking (out of 1000)

var total_power := 0  # Cached sum for all active GPUs

# GPU data arrays — indexed by `gpu_id`
var gpu_cryptos: PackedStringArray = []  # Which crypto this GPU is mining
var is_overclocked: PackedByteArray = []  # 1 = true, 0 = false
var burnout_chances: PackedFloat32Array = []

# Queue for removal
var to_remove: PackedInt32Array = []

func _ready() -> void:
TimeManager.minute_passed.connect(_on_minute_tick)
MarketManager.crypto_market_ready.connect(setup_crypto_cooldowns)
block_attempted.connect(_on_block_attempted)

func _on_minute_tick(_unused: int) -> void:
       _advance_attempt_windows()
       var minute_of_hour: int = TimeManager.current_minute
       var current_hour: int = TimeManager.current_hour

       if minute_of_hour == batch_minute and minute_of_hour != 0 and current_hour != last_batch_hour:
               _run_hourly_burn_batch()
               last_batch_hour = current_hour

       if scheduled_burns.has(minute_of_hour):
               var burns: Dictionary = scheduled_burns[minute_of_hour]
               scheduled_burns.erase(minute_of_hour)
               _execute_scheduled_burns(burns)

var rng: RandomNumberGenerator = RNGManager.gpu.get_rng()
var current_time: int = TimeManager.total_minutes_elapsed

       for symbol in next_block_time.keys():
               var next_time: float = next_block_time[symbol]
               var crypto: Cryptocurrency = MarketManager.crypto_market.get(symbol)
               if not crypto:
                       continue

var power: int = get_power_for(symbol)
               if power <= 0:
                       while current_time >= next_time:
                               next_time += crypto.block_time
                       next_block_time[symbol] = next_time
                       continue

               while current_time >= next_time:
                       emit_signal("block_attempted", symbol)
                       var random_difficulty = rng.randi_range(0, crypto.power_required)
                       if power >= random_difficulty:
                               PortfolioManager.add_crypto(symbol, crypto.block_size)
                               emit_signal("crypto_mined", crypto)
                       next_time += crypto.block_time
               next_block_time[symbol] = next_time

       emit_signal("gpus_changed")  # Notify Minerr UI to refresh

func _on_block_attempted(symbol: String) -> void:
if not attempts_window.has(symbol):
var arr: Array = []
arr.resize(60)
attempts_window[symbol] = arr
attempts_totals[symbol] = 0
var arr: Array = attempts_window[symbol]
arr[attempts_index] = int(arr[attempts_index]) + 1
attempts_totals[symbol] = int(attempts_totals[symbol]) + 1

func _advance_attempt_windows() -> void:
	attempts_index = (attempts_index + 1) % 60
	for symbol in attempts_window.keys():
	var arr: Array = attempts_window[symbol]
	attempts_totals[symbol] = int(attempts_totals[symbol]) - int(arr[attempts_index])
	arr[attempts_index] = 0

func get_attempts_per_hour(symbol: String) -> float:
	if attempts_totals.has(symbol):
	return float(attempts_totals[symbol])
	var crypto: Cryptocurrency = MarketManager.crypto_market.get(symbol)
	if crypto:
	return 60.0 / max(crypto.block_time, 1.0)
	return 0.0

func get_used_gpu_count_for(symbol: String) -> int:
	return get_gpu_count_for(symbol)

func get_global_burnout_multiplier() -> float:
	return 1.0

func get_symbol_burnout_multiplier(symbol: String) -> float:
	return 1.0

func _run_hourly_burn_batch() -> void:
	scheduled_burns.clear()
    var rng: RandomNumberGenerator = RNGManager.gpu.get_rng()
	for crypto in MarketManager.crypto_market.values():
	var symbol: String = crypto.symbol
	var m_used: int = get_used_gpu_count_for(symbol)
	if m_used <= 0:
	continue
	var A: float = get_attempts_per_hour(symbol)
	if A <= 0.0:
	continue
	var p_eff: float = clamp(0.01 * get_global_burnout_multiplier() * get_symbol_burnout_multiplier(symbol), 0.001, 0.25)
	var T: int = int(floor(m_used * A))
	if T <= 0:
	continue
	var K: int = _sample_burnouts(T, p_eff, m_used, rng)
	if K <= 0:
	continue
	for i in range(K):
	var r: int = rng.randi_range(0, 59)
	var bucket: Dictionary = scheduled_burns.get(r, {})
	bucket[symbol] = int(bucket.get(symbol, 0)) + 1
	scheduled_burns[r] = bucket

func _sample_burnouts(T: int, p_eff: float, m_used: int, rng: RandomNumberGenerator) -> int:
	var K: int = 0
	if T <= 200:
	for i in range(T):
	if rng.randf() < p_eff:
	K += 1
	elif T * p_eff <= 30.0 and p_eff <= 0.05:
	var lam: float = T * p_eff
	var L: float = exp(-lam)
	var k: int = 0
	var p_val: float = 1.0
	while k < m_used and p_val > L:
	k += 1
	p_val *= rng.randf()
	K = k - 1
	elif T * p_eff >= 30.0 and T * (1.0 - p_eff) >= 30.0:
	var mu: float = T * p_eff
	var sigma: float = sqrt(T * p_eff * (1.0 - p_eff))
	K = int(round(rng.randfn(mu, sigma)))
	if K < 0:
	K = 0
	else:
	for i in range(T):
	if rng.randf() < p_eff:
	K += 1
	if K >= m_used:
	break
	if K > m_used:
	K = m_used
	return K

func _execute_scheduled_burns(burns: Dictionary) -> void:
    var rng: RandomNumberGenerator = RNGManager.gpu.get_rng()
	for symbol in burns.keys():
	var count: int = int(burns[symbol])
	_burn_random_gpus(symbol, count, rng)
	_cleanup_burned_gpus()

func _burn_random_gpus(symbol: String, count: int, rng: RandomNumberGenerator) -> void:
	var indices: Array = _get_used_gpu_indices(symbol)
	var m: int = indices.size()
	if m == 0:
	return
	if count > m:
	count = m
	var selected: Array = _select_random_indices(indices, count, rng)
	for idx in selected:
	to_remove.append(int(idx))
	emit_signal("gpu_burned_out", int(idx))

func _get_used_gpu_indices(symbol: String) -> Array:
	var arr: Array = []
	for i in range(gpu_cryptos.size()):
	if gpu_cryptos[i] == symbol:
	arr.append(i)
	return arr

func _select_random_indices(source: Array, count: int, rng: RandomNumberGenerator) -> Array:
	var m: int = source.size()
	var result: Array = []
	if count <= 0 or m == 0:
	return result
	if count > m:
	count = m
	if count > m / 3:
	var survivors_dict: Dictionary = _floyd_sample_range(m, m - count, rng)
	var survivor_map: Dictionary = {}
	for key in survivors_dict.keys():
	survivor_map[int(key)] = true
	for i in range(m):
	if not survivor_map.has(i):
	result.append(source[i])
	else:
	var chosen: Dictionary = _floyd_sample_range(m, count, rng)
	for key in chosen.keys():
	result.append(source[int(key)])
	return result

func _floyd_sample_range(n: int, k: int, rng: RandomNumberGenerator) -> Dictionary:
	var chosen: Dictionary = {}
	for i in range(n - k, n):
	var r: int = rng.randi_range(0, i)
	if chosen.has(r):
	chosen[i] = true
	else:
	chosen[r] = true
	return chosen

func setup_crypto_cooldowns() -> void:
	next_block_time.clear()
	for crypto in MarketManager.crypto_market.values():
		next_block_time[crypto.symbol] = TimeManager.total_minutes_elapsed + crypto.block_time

func get_time_until_next_block(symbol: String) -> int:
	if not next_block_time.has(symbol):
		return -1
	# Use total_minutes_elapsed to handle day rollovers correctly
	return int(ceil(next_block_time[symbol] - TimeManager.total_minutes_elapsed))

func add_gpu(crypto_symbol: String, overclocked := false) -> void:
	gpu_cryptos.append(crypto_symbol)
	if overclocked:
		is_overclocked.append(1)
	else:
		is_overclocked.append(0)
	burnout_chances.append(0.0)

	var power := base_power
	if overclocked:
		power = int(base_power * overclock_power_multiplier)
	total_power += power

	emit_signal("gpus_changed")

func buy_gpu() -> bool:
	if PortfolioManager.attempt_spend(current_gpu_price, gpu_credit_requirement):
		add_gpu("")  # Add a free GPU (unassigned)
		current_gpu_price *= gpu_price_growth
		emit_signal("gpus_changed")
		emit_signal("gpu_prices_changed")
		return true
	else:
		print("Insufficient funds to buy GPU.")
		return false

func get_free_gpu_count() -> int:
	var free := 0
	for crypto in gpu_cryptos:
		if crypto == "":
			free += 1
	return free

func assign_free_gpu(symbol: String) -> bool:
	for i in range(gpu_cryptos.size()):
		if gpu_cryptos[i] == "":
			gpu_cryptos[i] = symbol
			emit_signal("gpus_changed")
			return true
	return false  # No free GPU available

func set_overclocked(index: int, overclocked: bool) -> void:
	if index >= gpu_cryptos.size():
		return

	var was_overclocked = bool(is_overclocked[index])
	if was_overclocked != overclocked:
		var old_power = base_power
		if was_overclocked:
			old_power = int(base_power * overclock_power_multiplier)
		var new_power = base_power
		if overclocked:
			new_power = int(base_power * overclock_power_multiplier)
		total_power += new_power - old_power
		if overclocked:
			is_overclocked[index] = 1
		else:
			is_overclocked[index] = 0

func process_gpu_tick() -> void:
    var rng = RNGManager.gpu.get_rng()
	total_power = 0  # Recalculate total power

	for i in range(gpu_cryptos.size()):
		var symbol: String = gpu_cryptos[i]
		var crypto: Cryptocurrency = MarketManager.crypto_market.get(symbol)
		if not crypto:
			continue

		var power = base_power
		if is_overclocked[i]:
			power *= overclock_power_multiplier
			burnout_chances[i] += burnout_rate_per_tick

			if rng.randi_range(0, 1000) < burnout_chances[i]:
				to_remove.append(i)
				emit_signal("gpu_burned_out", i)
				continue
		else:
			burnout_chances[i] = 0.0  # Reset burnout if not overclocked

		# Mining logic
		if rng.randi_range(0, crypto.power_required) < power:
			PortfolioManager.add_crypto(symbol, crypto.reward_per_mine)

		total_power += int(power)

	# Handle removals efficiently
	_cleanup_burned_gpus()

func _cleanup_burned_gpus() -> void:
	if to_remove.is_empty():
		return

	to_remove.sort()
	for i in range(to_remove.size() - 1, -1, -1):
		var index := to_remove[i]
		gpu_cryptos.remove_at(index)
		is_overclocked.remove_at(index)
		burnout_chances.remove_at(index)

	to_remove.clear()
	emit_signal("gpus_changed")

func remove_gpu_from(symbol: String, count: int = 1) -> void:
	var removed := 0
	var i := gpu_cryptos.size() - 1
	while i >= 0 and removed < count:
		if gpu_cryptos[i] == symbol:
			gpu_cryptos[i] = ""  # Assign GPU as free (unassigned), don't delete it!
			is_overclocked[i] = 0
			burnout_chances[i] = 0.0
			removed += 1
		i -= 1

		if removed > 0:
				emit_signal("gpus_changed")

func halve_gpus() -> void:
	var target := int(floor(gpu_cryptos.size() / 2.0))
	while gpu_cryptos.size() > target:
			var index := gpu_cryptos.size() - 1
			gpu_cryptos.remove_at(index)
			is_overclocked.remove_at(index)
			burnout_chances.remove_at(index)
	total_power = 0
	emit_signal("gpus_changed")

func get_total_gpu_count() -> int:
	return gpu_cryptos.size()

func get_gpu_count_for(symbol: String) -> int:
	var count := 0
	for assigned_symbol in gpu_cryptos:
		if assigned_symbol == symbol:
			count += 1
	return count

func get_power_for(symbol: String) -> int:
	var total := 0
	for i in range(gpu_cryptos.size()):
		if gpu_cryptos[i] == symbol:
			var power = base_power
			if is_overclocked[i]:
				power = int(round(base_power * overclock_power_multiplier))
			total += power
	return total

func get_new_gpu_price() -> float:
	return current_gpu_price

func get_used_gpu_price() -> float:
	return current_gpu_price * 0.5  # Fixed discount

## SAVE/LOAD/RESET

func reset() -> void:
	gpu_cryptos.clear()
	is_overclocked.clear()
	burnout_chances.clear()
	to_remove.clear()
	total_power = 0
	current_gpu_price = gpu_base_price
	next_block_time.clear()
	scheduled_burns.clear()
	attempts_window.clear()
	attempts_totals.clear()
	attempts_index = 0
	last_batch_hour = -1

func get_save_data() -> Dictionary:
	var next_times: Dictionary = {}
	for symbol in next_block_time:
		next_times[symbol] = next_block_time[symbol]
	var burns: Array = []
	for minute in scheduled_burns.keys():
		var per_symbol: Dictionary = scheduled_burns[minute]
		for symbol in per_symbol.keys():
			burns.append({"minute": minute, "symbol": symbol, "count": int(per_symbol[symbol])})
	return {
		"current_gpu_price": current_gpu_price,
		"gpu_cryptos": gpu_cryptos,
		"is_overclocked": is_overclocked,
		"burnout_chances": burnout_chances,
		"next_block_time": next_times,
		"scheduled_burns": burns,
		"last_batch_hour": last_batch_hour
	}


func load_from_data(data: Dictionary) -> void:
	reset()

	current_gpu_price = data.get("current_gpu_price", gpu_base_price)

	var arr_crypto = data.get("gpu_cryptos", [])
	if typeof(arr_crypto) == TYPE_STRING:
		arr_crypto = []
	gpu_cryptos = array_to_packed_string_array(arr_crypto)

	var arr_overclock = data.get("is_overclocked", [])
	if typeof(arr_overclock) == TYPE_STRING:
		arr_overclock = []
	is_overclocked = array_to_packed_byte_array(arr_overclock)

	var arr_burnout = data.get("burnout_chances", [])
	if typeof(arr_burnout) == TYPE_STRING:
		arr_burnout = []
	burnout_chances = array_to_packed_float32_array(arr_burnout)

	var gpu_count = gpu_cryptos.size()
	while is_overclocked.size() < gpu_count:
		is_overclocked.append(0)
	while burnout_chances.size() < gpu_count:
		burnout_chances.append(0.0)
	while is_overclocked.size() > gpu_count:
		is_overclocked.remove_at(is_overclocked.size() - 1)
	while burnout_chances.size() > gpu_count:
		burnout_chances.remove_at(burnout_chances.size() - 1)

	setup_crypto_cooldowns()

	var saved_times = data.get("next_block_time", {})
	for symbol in saved_times.keys():
		next_block_time[symbol] = float(saved_times[symbol])

	scheduled_burns.clear()
	var burns: Array = data.get("scheduled_burns", [])
	for entry in burns:
		var minute: int = int(entry.get("minute", -1))
		var symbol: String = str(entry.get("symbol", ""))
		var count: int = int(entry.get("count", 0))
		if minute < 0 or minute > 59 or count <= 0 or symbol == "":
		continue
		var bucket: Dictionary = scheduled_burns.get(minute, {})
		bucket[symbol] = int(bucket.get(symbol, 0)) + count
		scheduled_burns[minute] = bucket
	last_batch_hour = int(data.get("last_batch_hour", -1))
	var current_minute: int = TimeManager.current_minute
	var to_exec: Array = []
	for minute in scheduled_burns.keys():
		if minute < current_minute:
		to_exec.append(minute)
	for minute in to_exec:
		var burns_now: Dictionary = scheduled_burns[minute]
		scheduled_burns.erase(minute)
		_execute_scheduled_burns(burns_now)

emit_signal("gpus_changed")

func array_to_packed_byte_array(arr: Array) -> PackedByteArray:
	var pba := PackedByteArray()
	for v in arr:
		pba.append(int(v))
	return pba

func array_to_packed_float32_array(arr: Array) -> PackedFloat32Array:
	var pfa := PackedFloat32Array()
	for v in arr:
		pfa.append(float(v))
	return pfa

func array_to_packed_string_array(arr: Array) -> PackedStringArray:
	var psa := PackedStringArray()
	for v in arr:
		psa.append(str(v))
	return psa
