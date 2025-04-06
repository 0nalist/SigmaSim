#stock_market.gd
extends VBoxContainer

var tsla_price: int = 420
var tsla_volatility: float = 1.45
var tsla_owned: int = 0
@onready var tsla_label: Label = %TSLALabel
@onready var owned_tsla_label: Label = $GridContainer/OwnedTSLALabel


func _on_timer_timeout() -> void:
	tsla_price += randi_range(-tsla_price/100*tsla_volatility, tsla_price/100*tsla_volatility)
	update_stock_labels()

func update_stock_labels():
	%TSLALabel.text = " $TSLA: $" + str(tsla_price)


func _on_buy_tesla_button_pressed() -> void:
	if MoneyManager.cash < tsla_price:
		print("insufficient funds!")
		return
	MoneyManager.spend_cash(tsla_price)
	tsla_owned += 1
	update_owned_tsla()


func _on_sell_tesla_button_pressed() -> void:
	if tsla_owned < 1:
		print("no stocks owned!")
		return
	MoneyManager.add_cash(tsla_price)
	tsla_owned -= 1
	update_owned_tsla()

func update_owned_tsla():
	owned_tsla_label.text = str(tsla_owned)
