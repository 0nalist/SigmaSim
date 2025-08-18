extends Node
# Autoload name: MarketManager

var stock_market: Dictionary = {}  # symbol: Stock
var crypto_market: Dictionary = {}  # symbol: Crypto

signal crypto_market_ready

signal market_tick()
signal crypto_tick()
signal stock_price_updated(symbol: String, stock: Stock)
signal crypto_price_updated(name: String, crypto: Cryptocurrency)

var STOCK_RESOURCES = {
	"ALPH_STOCK" : preload("res://resources/stocks/alph_stock.tres"),
	"BRO_STOCK" : preload("res://resources/stocks/bro_stock.tres"),
	"GME_STOCK" : preload("res://resources/stocks/gme_stock.tres"),
	"LOCK_STOCK" : preload("res://resources/stocks/lock_stock.tres"),
	"TSLA_STOCK" : preload("res://resources/stocks/tsla_stock.tres"),
	"USD_STOCK" : preload("res://resources/stocks/usd_stock.tres"),
	"YOLO_STOCK" : preload("res://resources/stocks/yolo_stock.tres"),
	
}

var CRYPTO_RESOURCES = {
	"BITC_CRYPTO" : preload("res://resources/crypto/bitc_crypto.tres"),
	"HAWK_CRYPTO" : preload("res://resources/crypto/hawk_crypto.tres"),
	"WORM_CRYPTO" : preload("res://resources/crypto/worm_crypto.tres"),
	
}


func _ready():
	TimeManager.minute_passed.connect(_on_minute_passed)
	if crypto_market.is_empty():
		_init_crypto_market()
	if stock_market.is_empty():
		_init_stock_market()

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

func register_crypto(crypto: Cryptocurrency) -> void:
	crypto_market[crypto.symbol] = crypto
	emit_signal("crypto_price_updated", crypto.symbol, crypto)


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

func refresh_prices():
	_update_stock_prices()

func _update_stock_prices():
var rng = RNGManager.get_rng()
for stock in stock_market.values():
stock.intrinsic_value += rng.randf_range(0.0001, 0.001)

		stock.momentum -= 1
		if stock.momentum <= 0:
stock.sentiment = rng.randf_range(-1.0, 1.0)
stock.momentum = rng.randi_range(5, 20)

		var deviation = stock.price / stock.intrinsic_value
var noise = rng.randf_range(-0.5, 0.5)
		var directional_bias = stock.sentiment * 0.25
		var total_factor = clamp(noise + directional_bias, -1.0, 1.0)
		var max_percent_change = stock.volatility / 100.0
		var delta = stock.price * max_percent_change * total_factor

if deviation > 2.0 and rng.randf() < 0.2:
delta -= stock.price * rng.randf_range(0.1, 0.3)
elif deviation < 0.5 and rng.randf() < 0.2:
delta += stock.price * rng.randf_range(0.1, 0.3)

		var old_price = stock.price
		stock.price = max(snapped(stock.price + delta, 0.01), 0.01)

		if abs(stock.price - old_price) > 0.001:
			emit_signal("stock_price_updated", stock.symbol, stock)

func _update_crypto_prices():
	for crypto in crypto_market.values():
		var old_price = crypto.price
		crypto.update_from_market()

		if abs(crypto.price - old_price) > 0.001:
			emit_signal("crypto_price_updated", crypto.symbol, crypto)


## --- Initialization --- ##

func _init_crypto_market() -> void:
	for symbol in CRYPTO_RESOURCES.keys():
		var crypto = CRYPTO_RESOURCES[symbol].duplicate()
		register_crypto(crypto)
	emit_signal("crypto_market_ready")

func _init_stock_market() -> void:
	for symbol in STOCK_RESOURCES.keys():
		var stock = STOCK_RESOURCES[symbol].duplicate()
		register_stock(stock)


## --- SAVELOAD

func get_save_data() -> Dictionary:
	var stock_data := {}
	for symbol in stock_market:
		stock_data[symbol] = stock_market[symbol].to_dict()

	var crypto_data := {}
	for symbol in crypto_market:
		crypto_data[symbol] = crypto_market[symbol].to_dict()

	return {
		"stock_market": stock_data,
		"crypto_market": crypto_data
	}

func load_from_data(data: Dictionary) -> void:
	stock_market.clear()
	crypto_market.clear()

	for symbol in STOCK_RESOURCES.keys():
		var stock = STOCK_RESOURCES[symbol].duplicate()
		if data.get("stock_market", {}).has(symbol):
			stock.from_dict(data["stock_market"][symbol])
		register_stock(stock)

	for symbol in CRYPTO_RESOURCES.keys():
		var crypto = CRYPTO_RESOURCES[symbol].duplicate()
		if data.get("crypto_market", {}).has(symbol):
			crypto.from_dict(data["crypto_market"][symbol])
		register_crypto(crypto)
	emit_signal("crypto_market_ready")
