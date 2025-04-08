extends BaseAppUI
class_name BrokeRageUI


@onready var stock_market: VBoxContainer = $TabContainer/StockMarket
@onready var cash_label: Label = %CashLabel
@onready var balance_label: Label = %BalanceLabel
@onready var passive_income_label: Label = %PassiveIncomeLabel


func _ready() -> void:
	app_title = "BrokeRage"
	app_icon = preload("res://assets/AlphaOnline.png")
	emit_signal("title_updated", app_title)
	MoneyManager.update_cash.connect(_on_cash_updated)
	MoneyManager.update_passive_income.connect(_on_passive_income_updated)

	# Emit updates immediately
	_on_cash_updated(MoneyManager.cash)
	_on_passive_income_updated(MoneyManager.get_passive_income())

func _on_cash_updated(_delta) -> void:
	var cash = MoneyManager.cash
	var balance = MoneyManager.get_balance()

	cash_label.text = "Cash: $" + str(cash)
	balance_label.text = "Balance: $" + str(balance)

	await get_tree().create_timer(0.2).timeout
	emit_signal("title_updated", "BrokeRage - $" + str(cash))

func _on_passive_income_updated(_amount) -> void:
	passive_income_label.text = "Passive Income: $" + str(MoneyManager.get_passive_income())
