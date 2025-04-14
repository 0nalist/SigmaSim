extends Node

signal minute_passed(current_time_minutes: int)
signal hour_passed(current_hour: int)
signal day_passed(new_day: int, new_month: int, new_year: int)

var in_game_minutes := 4 * 60 #+ 20  # Start at 4:20 AM
var time_accumulator := 0.0

var current_day := 1
var current_month := 1
var current_year := 2025
var day_of_week := 0  # 0 = Monday, 6 = Sunday

var is_fast_forwarding := false
var fast_forward_minutes_left := 0

var days_in_month := {
	1: 31, 2: 28, 3: 31, 4: 30, 5: 31, 6: 30,
	7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31
}

var day_names := ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

func _process(delta: float) -> void:
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

func advance_time(minutes_to_add: int) -> void:
	for _i in minutes_to_add:
		in_game_minutes += 1
		emit_signal("minute_passed", in_game_minutes)

		if in_game_minutes % 60 == 0:
			var hour = (in_game_minutes / 60) % 24
			emit_signal("hour_passed", hour)

		if in_game_minutes >= 24 * 60:
			in_game_minutes = 0
			advance_day()

func advance_day() -> void:
	current_day += 1
	day_of_week = (day_of_week + 1) % 7

	var dim = days_in_month.get(current_month, 30)
	if current_month == 2 and is_leap_year(current_year):
		dim = 29

	if current_day > dim:
		current_day = 1
		current_month += 1
		if current_month > 12:
			current_month = 1
			current_year += 1

	emit_signal("day_passed", current_day, current_month, current_year)

func is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

func sleep_for(minutes: int) -> void:
	is_fast_forwarding = true
	fast_forward_minutes_left = minutes

func get_formatted_time() -> String:
	var total_minutes = in_game_minutes % (24 * 60)
	var hour_24 = total_minutes / 60
	var minute = total_minutes % 60

	var hour_12 = hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12

	var am_pm = "AM" if hour_24 < 12 else "PM"
	var day_str = day_names[day_of_week]

	return "%s %d:%02d %s" % [day_str, hour_12, minute, am_pm]


func get_formatted_date() -> String:
	var day_str = day_names[day_of_week]
	return "%s %d/%d/%d" % [day_str, current_day, current_month, current_year]
