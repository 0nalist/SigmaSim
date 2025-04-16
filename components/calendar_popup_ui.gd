extends BasePopupUI

@onready var autopay_checkbox: CheckBox = %AutopayCheckBox
@onready var grid_container: GridContainer = %GridContainer
@onready var day_panel_scene: PackedScene = preload("res://components/calendar_day_panel.tscn")
@onready var month_year_label: Label = %MonthYearLabel


func _ready():
	autopay_checkbox.button_pressed = BillManager.autopay_enabled
	autopay_checkbox.toggled.connect(_on_autopay_toggled)
	populate_calendar(TimeManager.current_month, TimeManager.current_year)

func _on_autopay_toggled(pressed: bool) -> void:
	BillManager.autopay_enabled = pressed

func populate_calendar(month: int, year: int) -> void:
	var days_in_month = TimeManager.get_days_in_month(month, year)
	var first_weekday = TimeManager.get_first_weekday_of_month(month, year)
	var today = TimeManager.get_today()
	var due_bills := BillManager.get_due_bills_for_month(month, year)  # {int: Array[String]}

	# Clear the grid
	for child in grid_container.get_children():
		child.queue_free()

	var total_cells = 42
	for i in range(total_cells):
		var day_num = i - first_weekday + 1
		var is_valid_day := day_num > 0 and day_num <= days_in_month

		var panel := day_panel_scene.instantiate()

		if is_valid_day:
			var is_past = (
				year < today.year or
				(year == today.year and month < today.month) or
				(year == today.year and month == today.month and day_num < today.day)
			)
			var bills_today: Array[String] = []
			if due_bills.has(day_num):
				for b in due_bills[day_num]:
					if typeof(b) == TYPE_STRING:
						bills_today.append(b)
			panel.call_deferred("set_day", day_num, is_past, bills_today)
		else:
			panel.visible = false

		grid_container.add_child(panel)
