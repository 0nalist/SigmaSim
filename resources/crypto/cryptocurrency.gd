# Cryptocurrency.gd
extends Resource
class_name Cryptocurrency

@export var symbol: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
@export var price: float = 1.0
@export var volatility: float = 1.0
@export var power_required: int = 100
@export var block_size: float = 1.0
@export var block_time: float = 10.0
@export var price_history: Array[float] = [price]
@export var all_time_high: float = 1.0

var last_price: float = price

func update_price(delta: float) -> void:
	price_history.append(price)
	if price_history.size() > 1000:
		price_history.pop_front()

	last_price = price
	price = max(0.01, snapped(price + delta, 0.01))
	all_time_high = max(all_time_high, price)


func update_from_market(volatility_scale: float = 1.0) -> void:
	var rng: RandomNumberGenerator = RNGManager.crypto.get_rng()
	var noise: float = rng.randf_range(-0.5, 0.5)
	var max_percent_change: float = volatility / 100.0 * volatility_scale
	var delta: float = price * max_percent_change * noise
	update_price(delta)
	#update_power_required(price)

'''
func update_power_required(previous_price: float) -> void:
	if previous_price <= 0:
		return

	var value_ratio = price / previous_price
	var noise = rng.randf_range(0.95, 1.05)
	   var new_required = power_required * value_ratio * noise

	# Set updated value
	power_required = clamp(int(new_required), 1, 1_000_000)
'''

## --- SAVELOAD

func to_dict() -> Dictionary:
	return {
		"symbol": symbol,
		"display_name": display_name,
		"price": price,
		"volatility": volatility,
		"power_required": power_required,
		"block_size": block_size,
		"price_history": price_history.duplicate() as Array[float],
		"all_time_high": all_time_high,
		"last_price": last_price
	}

func from_dict(data: Dictionary) -> void:
	symbol = data.get("symbol", symbol)
	display_name = data.get("display_name", display_name)
	price = data.get("price", price)
	volatility = data.get("volatility", volatility)
	power_required = data.get("power_required", power_required)
	block_size = data.get("block_size", block_size)
	var raw_history = data.get("price_history", price_history)
	price_history = []
	for value in raw_history:
		if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
			price_history.append(float(value))
	all_time_high = data.get("all_time_high", all_time_high)
	last_price = data.get("last_price", price)
