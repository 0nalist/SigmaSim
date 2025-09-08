extends Pane

@export var click_catcher: Control = null

@onready var autopay_checkbox: CheckBox = %AutopayCheckBox
@onready var grid_container: GridContainer = %GridContainer
@export var day_panel_scene: PackedScene
@onready var month_year_label: Label = %MonthYearLabel
@onready var in_game_label: Label = %InGameTimeElapsedLabel
@onready var real_time_label: Label = %RealTimeElapsedLabel

func _ready():
	hide()
	autopay_checkbox.set_pressed_no_signal(BillManager.autopay_enabled)
	BillManager.autopay_changed.connect(_on_autopay_changed)
	TimeManager.day_passed.connect(_on_day_passed)
	TimeManager.minute_passed.connect(_on_minute_passed)
	populate_calendar(TimeManager.current_month, TimeManager.current_year)
	month_year_label.text = str(TimeManager.month_names[TimeManager.current_month-1]) + " " + str(TimeManager.current_year)
	_update_elapsed_labels()
	call_deferred("move_to_front")

func add_click_catcher() -> void:
	click_catcher = preload("res://components/ui/click_catcher.tscn").instantiate()
	click_catcher.clicked_outside.connect(_on_click_outside)
	get_tree().root.add_child(click_catcher)
	move_to_front()

func _on_click_outside(pos: Vector2) -> void:
	if not get_global_rect().has_point(pos):
		close()

func open() -> void:
	add_click_catcher()
	show()
	set_z_index(1000)  # Ensure it's above any regular window

func close() -> void:
	if click_catcher:
		click_catcher.queue_free()
		click_catcher = null
	hide()

func _on_day_passed(_day: int, month: int, year: int):
	populate_calendar(month, year)
	_update_elapsed_labels()

func _on_minute_passed(_total_minutes: int) -> void:
	_update_elapsed_labels()

func populate_calendar(month: int, year: int) -> void:
	var days_in_month = TimeManager.get_days_in_month(month, year)
	var first_weekday: int = int(TimeManager.get_first_weekday_of_month(month, year))  # 0 = Monday
	var today = TimeManager.get_today()
	var due_bills = BillManager.get_due_bills_for_month(month, year)  # {day: Array[String]}

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
	month_year_label.text = str(TimeManager.month_names[TimeManager.current_month-1]) + " " + str(TimeManager.current_year)

func _on_autopay_check_box_toggled(toggled_on: bool) -> void:
	BillManager.autopay_enabled = toggled_on

func _on_autopay_changed(enabled: bool) -> void:
	autopay_checkbox.set_pressed_no_signal(enabled)

func _on_life_stylist_button_pressed() -> void:
	WindowManager.launch_app_by_name("LifeStylist")

func _on_ower_view_button_pressed() -> void:
	WindowManager.launch_app_by_name("OwerView")

func _update_elapsed_labels() -> void:
       in_game_label.text = _format_elapsed(TimeManager.get_total_minutes_played())
       var total_real_seconds := int(TimeManager.get_total_real_seconds_played())
       var real_minutes := total_real_seconds / 60
       var real_seconds := total_real_seconds % 60
       real_time_label.text = "%s:%02d" % [_format_elapsed(real_minutes), real_seconds]

func _format_elapsed(total_minutes: int) -> String:
	var years := total_minutes / (60 * 24 * 365)
	var rem := total_minutes % (60 * 24 * 365)
	var days := rem / (60 * 24)
	rem %= 60 * 24
	var hours := rem / 60
	var minutes := rem % 60
	var parts: Array[String] = []
	if years > 0:
		parts.append(str(years))
	if days > 0 or years > 0:
		parts.append(str(days))
	parts.append("%02d:%02d" % [hours, minutes])
	return ":".join(parts)
