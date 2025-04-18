extends VBoxContainer

@export var stock_list: Array[Stock]
@export var stock_row_scene: PackedScene  # Drag in StockRow.tscn here

var stock_rows: Dictionary = {}  # key: symbol, value: StockRow instance

func _ready():
	# Register stocks into PortfolioManager
	for stock in stock_list:
		PortfolioManager.stock_data[stock.symbol] = stock
		MarketManager.register_stock(stock)

		var row = stock_row_scene.instantiate() as StockRow
		add_child(row)
		row.setup(stock)
		row.buy_pressed.connect(_on_buy_button_pressed)
		row.sell_pressed.connect(_on_sell_button_pressed)
		stock_rows[stock.symbol] = row
	
	# Listen for price/ownership updates
	MarketManager.stock_price_updated.connect(_on_stock_updated)

func _on_buy_button_pressed(symbol: String):
	if !PortfolioManager.buy_stock(symbol):
		print("Failed to buy stock:", symbol)

func _on_sell_button_pressed(symbol: String):
	if !PortfolioManager.sell_stock(symbol):
		print("Failed to sell stock:", symbol)

func _on_stock_updated(symbol: String, updated_stock: Stock):
	if stock_rows.has(symbol):
		stock_rows[symbol].update_display(updated_stock)
