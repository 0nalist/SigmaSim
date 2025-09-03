extends Node

func _init() -> void:
	_ready()

const BillManagerScript: Script = preload("res://autoloads/bill_manager.gd")

func _ready() -> void:
	# Use the real singletons already set up in autoloads
	var pm: Node = PortfolioManager
	var tm: Node = TimeManager

	# --- BillManager weekly bills check ---
	var bm1: Node = BillManagerScript.new()
	var sundays: Array[int] = [2, 9, 16, 23]
	var expected: Array[String] = ["Rent", "Student Loan", "Credit Card", "Medical Insurance"]
	var month: int = 1
	var year: int = 2000
	var i: int = 0
	while i < sundays.size():
		var bills: Array[String] = bm1.get_due_bills_for_date(sundays[i], month, year)
		assert(expected[i] in bills)
		i += 1

	# --- Autopay cycle ---
	var bm2: Node = BillManagerScript.new()
	bm2.autopay_enabled = true
	bm2._on_day_passed(1, 1, 2000)
	# bm2 should have called its own attempt_to_autopay internally
	# You can assert real side effects instead of counting dummy counters

	# --- Credit card autopay logic ---
	pm.cash = 0.0
	pm.credit_limit = 100.0
	pm.credit_used = 0.0

	var bm3: Node = BillManagerScript.new()
	bm3.static_bill_amounts["TestBill"] = 40.0
	var result: bool = bm3.attempt_to_autopay("TestBill")
	assert(result)
	assert(pm.credit_used == 40.0)

	pm.credit_used = 90.0
	bm3.static_bill_amounts["AnotherBill"] = 20.0
	var result_fail: bool = bm3.attempt_to_autopay("AnotherBill")
	assert(not result_fail)
	assert(pm.credit_used == 90.0)

	print("bill_manager_test passed")
