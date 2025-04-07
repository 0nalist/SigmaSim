# stock_row.gd
extends GridContainer
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
	stock_label.text = " $" + stock.symbol + " - $" + str(stock.price)
	owned_label.text = str(stock.owned) + " : $" + str(stock.price*stock.owned)
	update_sentiment_arrow(stock.sentiment)

func update_sentiment_arrow(sentiment: float) -> void:
	var arrow = $SentimentArrow

	# Make sure pivot is centered
	arrow.set_pivot_offset(arrow.size / 2)

	# Clamp and map sentiment to rotation from -90 (up) to +90 (down)
	sentiment = clamp(sentiment, -1.0, 1.0)
	var angle_deg = -sentiment * 90.0  # <-- Negate it to rotate correctly

	arrow.rotation_degrees = angle_deg

	# Set color
	if sentiment > 0.05:
		arrow.modulate = Color.GREEN
	elif sentiment < -0.05:
		arrow.modulate = Color.RED
	else:
		arrow.modulate = Color(0.6, 0.6, 0.6)
