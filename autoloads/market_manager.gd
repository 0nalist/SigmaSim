extends Node
# Autoload name: MarketManager

var stock_market: Dictionary = {}  # symbol: Stock
var crypto_market: Dictionary = {}  # symbol: Crypto
var stock_events: Dictionary = {}  # symbol: MarketEvent
var crypto_events: Dictionary = {}  # symbol: MarketEvent

signal crypto_market_ready

signal market_tick()
signal crypto_tick()
signal stock_price_updated(symbol: String, stock: Stock)
signal crypto_price_updated(name: String, crypto: Cryptocurrency)

var STOCK_RESOURCES := {
	"ALPH_STOCK": preload("res://resources/stocks/alph_stock.tres"),
	"BRO_STOCK": preload("res://resources/stocks/bro_stock.tres"),
	"GME_STOCK": preload("res://resources/stocks/gme_stock.tres"),
	"LOCK_STOCK": preload("res://resources/stocks/lock_stock.tres"),
	"TSLA_STOCK": preload("res://resources/stocks/tsla_stock.tres"),
	"USD_STOCK": preload("res://resources/stocks/usd_stock.tres"),
	"YOLO_STOCK": preload("res://resources/stocks/yolo_stock.tres"),
}

var CRYPTO_RESOURCES := {
	"BITC": preload("res://resources/crypto/bitc_crypto.tres"),
	"HAWK1": preload("res://resources/crypto/hawk1_crypto.tres"),
	"HAWK2": preload("res://resources/crypto/hawk2_crypto.tres"),
	"WORM": preload("res://resources/crypto/worm_crypto.tres"),
}

var EVENT_RESOURCES := {
	"HAWK_PUMP": preload("res://resources/market_events/hawk_pump_and_dump.tres"),
}

var DAILY_EVENT_RESOURCES := {
	"GENERIC_SURGE": preload("res://resources/market_events/generic_asset_surge.tres"),
	"GENERIC_CRASH": preload("res://resources/market_events/generic_asset_crash.tres"),
}

var MAJOR_EVENT_RESOURCES := {
	"MAJOR_SURGE": preload("res://resources/market_events/major_market_surge.tres"),
	"MAJOR_CRASH": preload("res://resources/market_events/major_market_crash.tres"),
}

func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.hour_passed.connect(_on_hour_passed)
	if crypto_market.is_empty():
			print("crypto market was empty")
			_init_crypto_market()
	if stock_market.is_empty():
		_init_stock_market()
	print("market manager ready, crypto should be initialized")

func init_new_save_events() -> void:
	_init_market_events()


func register_crypto(crypto: Cryptocurrency) -> void:
	if crypto == null:
		push_error("register_crypto: got null resource")
		return

	assert(crypto is Cryptocurrency)
	assert(not str(crypto.symbol).is_empty())
	assert(not crypto_market.has(crypto.symbol))

	var script_name: String = ""
	if crypto.get_script() != null:
		script_name = str(crypto.get_script())
	var obj_id: int = crypto.get_instance_id()
	print("register_crypto: id=", str(obj_id),
	", type=", crypto.get_class(),
	", script=", script_name,
	", resource_name=", str(crypto.resource_name),
	", symbol='", str(crypto.symbol), "'")

	if str(crypto.symbol).is_empty():
		push_warning("register_crypto: resource had empty 'symbol'; skipping insert")
		return

	if crypto_market.has(crypto.symbol):
		push_warning("register_crypto: symbol '" + crypto.symbol + "' already registered; skipping")
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

func _on_hour_passed(current_hour: int, _total_minutes: int) -> void:
	if current_hour == 9:
			_schedule_daily_events()

func register_stock(stock: Stock) -> void:
	stock_market[stock.symbol] = stock


func get_stock(symbol: String) -> Stock:
	return stock_market.get(symbol)

func apply_stock_transaction(symbol: String, shares_delta: int) -> void:
	var stock: Stock = stock_market.get(symbol)
	if not stock:
		return

	stock.player_owned_shares += shares_delta
	stock.player_owned_shares = clamp(stock.player_owned_shares, 0, stock.shares_outstanding)

	# Simple supply/demand logic
	var ownership_ratio: float = stock.get_player_ownership_ratio()
	if shares_delta > 0:
		stock.sentiment += ownership_ratio * 0.5
		stock.price += stock.price * ownership_ratio * 0.1
	else:
		stock.sentiment -= ownership_ratio * 0.5
		stock.price -= stock.price * ownership_ratio * 0.2

	stock.price = max(snapped(stock.price, 0.01), 0.01)
	emit_signal("stock_price_updated", symbol, stock)

