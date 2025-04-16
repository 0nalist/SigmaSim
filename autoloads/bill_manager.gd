extends Node
# Autoload: BillManager

var autopay_enabled: bool = false

# Ordered list: Week 0 → Rent, Week 1 → Insurance, etc.
var weekly_bill_cycle := [
	{"name": "Rent", "color": Color.RED},
	{"name": "Medical Insurance", "color": Color.BLUE},
	{"name": "Student Loan", "color": Color.GREEN},
	{"name": "Credit Card", "color": Color.PURPLE}
]

var base_bill_amounts := {
	"Rent": 1200.0,
	"Medical Insurance": 300.0,
	"Student Loan": 400.0,
	"Credit Card": 0.0  # Dynamically calculated
}

func get_due_bills_for_month(month: int, year: int) -> Dictionary:
	var output: Dictionary = {}
	var days = TimeManager.get_days_in_month(month, year)

	for day in range(1, days + 1):
		var weekday = TimeManager.get_weekday_for_date(day, month, year)
		print("Day", day, "weekday =", weekday, "→", TimeManager.day_names[weekday])
		if weekday == 6:  # 6 = Sunday
			var week_index = int((day - 1) / 7)
			var bill_index = week_index % weekly_bill_cycle.size()
			var bill_info = weekly_bill_cycle[bill_index]
			output[day] = [bill_info.name]

	return output


func get_bill_color(bill_name: String) -> Color:
	for bill in weekly_bill_cycle:
		if bill.name == bill_name:
			return bill.color
	return Color.GRAY

func get_bill_amount(bill_name: String) -> float:
	return base_bill_amounts.get(bill_name, 0.0)
