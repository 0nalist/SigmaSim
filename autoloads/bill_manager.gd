extends Node
# Autoload: BillManager

signal lifestyle_updated
signal autopay_changed(enabled: bool)
signal debt_resources_changed

const DebtResource = preload("res://resources/debt/debt_resource.gd")

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

var lifestyle_categories := {}  # category_name: Dictionary
var debt_resources: Array[DebtResource] = []
var custom_debt_balances: Dictionary = {}


# Ordered list: Week 0 → Rent, Week 1 → Insurance, etc.
var weekly_bill_cycle := [
	{"name": "Rent", "color": Color.RED},
	{"name": "Medical Insurance", "color": Color.BLUE},
	{"name": "Student Loan", "color": Color.GREEN},
	{"name": "Credit Card", "color": Color.PURPLE},
]

var static_bill_amounts := {}

var is_loading := false


func _ready() -> void:
        TimeManager.day_passed.connect(_on_day_passed)
        #TimeManager.hour_passed.connect(_on_hour_passed)
        PortfolioManager.credit_updated.connect(_on_credit_updated)
        if lifestyle_categories.is_empty():
                for category in lifestyle_options.keys():
                        var option = lifestyle_options[category][0]
                        set_lifestyle_choice(category, option, 0)
        _rebuild_debt_resources()
        print("active bills: " + str(active_bills))

func _rebuild_debt_resources() -> void:
        debt_resources.clear()
        var credit := DebtResource.new()
        credit.name = "Credit Card"
        credit.get_balance = func(): return PortfolioManager.credit_used
        credit.get_limit = func(): return PortfolioManager.credit_limit
        credit.pay = func(amount):
                PortfolioManager.pay_down_credit(amount)
                return true
        debt_resources.append(credit)

        var student := DebtResource.new()
        student.name = "Student Loan"
        student.get_balance = func(): return PortfolioManager.get_student_loans()
        student.pay = func(amount):
                if PortfolioManager.pay_with_cash(amount):
                        PortfolioManager.set_student_loans(max(PortfolioManager.get_student_loans() - amount, 0.0))
                        return true
                return false
        debt_resources.append(student)

        for name in custom_debt_balances.keys():
                var res := DebtResource.new()
                res.name = name
                res.get_balance = func(n := name): return custom_debt_balances[n]
                res.pay = func(amount, n := name):
                        if PortfolioManager.pay_with_cash(amount):
                                custom_debt_balances[n] = max(custom_debt_balances[n] - amount, 0.0)
                                return true
                        return false
                debt_resources.append(res)
        debt_resources_changed.emit()

func add_custom_debt(name: String, amount: float) -> void:
        custom_debt_balances[name] = amount
        _rebuild_debt_resources()

func get_debt_resources() -> Array[DebtResource]:
        return debt_resources


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

	var bills_today = get_due_bills_for_date(new_day, new_month, new_year)

	for bill_name in bills_today:
		# 🧠 Check if this bill popup already exists or is pending for today
		var already_open := false
		for existing in active_bills[today_key]:
				if is_instance_valid(existing) and existing.bill_name == bill_name:
						already_open = true
						break
		if not already_open:
				for pending in pending_bill_data[today_key]:
						if pending.get("bill_name", "") == bill_name:
								already_open = true
								break

		if already_open:
				continue  # ✅ Skip duplicate

		var amount := get_bill_amount(bill_name)
		if amount <= 0.0:
				print("Skipping %s bill (amount is 0)" % bill_name)
				continue

		if autopay_enabled and attempt_to_autopay(bill_name):
			continue

		# Queue bill popup for display
		pending_bill_data[today_key].append({
				"bill_name": bill_name,
				"amount": amount
		})

	show_due_popups()





func _on_credit_updated(used: float, _limit: float) -> void:
	# Update any open Credit Card bill popups
	for bill_list in active_bills.values():
		for popup in bill_list:
			if is_instance_valid(popup) and popup.bill_name == "Credit Card":
				popup.amount = get_bill_amount("Credit Card")
				popup.update_amount_display() 


func center_bill_window(win: WindowFrame) -> void:
	var screen_size = get_viewport().get_visible_rect().size
	win.position = (screen_size - win.default_size) / 2


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
	var bills: Array[String] = []
	var weekday = TimeManager.get_weekday_for_date(day, month, year)

	if weekday == 6:  # Sunday
		var total_days = TimeManager.get_total_days_since_start(day, month, year)
		var week_index = int(total_days / 7)

		if week_index % 4 == 0:
			bills.append("Rent")
		if week_index % 4 == 1:
			bills.append("Medical Insurance")
		if week_index % 4 == 2:
			bills.append("Student Loan")
		if week_index % 4 == 3:
			bills.append("Credit Card")

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
				popup.close()
				return
			elif PortfolioManager.can_pay_with_credit(popup.amount):
				PortfolioManager.pay_with_credit(popup.amount)
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


