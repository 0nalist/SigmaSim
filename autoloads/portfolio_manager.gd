extends Node
#Autoload name PortfolioManager

## --- Basic numeric resources
var cash: float
var rent: float = 0.0
var interest: float = 0.0

## -- Debt resources
var credit_limit: float = 2000.0
var credit_used: float = 0.0
var credit_interest_rate: float = 0.3  # 30% by default
var credit_score: int = 700

var student_loans: float
var student_loan_min_payment: float = 0.0
const STUDENT_LOAN_INTEREST_DAILY := 0.001  # 0.1% per day
const STUDENT_LOAN_MIN_PAYMENT_PERCENT := 0.01  # 1% per 4 weeks

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
		cash = StatManager.get_stat("cash", cash)
		StatManager.set_base_stat("cash", cash)
		rent = StatManager.get_stat("rent", rent)
		StatManager.set_base_stat("rent", rent)
		interest = StatManager.get_stat("interest", interest)
		StatManager.set_base_stat("interest", interest)
		credit_limit = StatManager.get_stat("credit_limit", credit_limit)
		StatManager.set_base_stat("credit_limit", credit_limit)
		credit_used = StatManager.get_stat("credit_used", credit_used)
		StatManager.set_base_stat("credit_used", credit_used)
		credit_interest_rate = StatManager.get_stat("credit_interest_rate", credit_interest_rate)
		StatManager.set_base_stat("credit_interest_rate", credit_interest_rate)
		student_loans = StatManager.get_stat("student_loans", student_loans)
		StatManager.set_base_stat("student_loans", student_loans)
		employee_income = StatManager.get_stat("employee_income", employee_income)
		StatManager.set_base_stat("employee_income", employee_income)
		passive_income = StatManager.get_stat("passive_income", passive_income)
		StatManager.set_base_stat("passive_income", passive_income)
		MarketManager.stock_price_updated.connect(_on_stock_price_updated)
		TimeManager.day_passed.connect(_on_day_passed)

## --- Spending Router
func attempt_spend(amount: float, credit_required_score: int = 0, silent: bool = false) -> bool:
	if amount <= 0.0:
		printerr("Attempted to spend non-positive amount")
		return false

	# Cash first
	if can_pay_with_cash(amount):
		spend_cash(amount)
		if not silent:
			StatpopManager.spawn("-$" + str(NumberFormatter.format_number(amount)), get_viewport().get_mouse_position(), "click", Color.YELLOW)
		return true

	# Check if cash + credit is enough
	if not can_pay_with_credit(amount + cash):
		if not silent:
			StatpopManager.spawn("DECLINED", get_viewport().get_mouse_position(), "click", Color.RED)
		return false

	# Credit fallback
	if credit_score >= credit_required_score:
		var remainder := amount - cash
		if cash > 0.0:
			spend_cash(cash)
			if not silent:
				StatpopManager.spawn("-$" + str(NumberFormatter.format_number(remainder)), get_viewport().get_mouse_position(), "click", Color.YELLOW)

				if can_pay_with_credit(remainder):
						var total_with_interest := remainder * (1.0 + credit_interest_rate)
						credit_used += total_with_interest
						StatManager.set_base_stat("credit_used", credit_used)
						cash = 0.0
						StatManager.set_base_stat("cash", cash)
						emit_signal("cash_updated", cash)
						emit_signal("credit_updated", credit_used, credit_limit)
						_recalculate_credit_score()
			emit_signal("resource_changed", "debt", get_total_debt())
			if not silent:
				StatpopManager.spawn("-$" + str(NumberFormatter.format_number(remainder)), get_viewport().get_mouse_position(), "click", Color.ORANGE)
			WindowManager.launch_app_by_name("OwerView")
			return true

	# Failed to pay
	if not silent:
		StatpopManager.spawn("DECLINED", get_viewport().get_mouse_position(), "click", Color.RED)
	#print("Not enough cash or credit")
	return false






