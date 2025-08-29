extends Node
# Autoload: BillManager

signal lifestyle_updated
signal autopay_changed(enabled: bool)
signal debt_resources_changed()
signal credit_txn_occurred(amount: float)
signal student_loan_changed()

var _autopay_enabled: bool = false
var autopay_enabled: bool:
	get:
		return _autopay_enabled
	set(value):
		if _autopay_enabled == value:
			return
		_autopay_enabled = value
		autopay_changed.emit(value)
var active_bills: Dictionary = {}
var pending_bill_data: Dictionary = {}  # date_key: Array[Dictionary]
var paid_bills: Dictionary = {}  # date_key: Array[String]

var lifestyle_categories := {}  # category_name: Dictionary


# Ordered list
var weekly_bill_cycle := [
	{"name": "Student Loan", "color": Color.GREEN},
	{"name": "Rent", "color": Color.RED},
	{"name": "Credit Card", "color": Color.PURPLE},
	{"name": "Medical Insurance", "color": Color.BLUE},
]

var static_bill_amounts := {}

var is_loading := false

var debt_resources: Array[Dictionary] = []


func _initialize_default_lifestyle() -> void:
		lifestyle_categories.clear()
		lifestyle_indices.clear()
		for category in lifestyle_options.keys():
				var option = lifestyle_options[category][0]
				lifestyle_categories[category] = option
				lifestyle_indices[category] = 0
		emit_signal("lifestyle_updated")


func _ready() -> void:
	TimeManager.day_passed.connect(_on_day_passed)
	TimeManager.hour_passed.connect(_on_hour_passed)
	TimeManager.minute_passed.connect(_on_minute_passed)
	PortfolioManager.credit_updated.connect(_on_credit_updated)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	if lifestyle_categories.is_empty():
		_initialize_default_lifestyle()
	print("active bills: " + str(active_bills))

func _on_day_passed(new_day: int, new_month: int, new_year: int) -> void:
	if is_loading:
		return

	var yesterday = _get_yesterday()
	auto_resolve_bills_for_date(_format_date_key(yesterday))

	var today := {
		"day": new_day,
		"month": new_month,
		"year": new_year
	}
	var today_key = _format_date_key(today)
	if not active_bills.has(today_key):
		active_bills[today_key] = []
	if not pending_bill_data.has(today_key):
		pending_bill_data[today_key] = []

	var bills_today: Array = get_due_bills_for_date(new_day, new_month, new_year)
	var already_paid: Array = paid_bills.get(today_key, [])

	for bill_name in bills_today:
			if bill_name in already_paid:
							continue

			# 🧠 Check if this bill popup already exists or is pending for today
			var already_open: bool = false
			for existing in active_bills[today_key]:
					if is_instance_valid(existing) and existing.bill_name == bill_name:
							already_open = true
							break
			if not already_open:
					for pending in pending_bill_data.get(today_key, []):
							if pending.get("bill_name", "") == bill_name:
									already_open = true
									break

			if already_open:
					continue  # ✅ Skip duplicate

			var amount: float = get_bill_amount(bill_name)
			if amount <= 0.0:
					print("Skipping %s bill (amount is 0)" % bill_name)
					continue

			if autopay_enabled and attempt_to_autopay(bill_name):
				mark_bill_paid(bill_name, today_key)
				continue

			# Queue bill popup for display
			pending_bill_data[today_key].append({
					"bill_name": bill_name,
					"amount": amount
			})

	_tick_down_compound_timers(1440)
	apply_debt_interest()
	show_due_popups()




func _on_credit_updated(used: float, limit: float) -> void:
	_set_credit_card_balance(used, limit)
	for bill_list in active_bills.values():
		for popup in bill_list:
			if is_instance_valid(popup) and popup.bill_name == "Credit Card":
				popup.amount = get_bill_amount("Credit Card")
				popup.update_amount_display()

func _on_resource_changed(name: String, value: float) -> void:
	if name == "student_loans":
		_set_student_loan_balance(value)