func get_popup_save_data() -> Array:
	var popup_data := []
	for date_key in active_bills.keys():
		for popup in active_bills[date_key]:
			if is_instance_valid(popup):
				popup_data.append({
					"type": "BillPopupUI",
					"bill_name": popup.bill_name,
					"amount": popup.amount,
					"date_key": date_key
				})

	for date_key in pending_bill_data.keys():
		for bill_dict in pending_bill_data[date_key]:
			popup_data.append({
				"type": "BillPopupUI",
				"bill_name": bill_dict.get("bill_name", ""),
				"amount": bill_dict.get("amount", 0.0),
				"date_key": date_key
			})
	return popup_data


func reset() -> void:
        autopay_enabled = false
        active_bills.clear()
        pending_bill_data.clear()
        lifestyle_categories.clear()
        lifestyle_indices.clear()
        custom_debt_balances.clear()
        _rebuild_debt_resources()
        emit_signal("lifestyle_updated")


func get_save_data() -> Dictionary:
        return {
                "autopay_enabled": autopay_enabled,
                "lifestyle_categories": lifestyle_categories.duplicate(),
                "lifestyle_indices": lifestyle_indices.duplicate(),
                "pane_data": get_pane_save_data(),
                "custom_debts": custom_debt_balances.duplicate()
        }

func load_from_data(data: Dictionary) -> void:
        autopay_enabled = data.get("autopay_enabled", false)
        lifestyle_categories = data.get("lifestyle_categories", {}).duplicate()
        lifestyle_indices = data.get("lifestyle_indices", {}).duplicate()
        custom_debt_balances = data.get("custom_debts", {}).duplicate()
        active_bills.clear()
        pending_bill_data.clear()
        emit_signal("lifestyle_updated")
        _rebuild_debt_resources()

	if data.has("pane_data"):
			for pane_dict in data["pane_data"]:
					if typeof(pane_dict) != TYPE_DICTIONARY:
							continue

					var date_key = pane_dict.get("date_key", TimeManager.get_formatted_date())
					var popup_date_parts = date_key.split("/")
					if popup_date_parts.size() != 3:
							continue  # Skip invalid dates

					var popup_date = {
							"day": int(popup_date_parts[0]),
							"month": int(popup_date_parts[1]),
							"year": int(popup_date_parts[2])
					}

					if TimeManager.date_is_before(popup_date, TimeManager.get_today()):
							continue  # Skip old bills

					if not pending_bill_data.has(date_key):
							pending_bill_data[date_key] = []
					pending_bill_data[date_key].append({
							"bill_name": pane_dict.get("bill_name", ""),
							"amount": pane_dict.get("amount", 0.0)
					})


func show_due_popups() -> void:
	for date_key in pending_bill_data.keys():
		for bill_dict in pending_bill_data[date_key]:
			var pane = preload("res://components/popups/bill_popup_ui.tscn").instantiate()
			pane.init(bill_dict.get("bill_name", ""))
			pane.amount = bill_dict.get("amount", 0.0)

			var win = WindowFrame.instantiate_for_pane(pane)
			win.window_can_close = false
			win.window_can_minimize = false
			win.default_size = Vector2(360, 550)

			WindowManager.register_window(win, false)
			call_deferred("center_bill_window", win)

			if not active_bills.has(date_key):
					active_bills[date_key] = []
			active_bills[date_key].append(pane)

	pending_bill_data.clear()






func get_pane_save_data() -> Array:
	var pane_data := []
	for date_key in active_bills.keys():
			for pane in active_bills[date_key]:
					if is_instance_valid(pane):
							pane_data.append({
									"type": "BillPopupUI",
									"bill_name": pane.bill_name,
									"amount": pane.amount,
									"date_key": date_key
							})

	for date_key in pending_bill_data.keys():
			for bill_dict in pending_bill_data[date_key]:
					pane_data.append({
							"type": "BillPopupUI",
							"bill_name": bill_dict.get("bill_name", ""),
							"amount": bill_dict.get("amount", 0.0),
							"date_key": date_key
					})
	return pane_data








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
