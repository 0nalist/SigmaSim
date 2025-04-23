extends VBoxContainer
class_name LoanCard

signal pay_requested(amount: float)

@onready var title_label := %LoanTitleLabel
@onready var amount_label := %LoanAmountLabel
@onready var slider := %PaySlider
@onready var slider_value_label := %PayLabel
@onready var pay_button := %PayButton

var loan_name: String = ""
var get_balance_func: Callable
var pay_func: Callable

func _ready():
	slider.value_changed.connect(_on_slider_value_changed)
	pay_button.pressed.connect(_on_pay_button_pressed)

func init(title: String, get_balance: Callable, pay: Callable):
	loan_name = title
	get_balance_func = get_balance
	pay_func = pay
	title_label.text = title
	update_ui()

func update_ui():
	var owed = get_balance_func.call()
	var cash := PortfolioManager.cash
	var max_val = min(owed, cash)

	amount_label.text = "Owed: $%.2f" % owed
	slider.max_value = max_val
	if slider.value > max_val:
		slider.value = max_val
	slider_value_label.text = "$%.2f" % slider.value

func _on_slider_value_changed(value: float):
	slider_value_label.text = "$%.2f" % value

func _on_pay_button_pressed():
	var value = slider.value
	if value <= 0:
		return
	var success = pay_func.call(value)
	if success:
		update_ui()
