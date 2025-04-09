extends Node
#Autoload name MarketManager

@export var tick_interval: float = 1.0
var tick_timer: Timer

## Market storage
var stock_market: Dictionary = {}  # symbol: Stock
# TODO: Add contractor_market, crypto_market, etc.

## Signals
signal market_tick()
signal stock_price_updated(symbol: String, stock: Stock)

func _ready():
	tick_timer = Timer.new()
	tick_timer.wait_time = tick_interval
	tick_timer.one_shot = false
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)

func _on_tick() -> void:
	emit_signal("market_tick")
	_update_stock_prices()

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
