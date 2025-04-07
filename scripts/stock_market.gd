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
		var delta = randi_range(-stock.price / 100 * stock.volatility, stock.price / 100 * stock.volatility)
		stock.price += int(delta)
		stock_rows[stock.symbol].update_display()

func _on_buy_button_pressed(symbol: String):
	var stock = get_stock(symbol)
	if MoneyManager.cash < stock.price:
		print("Insufficient funds!")
		return
	MoneyManager.spend_cash(stock.price)
	stock.owned += 1
	stock_rows[symbol].update_display()

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
