extends Pane
class_name CryptoPopupUI

#@export var persist_on_save := true

@onready var label_symbol: Label = %LabelSymbol
@onready var label_name: Label = %LabelName
@onready var label_price: Label = %LabelPrice
@onready var label_volatility: Label = %LabelVolatility
@onready var label_block_size: Label = %LabelBlockSize
@onready var label_block_time: Label = %LabelBlockTime
@onready var label_power: Label = %LabelPower
@onready var label_all_time_high: Label = %LabelAllTimeHigh
@onready var label_owned: Label = %LabelOwned
@onready var price_chart: ChartComponent = %PriceChart
@onready var buy_button: Button = %BuyButton
@onready var sell_button: Button = %SellButton
@onready var quantity_spinbox: SpinBox = %QuantitySpinBox

var crypto: Cryptocurrency

func setup_custom(args) -> void:
	if args is Cryptocurrency:
		await setup(args)

func setup(_crypto: Cryptocurrency) -> void:
	crypto = _crypto
	unique_popup_key = "crypto_%s" % crypto.symbol
	HistoryManager.add_sample(crypto.symbol, TimeManager.get_now_minutes(), crypto.price)
	
	await ready
	
	price_chart.clear_series()
	price_chart.add_series(crypto.symbol, "Price", Color(1, 0.6, 0.2))
	_update_ui()
	window_title = str(crypto.symbol) + " " + str(crypto.price)
	MarketManager.crypto_price_updated.connect(_on_crypto_price_updated)

func _ready() -> void:
	super._ready()
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)

func _on_crypto_price_updated(symbol: String, updated_crypto: Cryptocurrency) -> void:
	if crypto == null or updated_crypto.symbol != crypto.symbol:
			return
	crypto = updated_crypto
	_update_ui()

func _update_ui() -> void:
	window_title = str(crypto.symbol) + " " + str(crypto.price)
	label_symbol.text = crypto.symbol
	label_name.text = crypto.display_name
	label_price.text = "$%.2f" % crypto.price
	label_volatility.text = "%.2f" % crypto.volatility
	label_block_size.text = "%.2f" % crypto.block_size
	label_block_time.text = "%.2f" % crypto.block_time
	label_power.text = str(crypto.power_required)
	label_all_time_high.text = "$%.2f" % crypto.all_time_high
	label_owned.text = "%.4f" % PortfolioManager.get_crypto_amount(crypto.symbol)

func _on_buy_pressed() -> void:
	if crypto:
		var amount := quantity_spinbox.value
		if PortfolioManager.attempt_spend(crypto.price * amount):
			PortfolioManager.add_crypto(crypto.symbol, amount)
			_update_ui()

func _on_sell_pressed() -> void:
	if crypto:
		var amount := quantity_spinbox.value
		if PortfolioManager.sell_crypto(crypto.symbol, amount):
			_update_ui()


func get_custom_save_data() -> Dictionary:
	if crypto:
			return {"symbol": crypto.symbol}
	return {}

func load_custom_save_data(data: Dictionary) -> void:
	var symbol: String = data.get("symbol", "")
	if symbol != "":
		var c: Cryptocurrency = MarketManager.crypto_market.get(symbol)
		if c:
			await ready   # or call_deferred("setup", c)
			setup(c)
