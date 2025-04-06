extends Panel

@onready var time_label = $TimeLabel

var in_game_minutes = 4 * 60 + 20  # Start at 4:20 AM
var time_accumulator = 0.0

func _process(delta):
	time_accumulator += delta
	if time_accumulator >= 1.0:
		time_accumulator -= 1.0
		advance_time(1)

func advance_time(minutes_to_add: int):
	in_game_minutes += minutes_to_add

	var total_minutes = in_game_minutes % (24 * 60)
	var hour_24 = int(total_minutes / 60)
	var minute = total_minutes % 60

	var hour_12 = hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12

	var am_pm = "AM" if hour_24 < 12 else "PM"

	var time_string = "%d:%02d %s" % [hour_12, minute, am_pm]
	time_label.text = time_string
