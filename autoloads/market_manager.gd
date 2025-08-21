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
	"ALPH_STOCK": preload("res://resources/stocks/alph_stock.tres"),
	"BRO_STOCK": preload("res://resources/stocks/bro_stock.tres"),
	"GME_STOCK": preload("res://resources/stocks/gme_stock.tres"),
	"LOCK_STOCK": preload("res://resources/stocks/lock_stock.tres"),
	"TSLA_STOCK": preload("res://resources/stocks/tsla_stock.tres"),
	"USD_STOCK": preload("res://resources/stocks/usd_stock.tres"),
	"YOLO_STOCK": preload("res://resources/stocks/yolo_stock.tres"),
}

var CRYPTO_RESOURCES = {
	"BITC": preload("res://resources/crypto/bitc_crypto.tres"),
	"HAWK": preload("res://resources/crypto/hawk_crypto.tres"),
	"WORM": preload("res://resources/crypto/worm_crypto.tres"),
}

func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	if crypto_market.is_empty():
		print("crypto market was empty")
		_init_crypto_market()
	if stock_market.is_empty():
		_init_stock_market()
	print("market manager ready, crypto should be initialized")

func register_crypto(crypto: Cryptocurrency) -> void:
	if crypto == null:
		push_error("register_crypto: got null resource")
		return

	# Debug: print everything we can about this resource
	var script_name: String = ""
	if crypto.get_script() != null:
		script_name = str(crypto.get_script())
	print("register_crypto: type=", crypto.get_class(),
		", script=", script_name,
		", resource_name=", str(crypto.resource_name),
		", symbol='", str(crypto.symbol), "'")

	# Guard: avoid inserting under empty key
	if str(crypto.symbol).is_empty():
		push_warning("register_crypto: resource had empty 'symbol'; skipping insert")
		return

	crypto_market[crypto.symbol] = crypto
	emit_signal("crypto_price_updated", crypto.symbol, crypto)

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
	print("_init_crypto_market: starting; resource keys=", str(CRYPTO_RESOURCES.keys()))
	var inserted_count: int = 0

	for key_symbol in CRYPTO_RESOURCES.keys():
		var base_res: Resource = CRYPTO_RESOURCES[key_symbol]
		if base_res == null:
			push_error("_init_crypto_market: base resource for key '" + str(key_symbol) + "' is null")
			continue

		var crypto: Resource = base_res.duplicate(true)
		if crypto == null:
			push_error("_init_crypto_market: duplicate(true) returned null for key '" + str(key_symbol) + "'")
			continue

		# Ensure correct type
		if not (crypto is Cryptocurrency):
			push_error("_init_crypto_market: resource for key '" + str(key_symbol) + "' is not a Cryptocurrency (got " + crypto.get_class() + ")")
			continue

		# If symbol missing, set a fallback and log loudly so you can fix the .tres
		var c: Cryptocurrency = crypto as Cryptocurrency
		if str(c.symbol).is_empty():
			push_warning("_init_crypto_market: '" + str(key_symbol) + "' had empty symbol; setting symbol to key '" + str(key_symbol) + "'. Fix the .tres to export a non-empty symbol.")
			c.symbol = str(key_symbol)

		print("registering crypto: '" + str(c.symbol) + "' from key '" + str(key_symbol) + "', resource_name='" + str(c.resource_name) + "'")
		register_crypto(c)
		if crypto_market.has(c.symbol):
			inserted_count += 1

	emit_signal("crypto_market_ready")
	print("crypto market initialized; inserted count=", str(inserted_count))
	print("crypto market keys: " + str(crypto_market.keys()))
	print("crypto market state: " + JSON.stringify(crypto_market, "  "))

func _init_stock_market() -> void:
		for symbol in STOCK_RESOURCES.keys():
				var stock = STOCK_RESOURCES[symbol].duplicate(true)
				register_stock(stock)

## --- SAVELOAD --- ##

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

	# --- Stocks (unchanged) ---
	for symbol in STOCK_RESOURCES.keys():
		var stock: Stock = STOCK_RESOURCES[symbol].duplicate(true)
		if data.get("stock_market", {}).has(symbol):
			stock.from_dict(data["stock_market"][symbol])
		register_stock(stock)

	# --- Cryptos (fixed) ---
	var saved_crypto: Dictionary = data.get("crypto_market", {})

	for key_symbol in CRYPTO_RESOURCES.keys():
		var base_res: Resource = CRYPTO_RESOURCES[key_symbol]
		if base_res == null:
			push_error("load_from_data: base crypto for key '" + str(key_symbol) + "' is null")
			continue

		var crypto_res: Resource = base_res.duplicate(true)
		if crypto_res == null:
			push_error("load_from_data: duplicate(true) returned null for key '" + str(key_symbol) + "'")
			continue

		if not (crypto_res is Cryptocurrency):
			push_error("load_from_data: resource for key '" + str(key_symbol) + "' is not a Cryptocurrency (got " + crypto_res.get_class() + ")")
			continue

		var c: Cryptocurrency = crypto_res as Cryptocurrency

		# Apply saved data if present (saved keys should match real symbols)
		if saved_crypto.has(key_symbol):
			c.from_dict(saved_crypto[key_symbol])

		# Fallback if .tres lacked a symbol and no saved data set it
		if str(c.symbol).is_empty():
			push_warning("load_from_data: '" + str(key_symbol) + "' had empty symbol; setting to key. Fix the .tres.")
			c.symbol = str(key_symbol)

		register_crypto(c)

	emit_signal("crypto_market_ready")
