extends Pane
class_name BrokeRage

@onready var stock_market: VBoxContainer = %StockMarket
@onready var cash_label: Label = %CashLabel
@onready var balance_label: Label = %BalanceLabel
@onready var invested_label: Label = %InvestedLabel
@onready var debt_label: Label = %DebtLabel


@onready var passive_income_label: Label = %PassiveIncomeLabel

var last_invested: float = 0.0


func _ready() -> void:
	#app_title = "BrokeRage"
	#app_icon = preload("res://assets/AlphaOnline.png")
	#emit_signal("title_updated", app_title)

	# Connect signals from PortfolioManager
	PortfolioManager.cash_updated.connect(_on_cash_updated)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	PortfolioManager.investments_updated.connect(_on_investments_updated)
	
	await get_tree().process_frame
	# Initial UI update
	_on_cash_updated(PortfolioManager.cash)
	_on_passive_income_updated(PortfolioManager.get_passive_income())
	_on_investments_updated(PortfolioManager.get_total_investments())
	_on_debt_updated()
	MarketManager.refresh_prices()

func _on_cash_updated(_cash: float) -> void:
	var cash = PortfolioManager.cash
	var balance = PortfolioManager.get_balance()

	cash_label.text = "Cash: $" + NumberFormatter.format_number(PortfolioManager.cash)
	balance_label.text = "Net Worth: $" + str(NumberFormatter.format_number(PortfolioManager.get_balance()))

	await get_tree().process_frame
	emit_signal("title_updated", "BrokeRage - $%.2f" % cash) # Not currently working



func _on_passive_income_updated(_amount: float) -> void:
	passive_income_label.text = "Passive Income: $%.2f" % PortfolioManager.get_passive_income()

func _on_investments_updated(amount: float):
	var delta = amount - last_invested
	last_invested = amount

	invested_label.text = "Invested: $" + str(NumberFormatter.format_number(amount))
	balance_label.text = "Net Worth: $" + str(NumberFormatter.format_number(PortfolioManager.get_balance()))
		
	
	if delta > 0.01:
		flash_invested_label(Color.GREEN)
	elif delta < -0.01:
		flash_invested_label(Color.RED)

func flash_invested_label(color: Color) -> void:
	invested_label.add_theme_color_override("font_color", color)
	await get_tree().create_timer(0.4).timeout
	invested_label.remove_theme_color_override("font_color")


func _on_resource_changed(resource: String, _value: float) -> void:
	if resource == "cash":
		_on_cash_updated(PortfolioManager.cash)
	elif resource == "passive_income":
		_on_passive_income_updated(PortfolioManager.get_passive_income())
	elif resource == "debt":
		_on_debt_updated()

func _on_debt_updated() -> void:
	debt_label.text = "Debt: $" + NumberFormatter.format_number(PortfolioManager.get_total_debt())


func _on_ower_view_button_pressed() -> void:
	WindowManager.launch_app_by_name("OwerView")