func center_bill_window(win: WindowFrame) -> void:
		var screen_size = get_viewport().get_visible_rect().size
		var rng: RandomNumberGenerator = RNGManager.get_rng()
		var max_pos = screen_size - win.default_size
		var rand_x := rng.randf_range(0.0, max(0.0, max_pos.x))
		var rand_y := rng.randf_range(0.0, max(0.0, max_pos.y))
		win.position = Vector2(rand_x, rand_y)


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
		# Siggy.activate("bill_unpayable")
		return false



func mark_bill_paid(bill_name: String, date_key: String) -> void:
		if not paid_bills.has(date_key):
				paid_bills[date_key] = []
		if bill_name not in paid_bills[date_key]:
				paid_bills[date_key].append(bill_name)


func is_bill_paid(bill_name: String, date_key: String) -> bool:
		return bill_name in paid_bills.get(date_key, [])


func get_due_bills_for_date(day: int, month: int, year: int) -> Array[String]:
	var bills: Array[String] = []
	var weekday = TimeManager.get_weekday_for_date(day, month, year)

	if weekday == 6:  # Sunday
		var total_days = TimeManager.get_total_days_since_start(day, month, year)
		var week_index = int(total_days / 7)

		if week_index % 4 == 0:
				bills.append("Rent")
		if week_index % 4 == 1:
				bills.append("Student Loan")
		if week_index % 4 == 2:
				bills.append("Credit Card")
		if week_index % 4 == 3:
				bills.append("Medical Insurance")

	if get_daily_lifestyle_cost() > 0:
		bills.append("Lifestyle Spending")

	return bills




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
					mark_bill_paid(popup.bill_name, date_str)
					popup.close()
					return
			elif PortfolioManager.can_pay_with_credit(popup.amount):
					PortfolioManager.pay_with_credit(popup.amount)
					mark_bill_paid(popup.bill_name, date_str)
					popup.close()
			else:
					GameManager.trigger_game_over("Could not pay bill " + str(popup.bill_name))
					#GameManager.trigger_game_over("Unpaid bill: %s" % popup.bill_name)
			

func get_bill_color(bill_name: String) -> Color:
	if bill_name == "Lifestyle Spending":
		return Color.ORANGE
	
	for bill in weekly_bill_cycle:
		if bill.name == bill_name:
			return bill.color
	return Color.GRAY


func get_bill_amount(bill_name: String) -> float:
	match bill_name:
		"Credit Card":
			return PortfolioManager.credit_used
		"Rent":
			var housing = lifestyle_categories.get("Housing", null)
			if housing:
				return housing.get("cost", 0) * 4  # 4-week total
			return 0.0
		"Medical Insurance":
			var insurance = lifestyle_categories.get("Medical Insurance", null)
			if insurance:
				return insurance.get("cost", 0) * 4  # 4-week total
			return 0.0
		"Student Loan":
			return PortfolioManager.get_min_student_loan_payment()
		"Lifestyle Spending":
			return get_daily_lifestyle_cost()
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



var lifestyle_indices := {}  # category_name: selected_index

func set_lifestyle_choice(category: String, option: Dictionary, index := -1):
	lifestyle_categories[category] = option
	if index >= 0:
		lifestyle_indices[category] = index
	emit_signal("lifestyle_updated")


func get_daily_lifestyle_cost() -> int:
	var total := 0
	for key in lifestyle_categories.keys():
		if key in ["Housing", "Medical Insurance"]:
			continue
		var cost = lifestyle_categories[key].get("cost", 0)
		total += int(round(cost / 7.0))
	return total



func add_debt_resource(resource: Dictionary) -> void:
	if not resource.has("interest_rate"):
		resource["interest_rate"] = 0.0
	var name := String(resource.get("name", ""))
	var interval := 0
	match name:
		"Credit Card":
			interval = 7 * 1440
		"Student Loan":
			interval = TimeManager.get_days_in_month(TimeManager.current_month, TimeManager.current_year) * 1440
		"Payday Loan":
			interval = 1 * 1440
		_:
			interval = int(resource.get("compound_interval", 0))
	resource["compound_interval"] = interval
	resource["compounds_in"] = int(resource.get("compounds_in", interval))
	debt_resources.append(resource)
	debt_resources_changed.emit()
func get_debt_resources() -> Array[Dictionary]:
		return debt_resources

