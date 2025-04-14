extends Node
#class_name TimeManager

signal minute_passed(current_time_minutes: int)
signal hour_passed(current_hour: int)

var in_game_minutes := 4 * 60 + 20  # 4:20 AM
var time_accumulator := 0.0

var is_fast_forwarding := false
var fast_forward_minutes_left := 0

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
	return "%d:%02d %s" % [hour_12, minute, am_pm]
