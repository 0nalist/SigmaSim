extends BaseAppUI
class_name BrokeRageUI

@onready var stock_market: VBoxContainer = %StockMarket
@onready var cash_label: Label = %CashLabel
@onready var balance_label: Label = %BalanceLabel
@onready var invested_label: Label = %InvestedLabel

@onready var passive_income_label: Label = %PassiveIncomeLabel

var last_invested: float = 0.0


func _ready() -> void:
	app_title = "BrokeRage"
	app_icon = preload("res://assets/AlphaOnline.png")
	emit_signal("title_updated", app_title)

	# Connect signals from PortfolioManager
	PortfolioManager.cash_updated.connect(_on_cash_updated)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	PortfolioManager.investments_updated.connect(_on_investments_updated)
	
	# Initial UI update
	_on_cash_updated(PortfolioManager.cash)
	_on_passive_income_updated(PortfolioManager.get_passive_income())
	_on_investments_updated(PortfolioManager.get_total_investments())

func _on_cash_updated(_cash: float) -> void:
	var cash = PortfolioManager.cash
	var balance = PortfolioManager.get_balance()

	cash_label.text = "Cash: $%.2f" % cash
	balance_label.text = "Balance: $%.2f" % balance

	await get_tree().create_timer(0.2).timeout
	emit_signal("title_updated", "BrokeRage - $%.2f" % cash)

func _on_passive_income_updated(_amount: float) -> void:
	passive_income_label.text = "Passive Income: $%.2f" % PortfolioManager.get_passive_income()

func _on_investments_updated(amount: float):
	var delta = amount - last_invested
	last_invested = amount

	invested_label.text = "Invested: $%.2f" % amount

	if delta > 0.01:
		flash_invested_label(Color.GREEN)
	elif delta < -0.01:
		flash_invested_label(Color.RED)

func flash_invested_label(color: Color) -> void:
	invested_label.add_theme_color_override("font_color", color)
	await get_tree().create_timer(0.4).timeout
	invested_label.remove_theme_color_override("font_color")


func _on_resource_changed(name: String, _value: float) -> void:
	if name == "cash":
		_on_cash_updated(PortfolioManager.cash)
	elif name == "passive_income":
		_on_passive_income_updated(PortfolioManager.get_passive_income())