## --- Cash Methods
func add_cash(amount: float):
		if amount < 0.0:
				printerr("Tried to add negative cash")
				return
		cash = snapped(cash + amount, 0.01)
		StatManager.set_base_stat("cash", cash)
		emit_signal("cash_updated", cash)
		emit_signal("resource_changed", "cash", cash)

func spend_cash(amount: float):
		if amount < 0.0:
				printerr("Tried to spend negative cash")
				return
		cash = snapped(cash - amount, 0.01)
		StatManager.set_base_stat("cash", cash)
		emit_signal("cash_updated", cash)
		emit_signal("resource_changed", "cash", cash)

func can_pay_with_cash(amount: float) -> bool:
	return cash >= amount

func pay_with_cash(amount: float) -> bool:
		if can_pay_with_cash(amount):
				cash -= amount
				StatManager.set_base_stat("cash", cash)
				emit_signal("cash_updated", cash)
				emit_signal("resource_changed", "cash", cash)
				return true
		return false



## --- Credit functions
func can_pay_with_credit(amount: float) -> bool:
	return credit_used + amount * (1.0 + credit_interest_rate) <= credit_limit


func pay_with_credit(amount: float) -> bool:
		if can_pay_with_credit(amount):
				var total_with_interest := amount * (1.0 + credit_interest_rate)
				credit_used += total_with_interest
				StatManager.set_base_stat("credit_used", credit_used)
				emit_signal("credit_updated", credit_used, credit_limit)
				_recalculate_credit_score()
				emit_signal("resource_changed", "debt", get_total_debt())
				WindowManager.launch_app_by_name("OwerView")
				return true
		return false

func get_credit_remaining() -> float:
	return credit_limit - credit_used

func set_credit_interest_rate(new_rate: float) -> void:
		credit_interest_rate = new_rate
		StatManager.set_base_stat("credit_interest_rate", credit_interest_rate)

func get_total_debt() -> float:
	return snapped(credit_used + student_loans, 0.01)

func get_credit_score() -> int:
	return credit_score

func _recalculate_credit_score():
	var usage_ratio := credit_used / credit_limit
	var base_score := 700

	# Penalize high utilization
	if usage_ratio > 0.9:
		base_score -= 100
	elif usage_ratio > 0.75:
		base_score -= 50
	elif usage_ratio > 0.5:
		base_score -= 20

	# Optional: reward low debt
	if student_loans == 0:
		base_score += 20

	credit_score = clamp(base_score, 300, 850)

func pay_down_credit(amount: float) -> bool:
		if attempt_spend(amount, 9999):
				credit_used = max(credit_used - amount, 0.0)
				StatManager.set_base_stat("credit_used", credit_used)
				emit_signal("credit_updated", credit_used, credit_limit)
				emit_signal("resource_changed", "debt", get_total_debt())
				return true
		return false

func _on_day_passed(_d: int, _m: int, _y: int) -> void:
	_accrue_student_loan_interest()

func _accrue_student_loan_interest():
				if student_loans <= 0.0:
								return
				var interest_amount := student_loans * STUDENT_LOAN_INTEREST_DAILY
				student_loans = snapped(student_loans + interest_amount, 0.01)
				StatManager.set_base_stat("student_loans", student_loans)
				_update_student_loan_min_payment()
				emit_signal("resource_changed", "student_loans", student_loans)
				emit_signal("resource_changed", "debt", get_total_debt())

func _update_student_loan_min_payment():
	student_loan_min_payment = max(snapped(student_loans * 0.01, 0.01), 0.0)
	emit_signal("resource_changed", "student_loan_min_payment", student_loan_min_payment)

func get_min_student_loan_payment() -> float:
	return student_loan_min_payment



## -- Balance functions

func get_balance() -> float:
	return snapped(cash + get_total_investments() - get_total_debt(), 0.01)

