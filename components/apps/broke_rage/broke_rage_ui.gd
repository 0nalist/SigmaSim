extends Pane
class_name BrokeRage

@onready var stock_market: VBoxContainer = %StockMarket

@onready var cash_label: Label = %CashLabel
@onready var balance_label: Label = %BalanceLabel
@onready var invested_label: Label = %InvestedLabel
@onready var debt_label: Label = %DebtLabel

@onready var net_worth_chart: ChartComponent = %NetWorthChart

@onready var passive_income_label: Label = %PassiveIncomeLabel

@onready var summary_tab_button: Button = %SummaryTabButton
@onready var charts_tab_button: Button = %ChartsTabButton
@onready var summary_view: VBoxContainer = %SummaryView
@onready var charts_view: VBoxContainer = %ChartsView

@onready var charts_summary_tab_button: Button = %SummaryTabButtonCharts
@onready var charts_charts_tab_button: Button = %ChartsTabButtonCharts
@onready var charts_cash_label: Label = %ChartsCashLabel
@onready var charts_portfolio_label: Label = %ChartsPortfolioLabel

@onready var charts_content: Control = _ensure_charts_content()
var stock_popup_scene: PackedScene = preload("res://components/popups/stock_popup_ui.tscn")

func _ensure_charts_content() -> Control:
		var existing: Node = charts_view.get_node_or_null("ChartsContent")
		if existing != null and existing is Control:
				return existing as Control

		var content: VBoxContainer = VBoxContainer.new()
		content.name = "ChartsContent"
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 16)
		charts_view.add_child(content)
		return content



var last_invested: float = 0.0
var _active_tab: StringName = &"Summary"


func _add_net_worth_sample() -> void:
	HistoryManager.add_sample("net_worth", TimeManager.get_now_minutes(), PortfolioManager.get_balance())


func _ready() -> void:
	#app_title = "BrokeRage"
	#app_icon = preload("res://assets/AlphaOnline.png")
	#emit_signal("title_updated", app_title)

	# Connect signals from PortfolioManager
	PortfolioManager.cash_updated.connect(_on_cash_updated)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	PortfolioManager.investments_updated.connect(_on_investments_updated)

	net_worth_chart.add_series("net_worth", "Net Worth")

	summary_tab_button.pressed.connect(_on_summary_tab_pressed)
	charts_tab_button.pressed.connect(_on_charts_tab_pressed)

	await get_tree().process_frame
	# Initial UI update
	_on_cash_updated(PortfolioManager.cash)
	_on_passive_income_updated(PortfolioManager.passive_income)
	_on_investments_updated(PortfolioManager.get_total_investments())
	_on_debt_updated()
	MarketManager.refresh_prices()

	_build_charts_view()
	_activate_tab(&"Summary")

func _on_cash_updated(_cash: float) -> void:
	var cash = PortfolioManager.cash
	var balance = PortfolioManager.get_balance()

	cash_label.text = "Cash: $" + NumberFormatter.format_number(cash)
	balance_label.text = "Net Worth: $" + str(NumberFormatter.format_number(balance))
	charts_cash_label.text = "Cash: $" + NumberFormatter.format_number(cash)

	HistoryManager.add_sample("cash", TimeManager.get_now_minutes() / 1000.0, cash)
	_add_net_worth_sample()

	await get_tree().process_frame
	#emit_signal("title_updated", "BrokeRage - $%.2f" % cash) # Not currently working



func _on_passive_income_updated(_amount: float) -> void:
	passive_income_label.text = "Passive Income: $%.2f" % PortfolioManager.passive_income

func _on_investments_updated(amount: float):
	var delta = amount - last_invested
	last_invested = amount

	invested_label.text = "Invested: $" + str(NumberFormatter.format_number(amount))
	balance_label.text = "Net Worth: $" + str(NumberFormatter.format_number(PortfolioManager.get_balance()))
	charts_portfolio_label.text = "Stocks: $" + str(NumberFormatter.format_number(amount))
	#TODO: ^Fix: Invalid assignment of property or key 'text' with value of type 'String' on a base object of type 'previously freed'.

	if delta > 0.01:
			flash_invested_label(Color.GREEN)
	elif delta < -0.01:
			flash_invested_label(Color.RED)
	_add_net_worth_sample()

func flash_invested_label(color: Color) -> void:
	invested_label.add_theme_color_override("font_color", color)
	await get_tree().create_timer(0.4).timeout
	invested_label.remove_theme_color_override("font_color")


func _on_resource_changed(resource: String, _value: float) -> void:
	if resource == "cash":
		_on_cash_updated(PortfolioManager.cash)
	elif resource == "passive_income":
		_on_passive_income_updated(PortfolioManager.passive_income)
	elif resource == "debt":
		_on_debt_updated()

func _on_debt_updated() -> void:
		debt_label.text = "Debt: $" + NumberFormatter.format_number(PortfolioManager.get_total_debt())
		_add_net_worth_sample()


func _on_wallet_button_pressed() -> void:
		WindowManager.launch_app_by_name("Wallet")

func _on_ower_view_button_pressed() -> void:

		WindowManager.launch_app_by_name("OwerView")


func _activate_tab(tab_name: StringName) -> void:
	if tab_name == &"Summary":
		if is_instance_valid(summary_tab_button):
			summary_tab_button.set_pressed(true)
		if is_instance_valid(charts_tab_button):
			charts_tab_button.set_pressed(false)
		if is_instance_valid(charts_summary_tab_button):
			charts_summary_tab_button.set_pressed(true)
		if is_instance_valid(charts_charts_tab_button):
			charts_charts_tab_button.set_pressed(false)

		summary_view.visible = true
		charts_view.visible = false
	else:
		if is_instance_valid(summary_tab_button):
			summary_tab_button.set_pressed(false)
		if is_instance_valid(charts_tab_button):
			charts_tab_button.set_pressed(true)
		if is_instance_valid(charts_summary_tab_button):
			charts_summary_tab_button.set_pressed(false)
		if is_instance_valid(charts_charts_tab_button):
			charts_charts_tab_button.set_pressed(true)

		summary_view.visible = false
		charts_view.visible = true

	_active_tab = tab_name


func _on_summary_tab_pressed() -> void:
		_activate_tab(&"Summary")

func _on_charts_tab_pressed() -> void:
		_activate_tab(&"Charts")


func _build_charts_view() -> void:
		# Only clear dynamic chart content, not the tab buttons or labels.
		for child: Node in charts_content.get_children():
				child.queue_free()

		var symbols := MarketManager.stock_market.keys()
		for i in range(symbols.size()):
				var symbol: String = symbols[i]
				var stock: Stock = MarketManager.get_stock(symbol)
				var popup: StockPopupUI = stock_popup_scene.instantiate()
				popup.custom_minimum_size = Vector2(350, 150)
				popup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				popup.size_flags_vertical = Control.SIZE_EXPAND_FILL
				popup.setup(stock)
				charts_content.add_child(popup)

				if i < symbols.size() - 1:
						var spacer: Control = Control.new()
						spacer.custom_minimum_size = Vector2(0, 12)
						charts_content.add_child(spacer)