func pay_debt(name: String, amount: float) -> void:
	match name:
		"Credit Card":
			PortfolioManager.pay_down_credit(amount)
			_set_credit_card_balance(PortfolioManager.credit_used, PortfolioManager.credit_limit)
		"Student Loan":
				if PortfolioManager.pay_with_cash(amount):
						PortfolioManager.set_student_loans(max(PortfolioManager.get_student_loans() - amount, 0.0))
						_set_student_loan_balance(PortfolioManager.get_student_loans())
						student_loan_changed.emit()
		_:
				if PortfolioManager.pay_with_cash(amount):
						var res: Dictionary = _get_debt_resource(name)
						if not res.is_empty():
								res["balance"] = max(res.get("balance", 0.0) - amount, 0.0)
								debt_resources_changed.emit()

func take_payday_loan(amount: float) -> void:
		var res: Dictionary = _get_debt_resource("Payday Loan")
		if res.is_empty():
				return
		var rate: float = float(res.get("interest_rate", 0.0))
		var total := amount * (1.0 + rate)
		res["balance"] = res.get("balance", 0.0) + total
		debt_resources_changed.emit()
		PortfolioManager.add_cash(amount)

func apply_debt_interest() -> void:
	var changed := false
	for res in debt_resources:
		var minutes := int(res.get("compounds_in", 0))
		if minutes > 0:
			continue
		var rate: float = float(res.get("interest_rate", 0.0))
		var bal: float = float(res.get("balance", 0.0))
		if rate != 0.0 and bal > 0.0:
			res["balance"] = bal * (1.0 + rate)
			changed = true
		if res.get("name", "") == "Student Loan":
			res["compound_interval"] = TimeManager.get_days_in_month(TimeManager.current_month, TimeManager.current_year) * 1440
		var interval := int(res.get("compound_interval", 0))
		if res.get("compounds_in", 0) != interval:
			res["compounds_in"] = interval
			changed = true
	if changed:
		debt_resources_changed.emit()


func _get_debt_resource(name: String) -> Dictionary:
	for res in debt_resources:
		if res.get("name", "") == name:
			return res
	return {}

func _set_credit_card_balance(used: float, limit: float) -> void:
	for res in debt_resources:
		if res.get("name", "") == "Credit Card":
			res["balance"] = used
			res["credit_limit"] = limit
			res["interest_rate"] = PortfolioManager.credit_interest_rate
			debt_resources_changed.emit()
			return
func _set_student_loan_balance(amount: float) -> void:
	for res in debt_resources:
		if res.get("name", "") == "Student Loan":
			res["balance"] = amount
			debt_resources_changed.emit()
			return



func _find_next_bill_date(bill_name: String) -> Dictionary:
	var day: int = TimeManager.current_day
	var month: int = TimeManager.current_month
	var year: int = TimeManager.current_year
	var days_ahead: int = 0

	# Safety guard: prevent infinite loops if bill not found
	var max_iterations: int = 365 * 5  # 5 years into the future

	for i in range(max_iterations):
		var bills: Array = get_due_bills_for_date(day, month, year)
		if bill_name in bills:
			return {
				"day": day,
				"month": month,
				"year": year,
				"days_ahead": days_ahead
			}

		# Advance one day
		day += 1
		if day > TimeManager.get_days_in_month(month, year):
			day = 1
			month += 1
			if month > 12:
				month = 1
				year += 1

		days_ahead += 1

	# If bill never found in horizon, still return something
	push_error("Bill not found within %d days: %s" % [max_iterations, bill_name])
	return {}



func _on_hour_passed(_hour: int, _total: int) -> void:
	_tick_down_compound_timers(60)
	apply_debt_interest()
func _on_minute_passed(_total: int) -> void:
	_tick_down_compound_timers(1)
	apply_debt_interest()
func _tick_down_compound_timers(delta: int) -> void:
	var changed := false
	for res in debt_resources:
		var minutes := int(res.get("compounds_in", 0))
		if minutes <= 0:
			continue
		if delta == 60 and minutes >= 1440:
			continue
		if delta == 1 and minutes >= 60:
			continue
		var new_minutes = max(minutes - delta, 0)
		if new_minutes != minutes:
			res["compounds_in"] = new_minutes
			changed = true
	if changed:
		debt_resources_changed.emit()
