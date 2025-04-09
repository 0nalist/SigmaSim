extends BaseAppUI
# Autoload name: GPUManager

signal gpus_changed
signal gpu_burned_out(index: int)

@export var base_power: int = 100
@export var overclock_power_multiplier: float = 1.5
@export var burnout_rate_per_tick: float = 5.0  # Burnout chance increase per tick of overclocking (out of 1000)

var total_power := 0  # Cached sum for all active GPUs

# GPU data arrays — indexed by `gpu_id`
var gpu_cryptos: PackedStringArray = []   # Which crypto this GPU is mining
var is_overclocked: PackedByteArray = []  # 1 = true, 0 = false
var burnout_chances: PackedFloat32Array = []

# Queue for removal
var to_remove: PackedInt32Array = []

func add_gpu(crypto_symbol: String, overclocked := false) -> void:
	gpu_cryptos.append(crypto_symbol)
	is_overclocked.append(1 if overclocked else 0)
	burnout_chances.append(0.0)

	var power := int(base_power * overclock_power_multiplier) if overclocked else base_power
	total_power += power

	emit_signal("gpus_changed")


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


func get_total_gpu_count() -> int:
	return gpu_cryptos.size()

func get_free_gpu_count() -> int:
	var assigned := 0
	for symbol in gpu_cryptos:
		if symbol != "":
			assigned += 1
	return gpu_cryptos.size() - assigned
