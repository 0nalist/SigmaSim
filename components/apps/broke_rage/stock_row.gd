extends GridContainer
class_name StockRow

signal buy_pressed(stock_symbol: String, quantity: int)
signal sell_pressed(stock_symbol: String, quantity: int)

@onready var stock_label: Label = %StockLabel
@onready var buy_button: Button = $BuyButton
@onready var sell_button: Button = $SellButton
@onready var quantity_spinbox: SpinBox = $QuantitySpinBox
@onready var owned_label: Label = $OwnedLabel
@onready var arrow = $SentimentArrow

var stock: Stock

var last_price: float = 0.0

func setup(_stock: Stock) -> void:
	stock = _stock
	last_price = stock.price
	update_display(stock)

	buy_button.pressed.connect(func():
		var quantity := int(quantity_spinbox.value)
		var price := stock.price * quantity
		if PortfolioManager.get_cash() < price and UpgradeManager.get_level("brokerage_pattern_day_trader") <= 0:
			print("Credit purchase requires Pattern Day Trader upgrade")
			return
		emit_signal("buy_pressed", stock.symbol, quantity)
		update_display(stock)
	)
	sell_button.pressed.connect(func():
		var quantity := int(quantity_spinbox.value)
		emit_signal("sell_pressed", stock.symbol, quantity)
		update_display(stock)
	)
	

func update_display(updated_stock: Stock) -> void:
	var previous_price = last_price
	last_price = updated_stock.price
	stock = updated_stock  # Update reference
	
	var owned = PortfolioManager.stocks_owned.get(stock.symbol, 0)
	var value = stock.price * owned

	stock_label.text = " %s $%.2f" % [stock.symbol, stock.price]
	owned_label.text = "%d shares ($%.2f)" % [owned, value]

	# Animate price color if changed
	if stock.price > previous_price:
		flash_price_color(Color.GREEN)
	elif stock.price < previous_price:
		flash_price_color(Color.RED)

	update_sentiment_arrow(stock.sentiment)

func flash_price_color(color: Color) -> void:
	stock_label.add_theme_color_override("font_color", color)
	#await get_tree().create_timer(.4).timeout
	#stock_label.remove_theme_color_override("font_color")

func update_sentiment_arrow(sentiment: float) -> void:
	arrow.pivot_offset = arrow.size / 2  # Ensure centered rotation

	sentiment = clamp(sentiment, -1.0, 1.0)
	var angle_deg = lerp(180.0, 0.0, (sentiment + 1.0) / 2.0)
	arrow.rotation_degrees = angle_deg

	if sentiment > 0.05:
		arrow.modulate = Color.GREEN
	elif sentiment < -0.05:
		arrow.modulate = Color.RED
	else:
		arrow.modulate = Color(0.6, 0.6, 0.6)  # Neutral


func _on_stock_label_gui_input(event: InputEvent) -> void:
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
                var popup_scene = preload("res://components/popups/stock_popup_ui.tscn")
                var stock_popup = popup_scene.instantiate() as Pane
                WindowManager.launch_pane_instance(stock_popup, stock.symbol)
