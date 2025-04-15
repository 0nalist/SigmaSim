extends Node
# Autoload name: MarketManager

var stock_market: Dictionary = {}  # symbol: Stock
var crypto_market: Dictionary = {}  # symbol: Crypto

signal market_tick()
signal crypto_tick()
signal stock_price_updated(symbol: String, stock: Stock)
signal crypto_price_updated(name: String, crypto: Cryptocurrency)

func _ready():
	TimeManager.minute_passed.connect(_on_minute_passed)

func _on_minute_passed(current_time_minutes: int) -> void:
	# Alternate stock and crypto ticks every minute
	if current_time_minutes % 2 == 0:
		_update_stock_prices()
		emit_signal("market_tick")
	else:
		_update_crypto_prices()
		emit_signal("crypto_tick")

func register_stock(stock: Stock) -> void:
	stock_market[stock.symbol] = stock

func get_stock(symbol: String) -> Stock:
	return stock_market.get(symbol)

func apply_stock_transaction(symbol: String, shares_delta: int) -> void:
	var stock = stock_market.get(symbol)
	if not stock:
		return

	stock.player_owned_shares += shares_delta
	stock.player_owned_shares = clamp(stock.player_owned_shares, 0, stock.shares_outstanding)

	# Simple supply/demand logic
	var ownership_ratio = stock.get_player_ownership_ratio()
	if shares_delta > 0:
		stock.sentiment += ownership_ratio * 0.5
		stock.price += stock.price * ownership_ratio * 0.1
	else:
		stock.sentiment -= ownership_ratio * 0.5
		stock.price -= stock.price * ownership_ratio * 0.2

	stock.price = max(snapped(stock.price, 0.01), 0.01)
	emit_signal("stock_price_updated", symbol, stock)

func _update_stock_prices():
	for stock in stock_market.values():
		stock.intrinsic_value += randf_range(0.01, 0.1)

		stock.momentum -= 1
		if stock.momentum <= 0:
			stock.sentiment = randf_range(-1.0, 1.0)
			stock.momentum = randi_range(5, 20)

		var deviation = stock.price / stock.intrinsic_value
		var noise = randf_range(-0.5, 0.5)
		var directional_bias = stock.sentiment * 0.25
		var total_factor = clamp(noise + directional_bias, -1.0, 1.0)
		var max_percent_change = stock.volatility / 100.0
		var delta = stock.price * max_percent_change * total_factor

		if deviation > 2.0 and randf() < 0.2:
			delta -= stock.price * randf_range(0.1, 0.3)
		elif deviation < 0.5 and randf() < 0.2:
			delta += stock.price * randf_range(0.1, 0.3)

		var old_price = stock.price
		stock.price = max(snapped(stock.price + delta, 0.01), 0.01)

		if abs(stock.price - old_price) > 0.001:
			emit_signal("stock_price_updated", stock.symbol, stock)

func _update_crypto_prices():
	for crypto in crypto_market.values():
		var old_price = crypto.price
		var noise = randf_range(-0.5, 0.5)
		var total_factor = noise
		var max_percent_change = crypto.volatility / 100.0
		var delta = crypto.price * max_percent_change * total_factor

		crypto.last_price = crypto.price
		crypto.price = max(0.01, snapped(crypto.price + delta, 0.01))
		crypto.update_power_required(old_price)

		if abs(crypto.price - old_price) > 0.001:
			emit_signal("crypto_price_updated", crypto.symbol, crypto)
