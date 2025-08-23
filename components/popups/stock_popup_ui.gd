extends Pane
class_name StockPopupUI

@onready var label_symbol = %LabelSymbol
@onready var label_price = %LabelPrice
@onready var label_intrinsic = %LabelIntrinsic
@onready var label_trailing = %LabelTrailing
@onready var label_sentiment = %LabelSentiment
@onready var label_volatility = %LabelVolatility
@onready var label_momentum = %LabelMomentum
@onready var label_owned = %LabelOwnership
@onready var price_chart: ChartComponent = %PriceChart
@onready var buy_button: Button = %BuyButton
@onready var sell_button: Button = %SellButton

var stock: Stock

func setup_custom(args) -> void:
	if args is Stock:
		setup(args)

func setup(_stock: Stock) -> void:
		stock = _stock
		HistoryManager.add_sample(stock.symbol, TimeManager.get_now_minutes(), stock.price)
		price_chart.clear_series()
		price_chart.add_series(stock.symbol, "Price", Color.GREEN)
		_update_ui()
		window_title = str(stock.symbol) + " " + str(stock.price)
		# Connect signal
                MarketManager.stock_price_updated.connect(_on_stock_price_updated)

func _ready() -> void:
                super._ready()
                buy_button.pressed.connect(_on_buy_pressed)
                sell_button.pressed.connect(_on_sell_pressed)

func _on_stock_price_updated(symbol: String, updated_stock: Stock) -> void:
	if stock == null or updated_stock.symbol != stock.symbol:
		return
	stock = updated_stock
	_update_ui()

func _update_ui() -> void:
                window_title = str(stock.symbol) + " " + str(stock.price)
                label_symbol.text = stock.symbol
                label_price.text = "$%.2f" % stock.price
                label_intrinsic.text = "$%.2f" % stock.intrinsic_value
                label_trailing.text = "$%.2f" % stock.trailing_average
                label_sentiment.text = "%.2f" % stock.sentiment
                label_volatility.text = "%.2f" % stock.volatility
                label_momentum.text = "%.2f" % stock.momentum
                label_owned.text = str(PortfolioManager.stocks_owned.get(stock.symbol, 0))

func _on_buy_pressed() -> void:
                if stock and PortfolioManager.buy_stock(stock.symbol):
                                _update_ui()

func _on_sell_pressed() -> void:
                if stock and PortfolioManager.sell_stock(stock.symbol):
                                _update_ui()
