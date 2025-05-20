extends Node
# Autoload name: GPUManager

signal gpus_changed
signal gpu_prices_changed
signal gpu_burned_out(index: int)
signal crypto_mined(crypto)
signal block_attempted(symbol: String)

var mining_timers: Dictionary = {}  # symbol: Timer

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
	call_deferred("setup_crypto_timers")

func setup_crypto_timers() -> void:
	for crypto in MarketManager.crypto_market.values():
		if not mining_timers.has(crypto.symbol):
			var timer = Timer.new()
			timer.wait_time = crypto.block_time
			timer.autostart = true
			timer.one_shot = false
			timer.timeout.connect(func(): _attempt_mine(crypto))
			add_child(timer)
			mining_timers[crypto.symbol] = timer

func get_time_until_next_block(symbol: String) -> int:
	if not mining_timers.has(symbol):
		return -1
	return int(ceil(mining_timers[symbol].time_left))

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
