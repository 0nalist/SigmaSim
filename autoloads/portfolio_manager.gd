extends Node
#Autoload name PortfolioManager

## --- Basic numeric resources
var cash: float = 0.0
var rent: float = 0.0
var interest: float = 0.0

## -- Debt resources
var credit_limit: float = 2000.0
var credit_used: float = 0.0
var credit_interest_rate: float = 0.3  # 30% by default

var student_loans: float = 1.11


## --- Income sources
var employee_income: float = 0.0
var passive_income: float = 0.0

## --- Stocks and owned counts
var stock_data: Dictionary = {}     # symbol: Stock
var stocks_owned: Dictionary = {}   # symbol: int

## --- Crypto and owned counts
var crypto_owned: Dictionary = {}  # symbol: float

## --- Future complex resources
var miners: Dictionary = {}
var businesses: Dictionary = {}

## --- Signals
signal cash_updated(new_cash: float)
signal credit_updated(used: float, limit: float)
signal stock_updated(symbol: String, new_stock: Stock)
signal resource_changed(name: String, value: float)
signal investments_updated(amount: float)

func _ready():
	MarketManager.stock_price_updated.connect(_on_stock_price_updated)


## --- Hybrid Spend (Cash then Credit fallback) ---
func attempt_spend(amount: float) -> bool:
	# Try paying with cash first
	if can_pay_with_cash(amount):
		spend_cash(amount)
		return true

	# Fallback to credit (for the remainder)
	var remainder := amount - cash
	if can_pay_with_credit(remainder):
		if cash > 0:
			spend_cash(cash)  # spend remaining cash first

		var total_with_interest := remainder * (1.0 + credit_interest_rate)
		credit_used += total_with_interest
		cash = 0.0  # should now be zero

		emit_signal("cash_updated", cash)
		emit_signal("credit_updated", credit_used, credit_limit)
		return true

	# Neither cash nor credit can cover the cost
	print("not enough cash or credit")
	return false





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
		emit_signal("credit_updated", credit_used, credit_limit)
		emit_signal("resource_changed", "debt", get_total_debt())
		return true
	return false

func get_credit_remaining() -> float:
	return credit_limit - credit_used

func set_credit_interest_rate(new_rate: float) -> void:
	credit_interest_rate = new_rate

func get_total_debt() -> float:
	return snapped(credit_used + student_loans, 0.01)



## -- Balance functions

func get_balance() -> float:
	return snapped(cash + get_total_investments() - get_total_debt(), 0.01)

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



## Student loans
func set_student_loans(amount: float):
	student_loans = snapped(amount, 0.01)
	emit_signal("resource_changed", "student_loans", student_loans)
	emit_signal("resource_changed", "debt", get_total_debt())

func add_student_loans(amount: float):
	student_loans = snapped(student_loans + amount, 0.01)
	emit_signal("resource_changed", "student_loans", student_loans)
	emit_signal("resource_changed", "debt", get_total_debt())

func get_student_loans() -> float:
	return student_loans








# Emit signal methods

func emit_investment_update():
	emit_signal("investments_updated", get_total_investments())


# Connected signals
func _on_stock_price_updated(symbol: String, stock: Stock) -> void:
	# Update our copy
	stock_data[symbol] = stock
	emit_signal("stock_updated", symbol, stock)
	emit_investment_update()








## -- Save/Load

func get_save_data() -> Dictionary:
	return {
		"cash": cash,
		"rent": rent,
		"interest": interest,
		"student_loans": student_loans,
		"credit_limit": credit_limit,
		"credit_used": credit_used,
		"credit_interest_rate": credit_interest_rate,
		"employee_income": employee_income,
		"passive_income": passive_income,
		"stocks_owned": stocks_owned.duplicate(),
		"crypto_owned": crypto_owned.duplicate(),

	}


func load_from_data(data: Dictionary) -> void:
	cash = data.get("cash", 0.0)
	student_loans = data.get("student_loans", 0.0)
	rent = data.get("rent", 0.0)
	interest = data.get("interest", 0.0)

	credit_limit = data.get("credit_limit", 0.0)
	credit_used = data.get("credit_used", 0.0)
	credit_interest_rate = data.get("credit_interest_rate", 0.3)

	employee_income = data.get("employee_income", 0.0)
	passive_income = data.get("passive_income", 0.0)

	stocks_owned = data.get("stocks_owned", {})
	crypto_owned = data.get("crypto_owned", {})


	emit_signal("cash_updated", cash)
	emit_signal("credit_updated", credit_used, credit_limit)
	emit_investment_update()