func reset() -> void:
	autopay_enabled = false
	active_bills.clear()
	pending_bill_data.clear()
	paid_bills.clear()
	debt_resources.clear()
	_initialize_default_lifestyle()



func get_save_data() -> Dictionary:
	return {
		"autopay_enabled": autopay_enabled,
		"lifestyle_categories": lifestyle_categories.duplicate(),
		"lifestyle_indices": lifestyle_indices.duplicate(),
		"debt_resources": debt_resources.duplicate(true),
		"paid_bills": paid_bills.duplicate(true)
	}


func load_from_data(data: Dictionary) -> void:
	autopay_enabled = data.get("autopay_enabled", false)
	lifestyle_categories = data.get("lifestyle_categories", {}).duplicate()
	lifestyle_indices = data.get("lifestyle_indices", {}).duplicate()
	paid_bills = data.get("paid_bills", {}).duplicate()
	active_bills.clear()
	pending_bill_data.clear()
	var temp: Array = data.get("debt_resources", []).duplicate(true)
	debt_resources.clear()
	for entry in temp:
		if typeof(entry) == TYPE_DICTIONARY:
			var res: Dictionary = entry as Dictionary
			if res.has("compounds_in") or res.has("compound_interval"):
				res["compound_interval"] = int(res.get("compound_interval", 0))
				res["compounds_in"] = int(res.get("compounds_in", res["compound_interval"]))
			else:
				var minutes := int(res.get("minutes_until_due", res.get("days_until_due", 0) * 1440))
				res["compound_interval"] = minutes
				res["compounds_in"] = minutes
			res.erase("minutes_until_due")
			res.erase("days_until_due")
			res.erase("compound_period")
			debt_resources.append(res)

	emit_signal("lifestyle_updated")
	debt_resources_changed.emit()
func register_popup(popup: BillPopupUI, date_key: String) -> void:
	if not active_bills.has(date_key):
		active_bills[date_key] = []
	active_bills[date_key].append(popup)


func show_due_popups() -> void:
	for date_key in pending_bill_data.keys():
			for bill_dict in pending_bill_data[date_key]:
					var pane = preload("res://components/popups/bill_popup_ui.tscn").instantiate()
					pane.init(bill_dict.get("bill_name", ""))
					pane.amount = bill_dict.get("amount", 0.0)
					pane.date_key = date_key

					var win = WindowFrame.instantiate_for_pane(pane)
					win.window_can_close = false
					win.window_can_minimize = false
					win.default_size = Vector2(360, 550)

					WindowManager.register_window(win, false)
					call_deferred("center_bill_window", win)

					register_popup(pane, date_key)

	pending_bill_data.clear()








## LIFESTYLE OPTIONS -- move to imported files later, when we set up EffectsResource system


func get_lifestyle_options(category: String) -> Array:
	return lifestyle_options.get(category, [])


