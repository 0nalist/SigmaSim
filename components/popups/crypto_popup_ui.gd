extends Pane
class_name CryptoPopupUI

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

var crypto: Cryptocurrency

func setup_custom(args) -> void:
        if args is Cryptocurrency:
                setup(args)

func setup(_crypto: Cryptocurrency) -> void:
        crypto = _crypto
        HistoryManager.add_sample(crypto.symbol, TimeManager.get_now_minutes(), crypto.price)
        price_chart.clear_series()
        price_chart.add_series(crypto.symbol, "Price", Color(1, 0.6, 0.2))
        _update_ui()
        window_title = str(crypto.symbol) + " " + str(crypto.price)
        MarketManager.crypto_price_updated.connect(_on_crypto_price_updated)

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
