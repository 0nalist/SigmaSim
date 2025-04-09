extends Resource
class_name Cryptocurrency

@export var symbol: String
@export var display_name: String
@export var icon: Texture

@export var price: float = 1.0
@export var volatility: float = 1.0  # Multiplier for how volatile this coin is
@export var power_required: int = 100  # Required power to guarantee mining success
@export var reward_per_mine: float = 1.0  # Amount of crypto mined per success
@export var price_history: Array[float] = []

# Used to track the last price so power_required can react a tick later
var last_price: float = price

func update_power_required() -> void:
	if last_price <= 0:
		return
	
	var price_ratio = price / last_price
	var noise = randf_range(0.95, 1.05)
	var new_required = power_required * price_ratio * noise

	power_required = clamp(int(new_required), 1, 1_000_000)