func refresh_prices() -> void:
	_update_stock_prices()

func _update_stock_prices() -> void:
	var rng: RandomNumberGenerator = RNGManager.market_manager.get_rng()
	var now: int = TimeManager.get_now_minutes()
	for stock: Stock in stock_market.values():
		var event: MarketEvent = stock_events.get(stock.symbol)
		var old_price: float = stock.price

		if event == null or not event.is_active():
			stock.intrinsic_value += rng.randf_range(0.0001, 0.001)

			stock.momentum -= 1
			if stock.momentum <= 0:
				stock.sentiment = rng.randf_range(-1.0, 1.0)
				stock.momentum = rng.randi_range(5, 20)

			var deviation: float = stock.price / stock.intrinsic_value
			var noise: float = rng.randf_range(-0.5, 0.5)
			var directional_bias: float = stock.sentiment * 0.25
			var total_factor: float = clamp(noise + directional_bias, -1.0, 1.0)
			var max_percent_change: float = stock.volatility / 100.0
			var delta: float = stock.price * max_percent_change * total_factor

			if deviation > 2.0 and rng.randf() < 0.2:
				delta -= stock.price * rng.randf_range(0.1, 0.3)
			elif deviation < 0.5 and rng.randf() < 0.2:
				delta += stock.price * rng.randf_range(0.1, 0.3)

			stock.price = max(snapped(stock.price + delta, 0.01), 0.01)

		if event != null:
			event.process(now, stock)
			if event.is_finished():
				stock_events.erase(stock.symbol)

		HistoryManager.add_sample(stock.symbol, now, stock.price)

		if abs(stock.price - old_price) > 0.001:
			emit_signal("stock_price_updated", stock.symbol, stock)


func _update_crypto_prices() -> void:
				var now: int = TimeManager.get_now_minutes()
				for crypto: Cryptocurrency in crypto_market.values():
								var event: MarketEvent = crypto_events.get(crypto.symbol)
								var old_price: float = crypto.price
								if event == null or not event.is_active():
												crypto.update_from_market()
								if event != null:
												event.process(now, crypto)
												if event.is_finished():
																crypto_events.erase(crypto.symbol)
								HistoryManager.add_sample(crypto.symbol, now, crypto.price)
								if abs(crypto.price - old_price) > 0.001:
												emit_signal("crypto_price_updated", crypto.symbol, crypto)