var lifestyle_options := {
	"Housing": [
		{
			"name": "Basement bedroom with sketchy roommates",
			"cost": 300,
			"effects_label": "-1 Comfort",
			"effects": { "COMFORT_FLAT": -1 }
		},
		{
			"name": "Studio Apartment",
			"cost": 600,
			"effects_label": "+1 Comfort",
			"effects": { "COMFORT_FLAT": 1 }
		},
		{
			"name": "Condo Downtown",
			"cost": 1200,
			"effects_label": "+2 Comfort, +1 Reputation",
			"effects": { "COMFORT_FLAT": 2, "REPUTATION_FLAT": 1 }
		},
		{
			"name": "Luxury Loft w/ Rooftop Sauna",
			"cost": 7800,
			"effects_label": "+3 Comfort, +3 Reputation",
			"effects": { "COMFORT_FLAT": 3, "REPUTATION_FLAT": 3 }
		},
		{
			"name": "Penthouse Suite in Skyrise",
			"cost": 30000,
			"effects_label": "+5 Comfort, +5 Reputation, +1 Romance",
			"effects": { "COMFORT_FLAT": 5, "REPUTATION_FLAT": 5, "ROMANCE_FLAT": 1 }
		},
		{
			"name": "Private Island",
			"cost": 250000,
			"effects_label": "+7 Comfort, +7 Reputation, +2 Romance",
			"effects": { "COMFORT_FLAT": 7, "REPUTATION_FLAT": 7, "ROMANCE_FLAT": 2 }
		}
	],
	"Medical Insurance": [
		{
			"name": "None (Hope for the Best)",
			"cost": 0,
			"effects_label": "-3 Health, -2 Energy",
			"effects": { "HEALTH_FLAT": -3, "ENERGY_FLAT": -2 }
		},
		{
			"name": "State Emergency Coverage",
			"cost": 200,
			"effects_label": "-1 Health, +0 Energy",
			"effects": { "HEALTH_FLAT": -1 }
		},
		{
			"name": "Employer HMO Plan",
			"cost": 450,
			"effects_label": "+0 Health, +1 Energy",
			"effects": { "ENERGY_FLAT": 1 }
		},
		{
			"name": "Private PPO",
			"cost": 850,
			"effects_label": "+2 Health, +1 Energy",
			"effects": { "HEALTH_FLAT": 2, "ENERGY_FLAT": 1 }
		},
		{
			"name": "Concierge Healthcare",
			"cost": 2500,
			"effects_label": "+3 Health, +2 Energy, +1 Mood",
			"effects": { "HEALTH_FLAT": 3, "ENERGY_FLAT": 2, "MOOD_FLAT": 1 }
		},
		{
			"name": "Biohacker Wellness Protocol",
			"cost": 36000,
			"effects_label": "+4 Health, +3 Energy, +2 Attractiveness",
			"effects": { "HEALTH_FLAT": 4, "ENERGY_FLAT": 3, "ATTRACTIVENESS_FLAT": 2 }
		}
	],
	"Food": [
		{
			"name": "Instant Noodles & Tap Water",
			"cost": 35,
			"effects_label": "-1 Health, -1 Mood",
			"effects": { "HEALTH_FLAT": -1, "MOOD_FLAT": -1 }
		},
		{
			"name": "Fast Food Value Menu",
			"cost": 250,
			"effects_label": "+0 Health, +0 Mood",
			"effects": {}
		},
		{
			"name": "Balanced Meal Kit Subscription",
			"cost": 1200,
			"effects_label": "+1 Health, +1 Energy",
			"effects": { "HEALTH_FLAT": 1, "ENERGY_FLAT": 1 }
		},
		{
			"name": "Organic Groceries & Home Cooking",
			"cost": 6000,
			"effects_label": "+2 Health, +2 Mood",
			"effects": { "HEALTH_FLAT": 2, "MOOD_FLAT": 2 }
		},
		{
			"name": "Private Chef",
			"cost": 20000,
			"effects_label": "+3 Health, +3 Energy, +1 Attractiveness",
			"effects": { "HEALTH_FLAT": 3, "ENERGY_FLAT": 3, "ATTRACTIVENESS_FLAT": 1 }
		},
		{
			"name": "Michelin Connoisseur",
			"cost": 250000,
			"effects_label": "+4 Health, +5 Mood, +2 Attractiveness",
			"effects": { "HEALTH_FLAT": 4, "MOOD_FLAT": 5, "ATTRACTIVENESS_FLAT": 2 }
		}
	],
	"Entertainment": [
		{
			"name": "No Fun at All",
			"cost": 0,
			"effects_label": "-2 Mood",
			"effects": { "MOOD_FLAT": -2 }
		},
		{
			"name": "Occasional Netflix Night",
			"cost": 35,
			"effects_label": "+0 Mood",
			"effects": {}
		},
		{
			"name": "Concerts, Movies & Games",
			"cost": 510,
			"effects_label": "+2 Mood, +1 Energy",
			"effects": { "MOOD_FLAT": 2, "ENERGY_FLAT": 1 }
		},
		{
			"name": "VIP Experiences & Festivals",
			"cost": 8600,
			"effects_label": "+4 Mood, +2 Reputation",
			"effects": { "MOOD_FLAT": 4, "REPUTATION_FLAT": 2 }
		}
	],
	"Nightlife": [
		{
			"name": "Never Go Out",
			"cost": 0,
			"effects_label": "-1 Romance",
			"effects": { "ROMANCE_FLAT": -1 }
		},
		{
			"name": "Cheap Bars & Dive Nights",
			"cost": 350,
			"effects_label": "+1 Mood",
			"effects": { "MOOD_FLAT": 1 }
		},
		{
			"name": "Trendy Clubs & Date Spots",
			"cost": 2420,
			"effects_label": "+2 Romance, +2 Reputation",
			"effects": { "ROMANCE_FLAT": 2, "REPUTATION_FLAT": 2 }
		},
		{
			"name": "Bottle Service & Afterparties",
			"cost": 9000,
			"effects_label": "+3 Romance, +3 Mood, +2 Attractiveness",
			"effects": { "ROMANCE_FLAT": 3, "MOOD_FLAT": 3, "ATTRACTIVENESS_FLAT": 2 }
		}
	],
	"Transportation": [
		{
			"name": "Walk Everywhere",
			"cost": 0,
			"effects_label": "+1 Health, -1 Energy",
			"effects": { "HEALTH_FLAT": 1, "ENERGY_FLAT": -1 }
		},
		{
			"name": "Public Transit",
			"cost": 35,  # $5/day
			"effects_label": "+0 Mood",
			"effects": {}
		},
		{
			"name": "Used Beater Car",
			"cost": 250,  # 
			"effects_label": "+1 Energy",
			"effects": { "ENERGY_FLAT": 1 }
		},
		{
			"name": "Luxury Sports Car",
			"cost": 2400,  
			"effects_label": "+2 Energy, +2 Attractiveness",
			"effects": { "ENERGY_FLAT": 2, "ATTRACTIVENESS_FLAT": 2 }
		},
		{
			"name": "Private Chauffeur",
			"cost": 12500,  
			"effects_label": "+3 Energy, +3 Comfort, +2 Reputation",
			"effects": { "ENERGY_FLAT": 3, "COMFORT_FLAT": 3, "REPUTATION_FLAT": 2 }
		}
	],
}

