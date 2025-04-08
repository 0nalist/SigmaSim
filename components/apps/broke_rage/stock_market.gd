# stock_market.gd
extends VBoxContainer

@export var stock_list: Array[Stock]
@export var stock_row_scene: PackedScene  # Drag in StockRow.tscn here

var stock_rows: Dictionary = {}  # key: symbol, value: StockRow instance

func _ready():
	for stock in stock_list:
		var row = stock_row_scene.instantiate() as StockRow
		add_child(row)
		row.setup(stock)

		row.buy_pressed.connect(_on_buy_button_pressed)
		row.sell_pressed.connect(_on_sell_button_pressed)

		
		stock_rows[stock.symbol] = row

func _on_timer_timeout() -> void:
	for stock in stock_list:
		# Decrease momentum, possibly reset sentiment
		stock.momentum -= 1
		if stock.momentum <= 0:
			stock.sentiment = randf_range(-1.0, 1.0)
			stock.momentum = randi_range(5, 20)  # e.g., hold sentiment for 5–20 ticks
			

		# Calculate random noise and sentiment bias
		var noise = randf_range(-1.0, 1.0)
		var base_fluctuation = stock.price / 100.0 * stock.volatility
	
		var total_fluctuation = base_fluctuation * (noise + stock.sentiment)
		var delta = round(total_fluctuation)

		# Clamp and apply price
		stock.price = max(stock.price + delta, 1)
		
		if stock.price < 3:
			if randf_range(0.00, 1.00) < stock.sentiment:
				stock.price += 1
		
		# Update the stock's UI row
		stock_rows[stock.symbol].update_display()
		#stock_rows[stock.symbol].update_sentiment_arrow(stock.sentiment) #moved into udpate_display()

func _on_buy_button_pressed(symbol: String):
	var stock = get_stock(symbol)
	if MoneyManager.cash < stock.price:
		print("Insufficient funds!")
		return
	MoneyManager.spend_cash(stock.price)
	stock.owned += 1
	stock_rows[symbol].update_display()
	MoneyManager.update_investments.emit(MoneyManager.get_investments())

func _on_sell_button_pressed(symbol: String):
	var stock = get_stock(symbol)
	if stock.owned < 1:
		print("No stocks owned!")
		return
	MoneyManager.add_cash(stock.price)
	stock.owned -= 1
	stock_rows[symbol].update_display()

func get_stock(symbol: String) -> Stock:
	for stock in stock_list:
		if stock.symbol == symbol:
			return stock
	return null
