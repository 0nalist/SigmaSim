extends Node

func _init() -> void:
    _ready()

var bm_script: Script = preload("res://autoloads/bill_manager.gd")

class DummyTimeManager:
    func get_weekday_for_date(day: int, month: int, year: int) -> int:
        return 6
    func get_total_days_since_start(day: int, month: int, year: int) -> int:
        return day - 2
    func get_days_in_month(month: int, year: int) -> int:
        return 31

class DummyPortfolioManager:
    var cash: float = 0.0
    var credit_limit: float = 0.0
    var credit_used: float = 0.0
    var credit_interest_rate: float = 0.0
    var credit_score: int = 700
    var CREDIT_REQUIREMENTS: Dictionary = {"bills": 0}
    func attempt_spend(amount: float, required_score: int = 0, silent: bool = false) -> bool:
        if cash >= amount:
            cash -= amount
            return true
        var available: float = credit_limit - credit_used
        if available >= amount:
            credit_used += amount
            return true
        return false
    func pay_down_credit(amount: float) -> bool:
        if cash >= amount:
            cash -= amount
            credit_used = max(credit_used - amount, 0.0)
            return true
        return false

class DummyPopup:
    var bill_name: String = ""
    var amount: float = 0.0
    var visible: bool = true
    func close() -> void:
        visible = false
    func update_amount_display() -> void:
        pass

class TestBillManager extends bm_script:
    var autopay_attempts: int = 0
    func attempt_to_autopay(bill_name: String) -> bool:
        autopay_attempts += 1
        return true
    func _get_yesterday() -> Dictionary:
        return {"day": 1, "month": 1, "year": 2000}
    func _format_date_key(date: Dictionary) -> String:
        return "key"
    func auto_resolve_bills_for_date(date_str: String) -> void:
        pass
    func get_due_bills_for_date(day: int, month: int, year: int) -> Array[String]:
        return ["TestBill"]
    func get_bill_amount(bill_name: String) -> float:
        return 10.0
    func mark_bill_paid(bill_name: String, date_key: String) -> void:
        pass

func _ready() -> void:
    var tm: DummyTimeManager = DummyTimeManager.new()
    Engine.register_singleton("TimeManager", tm)
    var pm: DummyPortfolioManager = DummyPortfolioManager.new()
    Engine.register_singleton("PortfolioManager", pm)

    var bm1: Node = bm_script.new()
    var sundays: Array[int] = [2, 9, 16, 23]
    var expected: Array[String] = ["Rent", "Student Loan", "Credit Card", "Medical Insurance"]
    var month: int = 1
    var year: int = 2000
    var i: int = 0
    while i < sundays.size():
        var bills: Array[String] = bm1.get_due_bills_for_date(sundays[i], month, year)
        assert(expected[i] in bills)
        i += 1

    var bm2: TestBillManager = TestBillManager.new()
    bm2.autopay_enabled = true
    bm2._on_day_passed(1, 1, 2000)
    assert(bm2.autopay_attempts == 1)
    bm2.autopay_enabled = false
    bm2._on_day_passed(1, 1, 2000)
    assert(bm2.autopay_attempts == 1)

    pm.cash = 0.0
    pm.credit_limit = 100.0
    pm.credit_used = 0.0
    var bm3: Node = bm_script.new()
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
