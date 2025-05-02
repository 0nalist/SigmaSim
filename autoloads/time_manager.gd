extends Node

signal minute_passed(current_time_minutes: int)
signal hour_passed(current_hour: int)
signal day_passed(new_day: int, new_month: int, new_year: int)

var time_ticking := true

var autosave_enabled := true

var in_game_minutes := 23 * 60 
var time_accumulator := 0.0

@export var autosave_interval: int = 6 # Number of in-game hours between autosaves
var autosave_hour_counter := 0

@export var default_start_date_time: Dictionary = {
	"in_game_minutes": 23 * 60,
	"current_day": 1,
	"current_month": 3,
	"current_year": 2025,
	}

var current_minute := 0
var current_hour := 0
var current_day := 1
var current_month := 3
var current_year := 2025
var day_of_week := 0  # 0 = Monday, 6 = Sunday

var is_fast_forwarding := false
var fast_forward_minutes_left := 0

var day_names := ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
var month_names := [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]

func _ready() -> void:
	day_of_week = get_weekday_for_date(current_day, current_month, current_year)

func start_time() -> void: ## refactor to set_time_paused
	time_ticking = true
	print("time ticking")

func stop_time() -> void: ## refactor to set_time_paused
	time_ticking = false

func set_time_paused(paused: bool) -> void:
	time_ticking = not paused


func sleep_for(minutes: int) -> void:
	is_fast_forwarding = true
	fast_forward_minutes_left = minutes

func _process(delta: float) -> void:
	
	if not time_ticking:
		return
	if is_fast_forwarding:
		if fast_forward_minutes_left > 0:
			advance_time(1)
			fast_forward_minutes_left -= 1
		else:
			is_fast_forwarding = false
	else:
		time_accumulator += delta
		if time_accumulator >= 1.0:
			time_accumulator -= 1.0
			advance_time(1)

func parse_date(date_str: String) -> Dictionary:
	var parts = date_str.split("/")
	if parts.size() != 3:
		return {"day": 1, "month": 1, "year": 2025} # default safe date
	return {
		"day": int(parts[0]),
		"month": int(parts[1]),
		"year": int(parts[2])
	}


func advance_time(minutes_to_add: int) -> void:
	for _i in minutes_to_add:
		in_game_minutes += 1
		current_hour = (in_game_minutes / 60) % 24
		current_minute = in_game_minutes % 60

		emit_signal("minute_passed", in_game_minutes)

		if current_minute == 0:
			emit_signal("hour_passed", current_hour)
			autosave_hour_counter += 1
			if autosave_enabled and autosave_hour_counter >= autosave_interval:
				autosave_hour_counter = 0
				SaveManager.save_to_slot(PlayerManager.get_slot_id())
				print("💾 Autosave triggered at hour %d" % current_hour)

		if in_game_minutes >= 24 * 60:
			in_game_minutes = 0
			advance_day()


func advance_day() -> void:
	current_day += 1
	day_of_week = (day_of_week + 1) % 7

	if current_day > get_days_in_month(current_month, current_year):
		current_day = 1
		current_month += 1
		if current_month > 12:
			current_month = 1
			current_year += 1

	emit_signal("day_passed", current_day, current_month, current_year) #TODO 


func get_days_in_month(month: int, year: int) -> int:
	if month == 2:
		return 29 if is_leap_year(year) else 28
	elif month in [4, 6, 9, 11]:
		return 30
	elif month in [1, 3, 5, 7, 8, 10, 12]:
		return 31
	else:
		return 0  # Invalid


func is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)


func get_formatted_time() -> String:
	var hour_24 = current_hour
	var minute = current_minute
	var hour_12 = hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	var am_pm = "AM" if hour_24 < 12 else "PM"
	return "%s %d:%02d %s" % [day_names[day_of_week], hour_12, minute, am_pm]


func get_formatted_date() -> String:
	return "%s %d/%d/%d" % [day_names[day_of_week], current_day, current_month, current_year]


