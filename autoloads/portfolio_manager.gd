extends Node
#Autoload name PortfolioManager

## --- Basic numeric resources
var cash: float = 201.0
var debt: float = 0.0
var rent: float = 0.0
var interest: float = 0.0

## --- Credit Card resources
var credit_limit: float = 2000.0
var credit_used: float = 0.0
var credit_interest_rate: float = 0.3  # 30% by default

## --- Income sources
var employee_income: float = 0.0
var passive_income: float = 0.0

## --- Stocks and owned counts
var stock_data: Dictionary = {}     # symbol: Stock
var stocks_owned: Dictionary = {}   # symbol: int

## --- Crypto and owned counts
var crypto_owned: Dictionary = {}  # symbol: float

## --- Future complex resources
var subcontractors: Array[Dictionary] = []
var miners: Dictionary = {}
var businesses: Dictionary = {}
var employees: Dictionary = {}

## --- Signals
signal cash_updated(new_cash: float)
signal credit_updated(used: float, limit: float)
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

func can_pay_with_cash(amount: float) -> bool:
	return cash >= amount

func pay_with_cash(amount: float) -> bool:
	if can_pay_with_cash(amount):
		cash -= amount
		emit_signal("cash_updated", cash)
		return true
	return false

## --- Credit functions
func can_pay_with_credit(amount: float) -> bool:
	return credit_used + amount * (1.0 + credit_interest_rate) <= credit_limit


func pay_with_credit(amount: float) -> bool:
	if can_pay_with_credit(amount):
		var total_with_interest := amount * (1.0 + credit_interest_rate)
		credit_used += total_with_interest
		debt += total_with_interest  # ← Track it in total debt
		emit_signal("credit_updated", credit_used, credit_limit)
		emit_signal("resource_changed", "debt", debt)
		return true
	return false

func get_credit_remaining() -> float:
	return credit_limit - credit_used

func set_credit_interest_rate(new_rate: float) -> void:
	credit_interest_rate = new_rate

## -- Balance functions

func get_balance() -> float:
	return snapped(cash + get_total_investments() - debt, 0.01)

func get_passive_income() -> float:
	return snapped(rent + employee_income + interest / 365.0 / 24.0 / 60.0 / 60.0, 0.01)

## --- Stock Methods
func buy_stock(symbol: String, amount: int = 1) -> bool:
	var stock = stock_data.get(symbol)
	if stock == null or cash < stock.price * amount:
		return false

	spend_cash(stock.price * amount)
	stocks_owned[symbol] = stocks_owned.get(symbol, 0) + amount
	MarketManager.apply_stock_transaction(symbol, amount)
	return true


func sell_stock(symbol: String, amount: int = 1) -> bool:
	if stocks_owned.get(symbol, 0) < amount:
		return false

	var stock = stock_data.get(symbol)
	add_cash(stock.price * amount)
	stocks_owned[symbol] -= amount
	MarketManager.apply_stock_transaction(symbol, -amount)
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

## Crypto

func get_crypto_amount(symbol: String) -> float:
	return crypto_owned.get(symbol, 0.0)

func add_crypto(symbol: String, amount: float) -> void:
	crypto_owned[symbol] = crypto_owned.get(symbol, 0.0) + amount
	emit_signal("resource_changed", symbol, crypto_owned[symbol])

func sell_crypto(symbol: String, amount: float = 1) -> bool:
	var owned := get_crypto_amount(symbol)
	if owned < amount:
		return false

	var crypto = MarketManager.crypto_market.get(symbol)
	if not crypto:
		return false

	crypto_owned[symbol] = owned - amount
	add_cash(amount * crypto.price)
	emit_signal("resource_changed", symbol, crypto_owned[symbol])
	return true



# Emit signal methods

func emit_investment_update():
	emit_signal("investments_updated", get_total_investments())


# Connected signals
func _on_stock_price_updated(symbol: String, stock: Stock) -> void:
	# Update our copy
	stock_data[symbol] = stock
	emit_signal("stock_updated", symbol, stock)
	emit_investment_update()
