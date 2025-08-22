extends Node
#Autoload name PortfolioManager

## --- Basic numeric resources
var cash: float:
	get:
		return get_cash()
	set(value):
		set_cash(value)

var rent: float:
	get:
		return get_rent()
	set(value):
		set_rent(value)

var interest: float:
	get:
		return get_interest()
	set(value):
		set_interest(value)

## -- Debt resources
var credit_limit: float:
	get:
		return get_credit_limit()
	set(value):
		set_credit_limit(value)

var credit_used: float:
	get:
		return get_credit_used()
	set(value):
		set_credit_used(value)

var credit_interest_rate: float:
	get:
		return get_credit_interest_rate()
	set(value):
		set_credit_interest_rate(value)

var credit_score: int = 700

var student_loans: float:
	get:
		return get_student_loans()
	set(value):
		set_student_loans(value)

var student_loan_min_payment: float = 0.0
const STUDENT_LOAN_INTEREST_DAILY := 0.001  # 0.1% per day
const STUDENT_LOAN_MIN_PAYMENT_PERCENT := 0.01  # 1% per 4 weeks

## --- Income sources
var employee_income: float:
	get:
		return get_employee_income()
	set(value):
		set_employee_income(value)

var passive_income: float:
	get:
		return get_passive_income_stat()
	set(value):
		set_passive_income(value)

## --- Stocks and owned counts
var stock_data: Dictionary = {}  # symbol: Stock
var stocks_owned: Dictionary = {}# symbol: int

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

## --- Stat Helpers
func get_cash() -> float:
	return StatManager.get_stat("cash")

func set_cash(value: float) -> void:
	StatManager.set_base_stat("cash", snapped(value, 0.01))

func get_rent() -> float:
	return StatManager.get_stat("rent")

func set_rent(value: float) -> void:
	StatManager.set_base_stat("rent", snapped(value, 0.01))

func get_interest() -> float:
	return StatManager.get_stat("interest")

func set_interest(value: float) -> void:
	StatManager.set_base_stat("interest", value)

func get_credit_limit() -> float:
	return StatManager.get_stat("credit_limit")

func set_credit_limit(value: float) -> void:
	StatManager.set_base_stat("credit_limit", value)

func get_credit_used() -> float:
	return StatManager.get_stat("credit_used")

func set_credit_used(value: float) -> void:
	StatManager.set_base_stat("credit_used", snapped(value, 0.01))

func get_credit_interest_rate() -> float:
	return StatManager.get_stat("credit_interest_rate")

func set_credit_interest_rate(value: float) -> void:
	StatManager.set_base_stat("credit_interest_rate", value)

func get_employee_income() -> float:
	return StatManager.get_stat("employee_income")

func set_employee_income(value: float) -> void:
	StatManager.set_base_stat("employee_income", value)

func get_passive_income_stat() -> float:
	return StatManager.get_stat("passive_income")

func set_passive_income(value: float) -> void:
	StatManager.set_base_stat("passive_income", value)

func _ready():
	StatManager.connect_to_stat("cash", self, "_on_cash_changed")
	StatManager.connect_to_stat("credit_used", self, "_on_credit_changed")
	StatManager.connect_to_stat("credit_limit", self, "_on_credit_changed")
	StatManager.connect_to_stat("student_loans", self, "_on_student_loans_changed")
	MarketManager.stock_price_updated.connect(_on_stock_price_updated)
	TimeManager.day_passed.connect(_on_day_passed)
	_on_cash_changed(get_cash())
	_on_credit_changed(get_credit_used())
	_on_student_loans_changed(get_student_loans())

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

		var current_cash := get_cash()
		var remainder = max(amount - current_cash, 0.0)

		# Check if cash + credit is enough
		if not can_pay_with_credit(remainder):
			if not silent:
				StatpopManager.spawn("DECLINED", get_viewport().get_mouse_position(), "click", Color.RED)
			return false

		# Credit fallback
		if credit_score >= credit_required_score:
			if current_cash > 0.0:
				spend_cash(current_cash)
				if not silent:
					StatpopManager.spawn("-$" + str(NumberFormatter.format_number(remainder)), get_viewport().get_mouse_position(), "click", Color.YELLOW)

			if can_pay_with_credit(remainder):
				var total_with_interest = remainder * (1.0 + get_credit_interest_rate())
				set_credit_used(get_credit_used() + total_with_interest)
				if not silent:
					StatpopManager.spawn("-$" + str(NumberFormatter.format_number(remainder)), get_viewport().get_mouse_position(), "click", Color.ORANGE)
				WindowManager.launch_app_by_name("OwerView")
				return true
		# Failed to pay
		if not silent:
				StatpopManager.spawn("DECLINED", get_viewport().get_mouse_position(), "click", Color.RED)
		return false






## --- Cash Methods
func add_cash(amount: float):
        if amount < 0.0:
                printerr("Tried to add negative cash")
                return
        set_cash(get_cash() + amount)
        emit_signal("cash_updated", get_cash())
        emit_signal("resource_changed", "cash", get_cash())
        Events.focus_wallet_card("brag")
        Events.flash_wallet_value("brag", amount)

func spend_cash(amount: float):
        if amount < 0.0:
                printerr("Tried to spend negative cash")
                return
        set_cash(get_cash() - amount)
        emit_signal("cash_updated", get_cash())
        emit_signal("resource_changed", "cash", get_cash())
        Events.focus_wallet_card("brag")
        Events.flash_wallet_value("brag", -amount)

