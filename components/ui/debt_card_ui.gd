extends PanelContainer
class_name DebtCardUI

var debt: DebtResource

@onready var title_label: Label = %TitleLabel
@onready var amount_label: Label = %AmountLabel
@onready var slider: HSlider = %PaySlider
@onready var slider_label: Label = %SliderLabel
@onready var pay_button: Button = %PayButton

func _ready():
    slider.value_changed.connect(_on_slider_changed)
    pay_button.pressed.connect(_on_pay_pressed)

func setup(res: DebtResource) -> void:
    debt = res
    title_label.text = res.name
    update_display()

func update_display() -> void:
    if debt == null:
        return
    var balance = debt.get_balance.call()
    if debt.get_limit.is_valid():
        var limit = debt.get_limit.call()
        amount_label.text = "$%s / $%s" % [NumberFormatter.format_commas(balance), NumberFormatter.format_commas(limit)]
    else:
        amount_label.text = "Owed: $" + NumberFormatter.format_commas(balance)
    var cash = PortfolioManager.cash
    var max_val = min(balance, cash)
    slider.max_value = max_val
    if slider.value > max_val:
        slider.value = max_val
    slider_label.text = "$%.2f" % slider.value

func _on_slider_changed(value: float) -> void:
    slider_label.text = "$%.2f" % value

func _on_pay_pressed() -> void:
    if debt == null:
        return
    var amount = slider.value
    if amount <= 0:
        return
    var success = debt.pay.call(amount)
    if success:
        update_display()