func _schedule_daily_events() -> void:
	var rng := RNGManager.market_manager.get_rng()

	var available_crypto: Array = []
	for symbol: String in crypto_market.keys():
			var ev: MarketEvent = crypto_events.get(symbol)
			if ev == null or ev.is_finished():
					available_crypto.append(symbol)
	if not available_crypto.is_empty():
			var crypto_symbol: String = available_crypto[rng.randi_range(0, available_crypto.size() - 1)]
			var crypto_event_key: String = DAILY_EVENT_RESOURCES.keys()[rng.randi_range(0, DAILY_EVENT_RESOURCES.size() - 1)]
			var crypto_base: Resource = DAILY_EVENT_RESOURCES[crypto_event_key]
			if crypto_base is MarketEvent:
					var crypto_ev: MarketEvent = crypto_base.duplicate(true)
					crypto_ev.target_symbol = crypto_symbol
					crypto_ev.target_type = "crypto"
					crypto_ev.schedule(TimeManager.get_now_minutes(), rng)
					crypto_events[crypto_symbol] = crypto_ev

	var available_stocks: Array = []
	for symbol: String in stock_market.keys():
			var ev: MarketEvent = stock_events.get(symbol)
			if ev == null or ev.is_finished():
					available_stocks.append(symbol)
	if not available_stocks.is_empty():
			var stock_symbol: String = available_stocks[rng.randi_range(0, available_stocks.size() - 1)]
			var stock_event_key: String = DAILY_EVENT_RESOURCES.keys()[rng.randi_range(0, DAILY_EVENT_RESOURCES.size() - 1)]
			var stock_base: Resource = DAILY_EVENT_RESOURCES[stock_event_key]
			if stock_base is MarketEvent:
					var stock_ev: MarketEvent = stock_base.duplicate(true)
					stock_ev.target_symbol = stock_symbol
					stock_ev.target_type = "stock"
					stock_ev.schedule(TimeManager.get_now_minutes(), rng)
					stock_events[stock_symbol] = stock_ev
	# --- Major market events ---
	if rng.randf() < 0.1:
		var is_surge := rng.randf() < 0.6
		var major_key: String
		if is_surge:
			major_key = "MAJOR_SURGE"
		else:
			major_key = "MAJOR_CRASH"

		var base_res: Resource = MAJOR_EVENT_RESOURCES[major_key]
		var weekday := TimeManager.day_of_week # 0 = Monday

		var allow_stock := weekday <= 4
		if weekday > 4 and not is_surge:
			allow_stock = true
		if allow_stock:
			var major_stocks: Array = []
			for symbol: String in stock_market.keys():
				var ev: MarketEvent = stock_events.get(symbol)
				if ev == null or ev.is_finished():
					major_stocks.append(symbol)
			if not major_stocks.is_empty():
				var sym = major_stocks[rng.randi_range(0, major_stocks.size() - 1)]
				var ev_res: MarketEvent = base_res.duplicate(true)
				ev_res.target_symbol = sym
				ev_res.target_type = "stock"
				ev_res.schedule(TimeManager.get_now_minutes(), rng)
				stock_events[sym] = ev_res

		if rng.randf() < 0.8:
			var major_crypto: Array = []
			for symbol: String in crypto_market.keys():
				var ev: MarketEvent = crypto_events.get(symbol)
				if ev == null or ev.is_finished():
					major_crypto.append(symbol)
			if not major_crypto.is_empty():
				var sym = major_crypto[rng.randi_range(0, major_crypto.size() - 1)]
				var ev_res: MarketEvent = base_res.duplicate(true)
				ev_res.target_symbol = sym
				ev_res.target_type = "crypto"
				ev_res.schedule(TimeManager.get_now_minutes(), rng)
				crypto_events[sym] = ev_res

## --- Initialization --- ##

