extends VBoxContainer

#@export var stock_list: Array[Stock]
@export var stock_row_scene: PackedScene  # Drag in StockRow.tscn here

var stock_rows: Dictionary = {}  # key: symbol, value: StockRow instance

func _ready():
	# Rebuild from current MarketManager.stock_market
	refresh_rows_from_market()

	# Connect for live updates
	MarketManager.stock_price_updated.connect(_on_stock_updated)

func refresh_rows_from_market():
	for row in stock_rows.values():
		row.queue_free()
	stock_rows.clear()

	for symbol in MarketManager.stock_market:
		var stock = MarketManager.get_stock(symbol)
		PortfolioManager.stock_data[stock.symbol] = stock

		var row = stock_row_scene.instantiate() as StockRow
		add_child(row)
		row.setup(stock)
		row.buy_pressed.connect(_on_buy_button_pressed)
		row.sell_pressed.connect(_on_sell_button_pressed)
		stock_rows[stock.symbol] = row



func _on_buy_button_pressed(symbol: String):
	if !PortfolioManager.buy_stock(symbol):
		print("Failed to buy stock:", symbol)

func _on_sell_button_pressed(symbol: String):
	if !PortfolioManager.sell_stock(symbol):
		print("Failed to sell stock:", symbol)

func _on_stock_updated(symbol: String, updated_stock: Stock):
	if stock_rows.has(symbol):
		stock_rows[symbol].update_display(updated_stock)
