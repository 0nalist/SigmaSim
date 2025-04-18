# Cryptocurrency.gd
extends Resource
class_name Cryptocurrency

@export var symbol: String
@export var display_name: String
@export var icon: Texture
@export var price: float = 1.0
@export var volatility: float = 1.0
@export var power_required: int = 100
@export var reward_per_mine: float = 1.0
@export var price_history: Array[float] = []
@export var all_time_high: float = 1.0

var last_price: float = price


func update_power_required(previous_price: float) -> void:
	if previous_price <= 0:
		return

	var value_ratio = price / previous_price
	var noise = randf_range(0.95, 1.05)
	var new_required = power_required * value_ratio * noise

	# Only update if higher than previous
	power_required = max(power_required, clamp(int(new_required), 1, 1_000_000))


## --- SAVELOAD

func to_dict() -> Dictionary:
	return {
		"symbol": symbol,
		"display_name": display_name,
		"price": price,
		"volatility": volatility,
		"power_required": power_required,
		"reward_per_mine": reward_per_mine,
		"price_history": price_history.duplicate(),
		"all_time_high": all_time_high,
		"last_price": last_price
	}

func from_dict(data: Dictionary) -> void:
	symbol = data.get("symbol", symbol)
	display_name = data.get("display_name", display_name)
	price = data.get("price", price)
	volatility = data.get("volatility", volatility)
	power_required = data.get("power_required", power_required)
	reward_per_mine = data.get("reward_per_mine", reward_per_mine)
	price_history = data.get("price_history", price_history)
	all_time_high = data.get("all_time_high", all_time_high)
	last_price = data.get("last_price", price)
