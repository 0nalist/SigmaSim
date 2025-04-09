extends Node
#Autoload name PortfolioManager

## --- Basic numeric resources
var cash: float = 0.0
var debt: float = 0.0
var rent: float = 0.0
var interest: float = 0.0

## --- Income sources
var employee_income: float = 0.0
var passive_income: float = 0.0

## --- Stocks and owned counts
var stock_data: Dictionary = {}     # symbol: Stock
var stocks_owned: Dictionary = {}   # symbol: int

## --- Future complex resources
var subcontractors: Array[Dictionary] = []
var miners: Dictionary = {}
var businesses: Dictionary = {}
var employees: Dictionary = {}

## --- Signals
signal cash_updated(new_cash: float)
signal stock_updated(symbol: String, new_stock: Stock)
signal resource_changed(name: String, value: float)
signal investments_updated(amount: float)

func _ready():
	MarketManager.stock_price_updated.connect(_on_stock_price_updated)


## --- Cash Methods
func add_cash(amount: float):
	if amount < 0.0:
		printerr("Tried to add negative cash")
		return
	cash = snapped(cash + amount, 0.01)
	emit_signal("cash_updated", cash)
	emit_signal("resource_changed", "cash", cash)

func spend_cash(amount: float):
	if amount < 0.0:
		printerr("Tried to spend negative cash")
		return
	cash = snapped(cash - amount, 0.01)
	emit_signal("cash_updated", cash)
	emit_signal("resource_changed", "cash", cash)

func get_balance() -> float:
	return snapped(cash + get_total_investments() - debt, 0.01)

func get_passive_income() -> float:
	return snapped(rent + employee_income + interest / 365.0 / 24.0 / 60.0 / 60.0, 0.01)

## --- Stock Methods
func buy_stock(symbol: String) -> bool:
	var stock = stock_data.get(symbol)
	if stock == null or cash < stock.price:
		return false

	spend_cash(stock.price)
	stocks_owned[symbol] = stocks_owned.get(symbol, 0) + 1
	emit_signal("stock_updated", symbol, stock)
	#emit_investment_update()
	return true

func sell_stock(symbol: String) -> bool:
	if stocks_owned.get(symbol, 0) <= 0:
		return false

	var stock = stock_data.get(symbol)
	add_cash(stock.price)
	stocks_owned[symbol] -= 1
	emit_signal("stock_updated", symbol, stock)
	#emit_investment_update()
	return true

func get_total_investments() -> float:
	var total := 0.0
	for symbol in stocks_owned:
		var owned = stocks_owned[symbol]
		var stock = stock_data.get(symbol)
		if stock:
			total += stock.price * owned
	return snapped(total, 0.01)

# Subcontractor tracking

func hire_subcontractor(template: Subcontractor):
	var new_sub = {
		"resource": template,
		"remaining_time": template.contract_length
	}
	subcontractors.append(new_sub)

func update_subcontractors(delta: float):
	var i := 0
	while i < subcontractors.size():
		subcontractors[i]["remaining_time"] -= delta
		if subcontractors[i]["remaining_time"] <= 0.0:
			subcontractors.remove_at(i)
		else:
			i += 1

func get_total_dps() -> float:
	var total := 0.0
	for sub in subcontractors:
		total += sub["resource"].dollar_per_second
	return total

func get_subcontractor_count() -> int:
	return subcontractors.size()


# Emit signal methods

func emit_investment_update():
	emit_signal("investments_updated", get_total_investments())


# Connected signals
func _on_stock_price_updated(symbol: String, stock: Stock) -> void:
	# Update our copy
	stock_data[symbol] = stock
	emit_signal("stock_updated", symbol, stock)
	emit_investment_update()
