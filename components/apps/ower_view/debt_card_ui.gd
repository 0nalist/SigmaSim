extends PanelContainer
class_name DebtCardUI

@onready var name_label: Label = %NameLabel
@onready var amount_label: Label = %AmountLabel
@onready var limit_bar: ProgressBar = %LimitBar
@onready var pay_slider: HSlider = %PaySlider
@onready var slider_label: Label = %SliderLabel
@onready var pay_button: Button = %PayButton

var resource_data: Dictionary

func init(resource: Dictionary) -> void:
	resource_data = resource
	pay_slider.value_changed.connect(_on_slider_changed)
	pay_button.pressed.connect(_on_pay_pressed)
	update_display()

func update_display() -> void:
	name_label.text = resource_data.get("name", "")
	var balance: float = resource_data.get("balance", 0.0)
	amount_label.text = "$" + NumberFormatter.format_commas(balance)
	var has_limit: bool = resource_data.get("has_credit_limit", false)
	if has_limit:
		var limit: float = resource_data.get("credit_limit", 0.0)
		limit_bar.max_value = limit
		limit_bar.value = balance
		limit_bar.visible = true
	else:
		limit_bar.visible = false
	update_slider()

func update_slider() -> void:
	var cash: float = PortfolioManager.cash
	var balance: float = resource_data.get("balance", 0.0)
	var max_pay: float = min(balance, cash)
	pay_slider.max_value = max_pay
	if pay_slider.value > max_pay:
		pay_slider.value = max_pay
	slider_label.text = "$%.2f" % pay_slider.value

func _on_slider_changed(value: float) -> void:
	slider_label.text = "$%.2f" % value

func _on_pay_pressed() -> void:
	var amount: float = pay_slider.value
	BillManager.pay_debt(resource_data.get("name", ""), amount)
	update_display()
