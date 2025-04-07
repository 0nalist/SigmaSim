# stock_row.gd
extends HBoxContainer
class_name StockRow

signal buy_pressed(stock_symbol: String)
signal sell_pressed(stock_symbol: String)

@onready var stock_label: Label = %StockLabel
@onready var buy_button: Button = $BuyButton
@onready var sell_button: Button = $SellButton
@onready var owned_label: Label = $OwnedLabel



var stock: Stock

func setup(_stock: Stock) -> void:
	stock = _stock
	update_display()
	buy_button.pressed.connect(func(): emit_signal("buy_pressed", stock.symbol))
	sell_button.pressed.connect(func(): emit_signal("sell_pressed", stock.symbol))


func update_display():
	stock_label.text = " $" + stock.symbol + ": $" + str(stock.price)
	owned_label.text = str(stock.owned) + " : " + str(stock.price*stock.owned)
