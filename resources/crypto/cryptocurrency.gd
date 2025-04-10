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
