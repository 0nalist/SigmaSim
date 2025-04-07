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

	# Ensure pivot is centered
	arrow.set_pivot_offset(arrow.size / 2)

	# Clamp and convert sentiment to angle (down to up)
	sentiment = clamp(sentiment, -1.0, 1.0)
	var angle_deg = lerp(180.0, 0.0, (sentiment + 1.0) / 2.0)
	arrow.rotation_degrees = angle_deg

	# Color based on direction
	if sentiment > 0.05:
		arrow.modulate = Color.GREEN
	elif sentiment < -0.05:
		arrow.modulate = Color.RED
	else:
		arrow.modulate = Color(0.6, 0.6, 0.6)  # Neutral gray
