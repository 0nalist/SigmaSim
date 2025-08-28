extends Resource
class_name Fund

@export var expected_return: float = 0.0
@export var time_period: int = 1
@export var variability: float = 0.0
@export var index_fund: bool = false
@export var index_assets: Dictionary = {}

var last_return: float = 0.0

func simulate_yield(principal: float, asset_returns: Dictionary = {}, rng: RandomNumberGenerator = null) -> float:
	if index_fund and index_assets.size() > 0:
		if asset_returns.is_empty():
			return principal
		var total: float = 0.0
		var total_count: int = 0
		for symbol in index_assets.keys():
			var count: int = int(index_assets[symbol])
			var pct: float = asset_returns.get(symbol, 0.0)
			total += pct * count
			total_count += count
		if total_count == 0:
			return principal
		var avg_pct: float = total / total_count
		last_return = principal * avg_pct / 100.0
		return principal * (1.0 + avg_pct / 100.0)
	else:
		if rng == null:
			rng = RandomNumberGenerator.new()
			rng.randomize()
		var noise: float = 0.0
		if variability > 0.0:
			noise = rng.randf_range(-variability, variability)
		var actual_pct: float = expected_return + noise
		last_return = principal * actual_pct / 100.0
		return principal * (1.0 + actual_pct / 100.0)