func can_pay_with_cash(amount: float) -> bool:
	return get_cash() >= amount

func pay_with_cash(amount: float) -> bool:
        if can_pay_with_cash(amount):
                set_cash(get_cash() - amount)
                emit_signal("cash_updated", get_cash())
                emit_signal("resource_changed", "cash", get_cash())
                Events.focus_wallet_card("brag")
                Events.flash_wallet_value("brag", -amount)
                return true
        return false



## --- Credit functions
func can_pay_with_credit(amount: float) -> bool:
	return get_credit_used() + amount * (1.0 + get_credit_interest_rate()) <= get_credit_limit()


func pay_with_credit(amount: float) -> bool:
	if can_pay_with_credit(amount):
		var total_with_interest := amount * (1.0 + get_credit_interest_rate())
		set_credit_used(get_credit_used() + total_with_interest)
		WindowManager.launch_app_by_name("OwerView")
		return true
	return false

func get_credit_remaining() -> float:
        return get_credit_limit() - get_credit_used()


func get_total_debt() -> float:
        return snapped(get_credit_used() + get_student_loans(), 0.01)

func get_credit_score() -> int:
        return credit_score

func try_spend_cash(amount: float) -> bool:
        if amount <= 0.0:
                return false
        if get_cash() < amount:
                return false
        spend_cash(amount)
        return true

func get_cash_inflow_24h() -> float:
        return 0.0

func get_cash_outflow_24h() -> float:
        return 0.0

func _recalculate_credit_score():
	var usage_ratio := get_credit_used() / get_credit_limit()
	var base_score := 700

	# Penalize high utilization
	if usage_ratio > 0.9:
		base_score -= 100
	elif usage_ratio > 0.75:
		base_score -= 50
	elif usage_ratio > 0.5:
		base_score -= 20

	# Optional: reward low debt
		if get_student_loans() == 0:
				base_score += 20

	credit_score = clamp(base_score, 300, 850)

func pay_down_credit(amount: float) -> bool:
	if attempt_spend(amount, 9999):
		set_credit_used(max(get_credit_used() - amount, 0.0))
		return true
	return false

func _on_day_passed(_d: int, _m: int, _y: int) -> void:
	_accrue_student_loan_interest()

func _accrue_student_loan_interest():
	var loans := get_student_loans()
	if loans <= 0.0:
		return
	var interest_amount := loans * STUDENT_LOAN_INTEREST_DAILY
	set_student_loans(loans + interest_amount)

func _update_student_loan_min_payment():
		student_loan_min_payment = max(snapped(get_student_loans() * 0.01, 0.01), 0.0)
		emit_signal("resource_changed", "student_loan_min_payment", student_loan_min_payment)

func get_min_student_loan_payment() -> float:
		return student_loan_min_payment


# -- Stat change callbacks
func _on_cash_changed(new_value: float) -> void:
		emit_signal("cash_updated", new_value)
		emit_signal("resource_changed", "cash", new_value)

func _on_credit_changed(_value: float) -> void:
		emit_signal("credit_updated", get_credit_used(), get_credit_limit())
		emit_signal("resource_changed", "debt", get_total_debt())
		_recalculate_credit_score()

func _on_student_loans_changed(_value: float) -> void:
		_update_student_loan_min_payment()
		emit_signal("resource_changed", "student_loans", get_student_loans())
		emit_signal("resource_changed", "debt", get_total_debt())
		_recalculate_credit_score()


## -- Balance functions

func get_balance() -> float:
		return snapped(get_cash() + get_total_investments() - get_total_debt(), 0.01)

func get_passive_income() -> float:
		return snapped(get_rent() + get_employee_income() + get_interest() / 365.0 / 24.0 / 60.0 / 60.0, 0.01)

func halve_assets() -> void:
	set_cash(get_cash() / 2.0)
	for symbol in stocks_owned.keys():
			var owned: int = stocks_owned[symbol]
			stocks_owned[symbol] = int(floor(owned / 2.0))
			emit_signal("stock_updated", symbol, stock_data.get(symbol))
	for symbol in crypto_owned.keys():
			crypto_owned[symbol] = crypto_owned[symbol] / 2.0
			emit_signal("resource_changed", symbol, crypto_owned[symbol])
	GPUManager.halve_gpus()
	emit_investment_update()

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
# Legacy wrappers retained for API compatibility. Logic now lives in StatManager.
func set_student_loans(amount: float):
	StatManager.set_base_stat("student_loans", snapped(amount, 0.01))

func add_student_loans(amount: float):
	set_student_loans(get_student_loans() + amount)

func get_student_loans() -> float:
	return StatManager.get_stat("student_loans")








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
	emit_investment_update()
	_on_cash_changed(get_cash())
	_on_credit_changed(get_credit_used())
	_on_student_loans_changed(get_student_loans())


func reset():
	set_cash(0.0)
	set_rent(0.0)
	set_interest(0.0)
	set_credit_limit(2000.0)
	set_credit_used(0.0)
	set_credit_interest_rate(0.3)
	set_student_loans(0.0)
	set_employee_income(0.0)
	set_passive_income(0.0)
	credit_score = 700
	student_loan_min_payment = 0.0

	stocks_owned.clear()
	crypto_owned.clear()
	stock_data.clear()
	miners.clear()
	businesses.clear()

	emit_investment_update()