func get_credit_summary() -> Dictionary:
			var out: Dictionary = {}
			out["balance"] = 0.0
			out["limit"] = 0.0
			out["apr"] = 0.0
			out["min_due"] = 0.0
			out["next_due"] = ""
			out["autopay"] = false
			if Engine.has_singleton("PortfolioManager"):
							out["balance"] = float(PortfolioManager.credit_used)
							out["limit"] = float(PortfolioManager.credit_limit)
			var info = _find_next_bill_date("Credit Card")
			var day = int(info.get("day", 0))
			var month = int(info.get("month", 0))
			var year = int(info.get("year", 0))
			var weekday = TimeManager.get_weekday_for_date(day, month, year)
			out["next_due"] = "%s %d/%d/%d" % [TimeManager.day_names[weekday], day, month, year]
			return out

func pay_credit(amount: float) -> void:
		credit_txn_occurred.emit(amount)
		debt_resources_changed.emit()
		var util: float = 0.0
		if Engine.has_singleton("PortfolioManager"):
				var limit: float = PortfolioManager.credit_limit
				var used: float = PortfolioManager.credit_used
				if limit > 0.0:
						util = (used / limit) * 100.0
		Events.focus_wallet_card("credit")
		Events.animate_wallet_to("credit", util)

func set_credit_autopay(_enabled: bool) -> void:
		debt_resources_changed.emit()

func get_last_credit_txn_ago() -> String:
		return "—"

func get_student_loan_summary() -> Dictionary:
		var out: Dictionary = {}
		out["principal"] = 0.0
		out["interest_rate"] = 0.0
		out["accrued_interest"] = 0.0
		out["next_due"] = ""
		out["min_due"] = 0.0
		out["autopay"] = false
		return out

func pay_student_loan(amount: float) -> void:
				pay_debt("Student Loan", amount)
				Events.focus_wallet_card("student_loan")

func set_student_loan_autopay(_enabled: bool) -> void:
		student_loan_changed.emit()
