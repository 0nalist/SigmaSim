extends Node
# Autoload name: GPUManager

signal gpus_changed
signal gpu_prices_changed
signal gpu_burned_out(index: int)
signal crypto_mined(crypto)
signal block_attempted(symbol: String)

var mining_cooldowns := {}  # symbol -> float (remaining cooldown in minutes)


# GPU Pricing
var gpu_base_price: float = 100.0
var current_gpu_price: float = gpu_base_price
var gpu_price_growth: float = 1.4  # price multiplier each purchase


@export var base_power: int = 10
@export var overclock_power_multiplier: float = 1.5
@export var burnout_rate_per_tick: float = 5.0  # Burnout chance increase per tick of overclocking (out of 1000)

var total_power := 0  # Cached sum for all active GPUs

# GPU data arrays — indexed by `gpu_id`
var gpu_cryptos: PackedStringArray = []   # Which crypto this GPU is mining
var is_overclocked: PackedByteArray = []  # 1 = true, 0 = false
var burnout_chances: PackedFloat32Array = []

# Queue for removal
var to_remove: PackedInt32Array = []

func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_tick)
	MarketManager.crypto_market_ready.connect(setup_crypto_cooldowns)

func _on_minute_tick(_min):
	#print("Minute tick! mining_cooldowns:", mining_cooldowns)
	for symbol in mining_cooldowns.keys():
		mining_cooldowns[symbol] -= 1.0
		#print("Cooldown for", symbol, "is now", mining_cooldowns[symbol])
		if mining_cooldowns[symbol] <= 0.0:
		#	print("Attempting to mine", symbol)
			var crypto = MarketManager.crypto_market.get(symbol)
			if crypto:
				_attempt_mine(crypto)
				mining_cooldowns[symbol] = crypto.block_time

func setup_crypto_cooldowns():
	#print("SETUP: crypto_market keys:", MarketManager.crypto_market.keys())
	mining_cooldowns.clear()
	for crypto in MarketManager.crypto_market.values():
	#	print("SETUP: Adding cooldown for", crypto.symbol, "=", crypto.block_time)
		mining_cooldowns[crypto.symbol] = crypto.block_time
	#print("SETUP: Resulting mining_cooldowns:", mining_cooldowns)

func get_time_until_next_block(symbol: String) -> int:
	if not mining_cooldowns.has(symbol):
		return -1
	return int(ceil(mining_cooldowns[symbol]))




func _attempt_mine(crypto: Cryptocurrency) -> void:
	emit_signal("block_attempted", crypto.symbol)
	var current_power = get_power_for(crypto.symbol)

	if current_power <= 0:
		return

	var random_difficulty = randi_range(0, crypto.power_required)
	if current_power >= random_difficulty:
		PortfolioManager.add_crypto(crypto.symbol, crypto.block_size)
		emit_signal("crypto_mined", crypto)
	emit_signal("gpus_changed")  # Notify Minerr UI to refresh

func add_gpu(crypto_symbol: String, overclocked := false) -> void:
	gpu_cryptos.append(crypto_symbol)
	is_overclocked.append(1 if overclocked else 0)
	burnout_chances.append(0.0)

	var power := int(base_power * overclock_power_multiplier) if overclocked else base_power
	total_power += power

	emit_signal("gpus_changed")

func buy_gpu() -> bool:
	if PortfolioManager.attempt_spend(current_gpu_price):
		add_gpu("")  # Add a free GPU (unassigned)
		current_gpu_price *= gpu_price_growth
		emit_signal("gpus_changed")
		emit_signal("gpu_prices_changed")
		return true
	else:
		print("Insufficient funds to buy GPU.")
		return false

# Adjust get_free_gpu_count logic:
func get_free_gpu_count() -> int:
	var free := 0
	for crypto in gpu_cryptos:
		if crypto == "":
			free += 1
	return free

# Modified assign_gpu function (to assign a free GPU to a crypto)
func assign_free_gpu(symbol: String) -> bool:
	for i in gpu_cryptos.size():
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
		var old_power = int(base_power * overclock_power_multiplier) if was_overclocked else base_power
		var new_power = int(base_power * overclock_power_multiplier) if overclocked else base_power
		total_power += new_power - old_power

	is_overclocked[index] = 1 if overclocked else 0


func process_gpu_tick() -> void:
	total_power = 0  # Recalculate total power

	for i in range(gpu_cryptos.size()):
		var symbol : String = gpu_cryptos[i]
		var crypto : Cryptocurrency = MarketManager.crypto_market.get(symbol)
		if not crypto:
			continue

		var power = base_power
		if is_overclocked[i]:
			power *= overclock_power_multiplier
			burnout_chances[i] += burnout_rate_per_tick

			if randi_range(0, 1000) < burnout_chances[i]:
				to_remove.append(i)
				emit_signal("gpu_burned_out", i)
				continue
		else:
			burnout_chances[i] = 0.0  # Reset burnout if not overclocked

		# Mining logic
		if randi_range(0, crypto.power_required) < power:
			PortfolioManager.add_crypto(symbol, crypto.reward_per_mine)

		total_power += int(power)

	# Handle removals efficiently
	_cleanup_burned_gpus()

func _cleanup_burned_gpus() -> void:
	if to_remove.is_empty():
		return

	# Remove in reverse to preserve indices
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
			gpu_cryptos[i] = ""  # ← Assign GPU as free (unassigned), don't delete it!
			is_overclocked[i] = 0  # Optionally reset overclock status
			burnout_chances[i] = 0.0  # Optionally reset burnout chances
			removed += 1
		i -= 1
	
	if removed > 0:
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
	for i in gpu_cryptos.size():
		if gpu_cryptos[i] == symbol:
			var power = base_power
			if is_overclocked[i]:
				power = int(round(base_power * overclock_power_multiplier))
			total += power
	return total

func get_new_gpu_price() -> float:
	return current_gpu_price

func get_used_gpu_price() -> float:
	# Assuming used GPUs are a fixed discount (e.g. 50% of new)
	return current_gpu_price * 0.5

## SAVE/LOAD/RESET

func reset() -> void:
	gpu_cryptos.clear()
	is_overclocked.clear()
	burnout_chances.clear()
	to_remove.clear()
	total_power = 0
	current_gpu_price = gpu_base_price

	mining_cooldowns.clear()


func get_save_data() -> Dictionary:
	var cooldowns: Dictionary = {}
	for symbol in mining_cooldowns:
		cooldowns[symbol] = mining_cooldowns[symbol]

	return {
		"current_gpu_price": current_gpu_price,
		"gpu_cryptos": gpu_cryptos,
		"is_overclocked": is_overclocked,
		"burnout_chances": burnout_chances,
		"mining_cooldowns": cooldowns
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

	# -- Force array lengths to match
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

	var saved_cooldowns = data.get("mining_cooldowns", {})
	for symbol in saved_cooldowns.keys():
		mining_cooldowns[symbol] = float(saved_cooldowns[symbol])

	emit_signal("gpus_changed")



func array_to_packed_byte_array(arr: Array) -> PackedByteArray:
	var pba := PackedByteArray()
	for v in arr:
		pba.append(int(v))  # Make sure to cast to int (0/1)
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
