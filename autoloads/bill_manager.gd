extends Node
# Autoload: BillManager

var autopay_enabled: bool = false
var active_bills: Dictionary = {}  # key: date_str → Array[BillPopupUI]

# Ordered list: Week 0 → Rent, Week 1 → Insurance, etc.
var weekly_bill_cycle := [
	{"name": "Rent", "color": Color.RED},
	{"name": "Medical Insurance", "color": Color.BLUE},
	{"name": "Student Loan", "color": Color.GREEN},
	{"name": "Credit Card", "color": Color.PURPLE}
]

var static_bill_amounts := {
	"Rent": 1200.0,
	"Medical Insurance": 850.0
}


func _ready() -> void:
	TimeManager.day_passed.connect(_on_day_passed)
	PortfolioManager.credit_updated.connect(_on_credit_updated)
	print("active bills: " + str(active_bills))


func _on_day_passed(new_day: int, new_month: int, new_year: int) -> void:
	# Resolve yesterday’s bills
	var yesterday = _get_yesterday()
	auto_resolve_bills_for_date(_format_date_key(yesterday))

	# Spawn today’s bills
	var today := {
		"day": new_day,
		"month": new_month,
		"year": new_year
	}
	var today_key = _format_date_key(today)
	if not active_bills.has(today_key):
		active_bills[today_key] = []

	var bills_today = get_due_bills_for_date(new_day, new_month, new_year)

	for bill_name in bills_today:
		var amount := get_bill_amount(bill_name)
		if amount <= 0.0:
			print("Skipping %s bill (amount is 0)" % bill_name)
			continue

		if autopay_enabled and attempt_to_autopay(bill_name):
			continue


		var popup = preload("res://components/popups/bill_popup_ui.tscn").instantiate()
		popup.init(bill_name)

		var win := preload("res://components/ui/window_frame.tscn").instantiate() as WindowFrame
		win.window_title = "Bill: %s" % bill_name
		win.call_deferred("set_window_title", win.window_title)
		win.icon = null
		win.default_size = popup.default_window_size if "default_window_size" in popup else Vector2(550, 290)
		win.window_can_close = false
		win.window_can_minimize = false
		win.get_node("%ContentPanel").add_child(popup)

		WindowManager.register_window(win, false)
		call_deferred("center_bill_window", win)
		active_bills[today_key].append(popup)


func _on_credit_updated(used: float, limit: float) -> void:
	# Update any open Credit Card bill popups
	for bill_list in active_bills.values():
		for popup in bill_list:
			if is_instance_valid(popup) and popup.bill_name == "Credit Card":
				popup.amount = get_bill_amount("Credit Card")
				popup.update_amount_display() 


func center_bill_window(win: WindowFrame) -> void:
	WindowManager.center_window(win)


func attempt_to_autopay(bill_name: String) -> bool:
	var amount := get_bill_amount(bill_name)

	if PortfolioManager.pay_with_cash(amount):
		print("✅ Autopaid %s with cash" % bill_name)
		return true
	elif PortfolioManager.can_pay_with_credit(amount):
		PortfolioManager.pay_with_credit(amount)
		print("✅ Autopaid %s with credit" % bill_name)
		return true
	else:
		print("❌ Autopay failed for %s" % bill_name)
		#Siggy.activate("bill_unpayable")
		return false


func get_due_bills_for_date(day: int, month: int, year: int) -> Array[String]:
	var weekday = TimeManager.get_weekday_for_date(day, month, year)
	if weekday != 6:
		return []

	var week_index = int((day - 1) / 7)
	var bill_index = week_index % weekly_bill_cycle.size()
	var bill_info = weekly_bill_cycle[bill_index]
	return [bill_info.name]


func get_due_bills_for_month(month: int, year: int) -> Dictionary:
	var output: Dictionary = {}
	var days = TimeManager.get_days_in_month(month, year)

	for day in range(1, days + 1):
		var bills = get_due_bills_for_date(day, month, year)
		if not bills.is_empty():
			output[day] = bills

	return output


func auto_resolve_bills_for_date(date_str: String) -> void:
	for popup in active_bills.get(date_str, []):
		if popup and popup.visible:
			if PortfolioManager.pay_with_cash(popup.amount):
				print("✅ Autopaid %s with cash" % popup.amount)
				return
			elif PortfolioManager.can_pay_with_credit(popup.amount):
				PortfolioManager.pay_with_credit(popup.amount)
				popup.close()
			else:
				GameManager.trigger_game_over("Could not pay bill " + str(popup.bill_name))
				#GameManager.trigger_game_over("Unpaid bill: %s" % popup.bill_name)


func get_bill_color(bill_name: String) -> Color:
	for bill in weekly_bill_cycle:
		if bill.name == bill_name:
			return bill.color
	return Color.GRAY


func get_bill_amount(bill_name: String) -> float:
	match bill_name:
		"Credit Card":
			return PortfolioManager.credit_used
		"Student Loan":
			return PortfolioManager.get_min_student_loan_payment()
		_:
			return static_bill_amounts.get(bill_name, 0.0)


func _format_date_key(date: Dictionary) -> String:
	return "%d/%d/%d" % [date.day, date.month, date.year]


func _get_yesterday() -> Dictionary:
	var day = TimeManager.current_day - 1
	var month = TimeManager.current_month
	var year = TimeManager.current_year

	if day < 1:
		month -= 1
		if month < 1:
			month = 12
			year -= 1
		day = TimeManager.get_days_in_month(month, year)

	return { "day": day, "month": month, "year": year }
