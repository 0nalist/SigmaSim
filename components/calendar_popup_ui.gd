extends BasePopupUI

@onready var autopay_checkbox: CheckBox = %AutopayCheckBox
@onready var grid_container: GridContainer = %GridContainer
@onready var day_panel_scene: PackedScene = preload("res://components/calendar_day_panel.tscn")
@onready var month_year_label: Label = %MonthYearLabel


func _ready():
	autopay_checkbox.button_pressed = BillManager.autopay_enabled
	autopay_checkbox.toggled.connect(_on_autopay_toggled)
	TimeManager.day_passed.connect(_on_day_passed)
	populate_calendar(TimeManager.current_month, TimeManager.current_year)
	month_year_label.text = str(TimeManager.month_names[TimeManager.current_month-1]) + " " + str(TimeManager.current_year)

func _on_day_passed(_day: int, month: int, year: int):
	populate_calendar(month, year)

func _on_autopay_toggled(pressed: bool) -> void:
	BillManager.autopay_enabled = pressed

func populate_calendar(month: int, year: int) -> void:
	var days_in_month := TimeManager.get_days_in_month(month, year)
	var first_weekday: int = int(TimeManager.get_first_weekday_of_month(month, year))  # 0 = Monday
	print("First weekday for", month, year, "is index:", first_weekday)
	var today := TimeManager.get_today()
	var due_bills := BillManager.get_due_bills_for_month(month, year)  # {day: Array[String]}

	# Clear all previous panels
	for child in grid_container.get_children():
		child.queue_free()

	var day_number := 1

	for i in range(42):
		var panel := day_panel_scene.instantiate()

		if i < first_weekday:
			panel.call_deferred("set_empty")

		elif day_number <= days_in_month:
			var is_past = (
				year < today.year or
				(year == today.year and month < today.month) or
				(year == today.year and month == today.month and day_number < today.day)
			)

			var bills_today: Array[String] = []
			if due_bills.has(day_number):
				for b in due_bills[day_number]:
					if typeof(b) == TYPE_STRING:
						bills_today.append(b)

			panel.call_deferred("set_day", day_number, is_past, bills_today)
			day_number += 1

		else:
			panel.call_deferred("set_empty")

		grid_container.add_child(panel)
	for panel in grid_container.get_children():
		if not panel.has_method("set_today_indicator"):
			continue

		if panel.day == today.day and month == today.month and year == today.year:
			panel.set_today_indicator(true)
		else:
			panel.set_today_indicator(false)


func _on_autopay_check_box_toggled(toggled_on: bool) -> void:
	BillManager.autopay_enabled = toggled_on