func get_passive_income() -> float:
	return snapped(rent + employee_income + interest / 365.0 / 24.0 / 60.0 / 60.0, 0.01)

## --- Stock Methods
func buy_stock(symbol: String, amount: int = 1) -> bool:
	var stock = stock_data.get(symbol)
	if stock == null:
		return false

	var total_price = stock.price * amount
	if attempt_spend(total_price, 800):
		stocks_owned[symbol] = stocks_owned.get(symbol, 0) + amount
		MarketManager.apply_stock_transaction(symbol, amount)
		return true

	return false


func sell_stock(symbol: String, amount: int = 1) -> bool:
	if stocks_owned.get(symbol, 0) < amount:
		return false

	var stock = stock_data.get(symbol)
	add_cash(stock.price * amount)
	StatpopManager.spawn("+$" + str(NumberFormatter.format_number(stock.price*amount)), get_viewport().get_mouse_position(), "click", Color.GREEN)
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

func get_crypto_total() -> float:
	var total := 0.0
	for symbol in crypto_owned.keys():
		var amount = crypto_owned[symbol]
		var crypto = MarketManager.crypto_market.get(symbol)
		if crypto:
			total += amount * crypto.price
	return snapped(total, 0.01)


## Student loans
func set_student_loans(amount: float):
		student_loans = snapped(amount, 0.01)
		StatManager.set_base_stat("student_loans", student_loans)
		emit_signal("resource_changed", "student_loans", student_loans)
		emit_signal("resource_changed", "debt", get_total_debt())
		_recalculate_credit_score()

func add_student_loans(amount: float):
		student_loans = snapped(student_loans + amount, 0.01)
		StatManager.set_base_stat("student_loans", student_loans)
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
				"stocks_owned": stocks_owned.duplicate(),
				"crypto_owned": crypto_owned.duplicate(),
		}


func load_from_data(data: Dictionary) -> void:
		stocks_owned = data.get("stocks_owned", {})
		crypto_owned = data.get("crypto_owned", {})

		cash = StatManager.get_stat("cash", 0.0)
		rent = StatManager.get_stat("rent", 0.0)
		interest = StatManager.get_stat("interest", 0.0)
		student_loans = StatManager.get_stat("student_loans", 0.0)
		credit_limit = StatManager.get_stat("credit_limit", 0.0)
		credit_used = StatManager.get_stat("credit_used", 0.0)
		credit_interest_rate = StatManager.get_stat("credit_interest_rate", 0.3)
		employee_income = StatManager.get_stat("employee_income", 0.0)
		passive_income = StatManager.get_stat("passive_income", 0.0)

		emit_signal("cash_updated", cash)
		emit_signal("credit_updated", credit_used, credit_limit)
		emit_investment_update()
		_recalculate_credit_score()


func reset():
	cash = 0.0
	rent = 0.0
	interest = 0.0
	credit_limit = 2000.0
	credit_used = 0.0
	credit_interest_rate = 0.3
	student_loans = 0.0
	employee_income = 0.0
	passive_income = 0.0

	StatManager.set_base_stat("cash", cash)
	StatManager.set_base_stat("rent", rent)
	StatManager.set_base_stat("interest", interest)
	StatManager.set_base_stat("credit_limit", credit_limit)
	StatManager.set_base_stat("credit_used", credit_used)
	StatManager.set_base_stat("credit_interest_rate", credit_interest_rate)
	StatManager.set_base_stat("student_loans", student_loans)
	StatManager.set_base_stat("employee_income", employee_income)
	StatManager.set_base_stat("passive_income", passive_income)

	stocks_owned.clear()
	crypto_owned.clear()
	stock_data.clear()
	miners.clear()
	businesses.clear()

	emit_signal("cash_updated", cash)
	emit_signal("credit_updated", credit_used, credit_limit)
	emit_signal("resource_changed", "debt", get_total_debt())
	emit_investment_update()
