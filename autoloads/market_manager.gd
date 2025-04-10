extends Node
# Autoload name: MarketManager

@export var tick_interval: float = 1.0
@export var crypto_tick_offset: float = 0.5  # Offset from market tick

var stock_market: Dictionary = {}  # symbol: Stock
var crypto_market: Dictionary = {}  # name: Crypto (if needed later)

var tick_timer: Timer
var crypto_timer: Timer

signal market_tick()
signal crypto_tick()
signal stock_price_updated(symbol: String, stock: Stock)
signal crypto_price_updated(name: String, crypto: Cryptocurrency)

func _ready():
	# Market tick
	tick_timer = Timer.new()
	tick_timer.wait_time = tick_interval
	tick_timer.one_shot = false
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_market_tick)
	add_child(tick_timer)

	# Crypto tick (staggered)
	crypto_timer = Timer.new()
	crypto_timer.wait_time = tick_interval
	crypto_timer.one_shot = false
	crypto_timer.autostart = true
	crypto_timer.timeout.connect(_on_crypto_tick)
	add_child(crypto_timer)

	# Start crypto timer slightly delayed
	await get_tree().create_timer(crypto_tick_offset).timeout
	crypto_timer.start()


func _on_market_tick() -> void:
	emit_signal("market_tick")
	_update_stock_prices()


func _on_crypto_tick() -> void:
	_update_crypto_prices()
	emit_signal("crypto_tick")  # Let miners do their thing after prices shift

func register_stock(stock: Stock) -> void:
	stock_market[stock.symbol] = stock


func get_stock(symbol: String) -> Stock:
	return stock_market.get(symbol)


func _update_stock_prices():
	for stock in stock_market.values():
		stock.momentum -= 1
		if stock.momentum <= 0:
			stock.sentiment = randf_range(-1.0, 1.0)
			stock.momentum = randi_range(5, 20)

		var noise = randf_range(-1.0, 1.0)
		var base_fluctuation = stock.price / 100.0 * stock.volatility
		var delta = base_fluctuation * (noise + stock.sentiment)

		var old_price = stock.price
		stock.price = max(snapped(stock.price + delta, 0.01), 0.01)

		if stock.price < 3.0 and randf() < stock.sentiment:
			stock.price = snapped(stock.price + 1.0, 0.01)

		if abs(stock.price - old_price) > 0.001:
			emit_signal("stock_price_updated", stock.symbol, stock)

func _update_crypto_prices():
	for crypto in crypto_market.values():
		var old_price = crypto.price

		var volatility = crypto.volatility
		var noise = randf_range(-1.0, 1.0)
		var delta = crypto.price * 0.01 * volatility * noise

		crypto.last_price = crypto.price
		crypto.price = max(0.01, snapped(crypto.price + delta, 0.01))

		# 🚀 Update power_required based on old_price
		crypto.update_power_required(old_price)

		if abs(crypto.price - old_price) > 0.001:
			emit_signal("crypto_price_updated", crypto.symbol, crypto)
