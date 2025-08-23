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

var stock: Stock
var _series_id: String = ""

func setup_custom(args) -> void:
	if args is Stock:
		setup(args)

func setup(_stock: Stock) -> void:
        stock = _stock
        _series_id = "stock_price_%s" % stock.symbol
        price_chart.clear_series()
        price_chart.lock_y_min = true
        price_chart.lock_x_min = true
        price_chart.add_series(_series_id, stock.symbol, Color.LIME_GREEN)
        var now: int = TimeManager.get_now_minutes()
        HistoryManager.add_sample(_series_id, now, stock.price)
        _update_ui()
        window_title = str(stock.symbol) + " " + str(stock.price)
        # Connect signal
        MarketManager.stock_price_updated.connect(_on_stock_price_updated)

func _on_stock_price_updated(symbol: String, updated_stock: Stock) -> void:
        if stock == null or updated_stock.symbol != stock.symbol:
                return
        stock = updated_stock
        var now: int = TimeManager.get_now_minutes()
        HistoryManager.add_sample(_series_id, now, stock.price)
        _update_ui()

func _update_ui() -> void:
	window_title = str(stock.symbol) + " " + str(stock.price)
	label_symbol.text = "Symbol: " + stock.symbol
	label_price.text = "Price: $" + str(stock.price)
	label_intrinsic.text = "Intrinsic Value: $" + str(stock.intrinsic_value)
	label_trailing.text = "Trailing Avg: $" + str(stock.trailing_average)
	label_sentiment.text = "Sentiment: " + str(stock.sentiment)
	label_volatility.text = "Volatility: " + str(stock.volatility)
	label_momentum.text = "Momentum: " + str(stock.momentum)
	label_owned.text = "Shares Owned: " + str(PortfolioManager.stocks_owned.get(stock.symbol, 0))