func get_today() -> Dictionary:
	return {
		"day": current_day,
		"month": current_month,
		"year": current_year
	}

func get_total_days_since_start(target_day: int, target_month: int, target_year: int) -> int:
	var start_day = default_start_date_time["current_day"]
	var start_month = default_start_date_time["current_month"]
	var start_year = default_start_date_time["current_year"]

	var total_days := 0

	# Count full years
	for y in range(start_year, target_year):
		total_days += 365
		if is_leap_year(y):
			total_days += 1

	# Count months in the final year
	var start_m = start_month if start_year == target_year else 1
	for m in range(start_m, target_month):
		total_days += get_days_in_month(m, target_year)

	# Count leftover days
	total_days += target_day - start_day

	return total_days


func date_is_before(date_a: Dictionary, date_b: Dictionary) -> bool:
	# Both inputs should be { "day": int, "month": int, "year": int }
	if date_a.year != date_b.year:
		return date_a.year < date_b.year
	elif date_a.month != date_b.month:
		return date_a.month < date_b.month
	else:
		return date_a.day < date_b.day


func get_first_weekday_of_month(month: int, year: int) -> int:
	var m = month
	var y = year
	if m < 3:
		m += 12
		y -= 1
	var q = 1
	var K = y % 100
	var J = y / 100
	var h = (q + int((13 * (m + 1)) / 5) + K + int(K / 4) + int(J / 4) + 5 * J) % 7
	return (h + 5) % 7  # 0 = Monday

func get_weekday_for_date(day: int, month: int, year: int) -> int:
	var m = month
	var y = year
	if m < 3:
		m += 12
		y -= 1
	var K = y % 100
	var J = y / 100
	var h = (day + int((13 * (m + 1)) / 5) + K + int(K / 4) + int(J / 4) + 5 * J) % 7
	return (h + 5) % 7  # 0 = Monday

func get_default_save_data() -> Dictionary:
	return default_start_date_time.duplicate()


## -- Save/Load

func get_save_data() -> Dictionary:
	return {
		"in_game_minutes": in_game_minutes,
		"current_day": current_day,
		"current_month": current_month,
		"current_year": current_year,
		"day_of_week": day_of_week,
		"is_fast_forwarding": is_fast_forwarding,
		"fast_forward_minutes_left": fast_forward_minutes_left
	}

func load_from_data(data: Dictionary) -> void:
	in_game_minutes = data.get("in_game_minutes", 0)
	current_hour = (in_game_minutes / 60) % 24
	current_minute = in_game_minutes % 60
	current_day = data.get("current_day", 1)
	current_month = data.get("current_month", 1)
	current_year = data.get("current_year", 2025)
	day_of_week = data.get("day_of_week", get_weekday_for_date(current_day, current_month, current_year))

	is_fast_forwarding = false
	fast_forward_minutes_left = 0

	# Then apply from save if present (only valid if explicitly true)
	if data.get("is_fast_forwarding", false):
		is_fast_forwarding = true
		fast_forward_minutes_left = data.get("fast_forward_minutes_left", 0)

	autosave_hour_counter = 0
	emit_signal("minute_passed", in_game_minutes)
	emit_signal("hour_passed", (in_game_minutes / 60) % 24)
	emit_signal("day_passed", current_day, current_month, current_year)

func reset() -> void:
	in_game_minutes = default_start_date_time["in_game_minutes"]
	current_day = default_start_date_time["current_day"]
	current_month = default_start_date_time["current_month"]
	current_year = default_start_date_time["current_year"]
	current_hour = (in_game_minutes / 60) % 24
	current_minute = in_game_minutes % 60
	day_of_week = get_weekday_for_date(current_day, current_month, current_year)

	time_accumulator = 0.0
	is_fast_forwarding = false
	fast_forward_minutes_left = 0
	autosave_hour_counter = 0
