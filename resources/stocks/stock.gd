extends Resource
class_name Stock

@export var symbol: String
@export var price: float = 1.0
@export var shares_outstanding: int = 1000

# --- Price Modeling ---
@export var intrinsic_value: float = 1.0
@export var trailing_average: float = 1.0
@export var smoothing_factor: float = 0.05  # EMA-like smoothing
@export var volatility: float = 0.1         # Range: 0.01 to 1.0

# --- Behavior ---
@export var sentiment: float = 0.0          # Between -1 and 1
@export var momentum: int = 0               # Ticks until sentiment change

# --- Player Ownership ---
var player_owned_shares: int = 0


# --- Called each tick to evolve price dynamics ---
func update_trailing_average():
	# Exponential Moving Average (EMA-style smoothing)
	trailing_average = trailing_average * (1.0 - smoothing_factor) + price * smoothing_factor


func apply_price_delta(delta: float):
	price = max(0.01, price + delta)
	update_trailing_average()


# --- Ownership Ratio ---
func get_player_ownership_ratio() -> float:
	if shares_outstanding <= 0:
		return 0.0
	return clamp(float(player_owned_shares) / float(shares_outstanding), 0.0, 1.0)


## --- SAVE LOAD

func to_dict() -> Dictionary:
	return {
		"symbol": symbol,
		"price": price,
		"shares_outstanding": shares_outstanding,
		"intrinsic_value": intrinsic_value,
		"trailing_average": trailing_average,
		"smoothing_factor": smoothing_factor,
		"volatility": volatility,
		"sentiment": sentiment,
		"momentum": momentum,
		"player_owned_shares": player_owned_shares
	}

func from_dict(data: Dictionary) -> void:
	symbol = data.get("symbol", symbol)
	price = data.get("price", price)
	shares_outstanding = data.get("shares_outstanding", shares_outstanding)
	intrinsic_value = data.get("intrinsic_value", intrinsic_value)
	trailing_average = data.get("trailing_average", trailing_average)
	smoothing_factor = data.get("smoothing_factor", smoothing_factor)
	volatility = data.get("volatility", volatility)
	sentiment = data.get("sentiment", sentiment)
	momentum = data.get("momentum", momentum)
	player_owned_shares = data.get("player_owned_shares", player_owned_shares)