# Load crypto resources fresh to preserve exported data.
func _init_crypto_market() -> void:
	print("_init_crypto_market: starting; resource keys=", str(CRYPTO_RESOURCES.keys()))
	var inserted_count: int = 0

	for key_symbol: String in CRYPTO_RESOURCES.keys():
		var base_res: Resource = CRYPTO_RESOURCES[key_symbol]
		if base_res == null:
			push_error("_init_crypto_market: base resource for key '" + str(key_symbol) + "' is null")
			continue

		if base_res is Cryptocurrency:
			var base_c: Cryptocurrency = base_res as Cryptocurrency
			print("_init_crypto_market: base '" + str(key_symbol) + "' -> symbol='", str(base_c.symbol), "', name='", str(base_c.display_name), "', price=", str(base_c.price), ", id=", str(base_c.get_instance_id()))

		var crypto_res: Resource = ResourceLoader.load(base_res.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if crypto_res == null:
			push_error("_init_crypto_market: load returned null for key '" + str(key_symbol) + "'")
			continue

		if not (crypto_res is Cryptocurrency):
			push_error("_init_crypto_market: resource for key '" + str(key_symbol) + "' is not a Cryptocurrency (got " + crypto_res.get_class() + ")")
			continue

		var c: Cryptocurrency = crypto_res as Cryptocurrency
		# Do NOT override symbol/display_name; rely on the resource itself.
		print("_init_crypto_market: loaded '", str(key_symbol), "' -> symbol='", str(c.symbol), "', name='", str(c.display_name), "', price=", str(c.price), ", id=", str(c.get_instance_id()))
		print("registering crypto: '", str(c.symbol), "' from key '", str(key_symbol), "', resource_name='", str(c.resource_name), "'")
		register_crypto(c)
		if crypto_market.has(c.symbol):
			inserted_count += 1

	debug_dump_crypto("post_init_loop")

	var expected: Array = CRYPTO_RESOURCES.keys()
	var actual: Array = crypto_market.keys()
	expected.sort()
	actual.sort()
	if expected != actual:
		push_warning("_init_crypto_market: expected symbols " + str(expected) + ", got " + str(actual))

	debug_dump_crypto("post_init")
	emit_signal("crypto_market_ready")
	print("crypto market initialized; inserted count=", str(inserted_count))
	print("crypto market keys: " + str(crypto_market.keys()))
	print("crypto market state: " + JSON.stringify(crypto_market, "	 "))

func _init_stock_market() -> void:
	for symbol: String in STOCK_RESOURCES.keys():
		var stock: Stock = STOCK_RESOURCES[symbol].duplicate(true)
		register_stock(stock)

func _init_market_events() -> void:
	crypto_events.clear()
	stock_events.clear()
	var rng := RNGManager.market_manager.get_rng()
	for key: String in EVENT_RESOURCES.keys():
		var base_res: Resource = EVENT_RESOURCES[key]
		if base_res == null:
			continue
		var event_res: Resource = base_res.duplicate(true)
		if event_res is MarketEvent:
			var ev: MarketEvent = event_res
			if key == "HAWK_PUMP":
				# (Fixed) No ternary operator; choose between HAWK1 and HAWK2.
				var pick: int = rng.randi_range(1, 2)
				if pick == 1:
					ev.target_symbol = "HAWK1"
				else:
					ev.target_symbol = "HAWK2"
			ev.schedule(TimeManager.get_now_minutes(), rng)
			if ev.target_type == "crypto":
				crypto_events[ev.target_symbol] = ev
			elif ev.target_type == "stock":
				stock_events[ev.target_symbol] = ev


## --- SAVELOAD --- ##

func get_save_data() -> Dictionary:
	var stock_data: Dictionary = {}
	for symbol: String in stock_market:
		stock_data[symbol] = stock_market[symbol].to_dict()

	var crypto_data: Dictionary = {}
	for symbol: String in crypto_market:
		crypto_data[symbol] = crypto_market[symbol].to_dict()

	return {
	"stock_market": stock_data,
	"crypto_market": crypto_data
	}

func load_from_data(data: Dictionary) -> void:
	stock_market.clear()
	crypto_market.clear()

	# --- Stocks (unchanged) ---
	# Stock resources use keys like "ALPH_STOCK" but the actual symbol used in
	# save data is stored on the resource itself (e.g. "$ALPH"). When loading
	# we must look up saved values by the stock's symbol instead of the
	# resource key, otherwise prices revert to their default values.
	for res_key: String in STOCK_RESOURCES.keys():
			var stock: Stock = STOCK_RESOURCES[res_key].duplicate(true)
			var stock_symbol := stock.symbol
			var saved_stocks: Dictionary = data.get("stock_market", {})
			if saved_stocks.has(stock_symbol):
					stock.from_dict(saved_stocks[stock_symbol])
			register_stock(stock)

	# --- Cryptos (respect resource-exported symbol/display_name) ---
	var saved_crypto: Dictionary = data.get("crypto_market", {})

	for key_symbol: String in CRYPTO_RESOURCES.keys():
		var base_res: Resource = CRYPTO_RESOURCES[key_symbol]
		if base_res == null:
			push_error("load_from_data: base crypto for key '" + str(key_symbol) + "' is null")
			continue

		var crypto_res: Resource = ResourceLoader.load(base_res.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if crypto_res == null:
			push_error("load_from_data: load returned null for key '" + str(key_symbol) + "'")
			continue

		if not (crypto_res is Cryptocurrency):
			push_error("load_from_data: resource for key '" + str(key_symbol) + "' is not a Cryptocurrency (got " + crypto_res.get_class() + ")")
			continue

		var c: Cryptocurrency = crypto_res as Cryptocurrency

		if saved_crypto.has(key_symbol):
			c.from_dict(saved_crypto[key_symbol])

		if str(c.symbol).is_empty():
			# Fallback only—prefer the .tres value.
			push_warning("load_from_data: '" + str(key_symbol) + "' had empty symbol; setting to key. Fix the .tres.")
			c.symbol = str(key_symbol)

		register_crypto(c)

	debug_dump_crypto("post_load")
	emit_signal("crypto_market_ready")

func debug_dump_crypto(context: String) -> void:
	print("-- crypto dump ", context, " --")
	for symbol: String in crypto_market.keys():
			var c: Cryptocurrency = crypto_market[symbol]
			print(symbol, ",", c.display_name, ", price=", c.price, ", power=", c.power_required, ", id=", str(c.get_instance_id()))

func reset() -> void:
	stock_market.clear()
	crypto_market.clear()
	stock_events.clear()
	crypto_events.clear()
	_init_stock_market()
	_init_crypto_market()
