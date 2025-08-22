extends Node
# Autoload: TimeManager

signal minute_passed(total_minutes: int)
signal hour_passed(current_hour: int, total_minutes: int)
signal day_passed(new_day: int, new_month: int, new_year: int, total_minutes: int)

var time_ticking := false:
	set(value):
		time_ticking = value

@export var autosave_enabled := true
@export var autosave_interval: int = 6 # Number of in-game hours between autosaves

@export var default_start_date_time: Dictionary = {
	"in_game_minutes": 23 * 60,
	"current_day": 1,
	"current_month": 3,
	"current_year": 2025
}

# Canonical clock: total in-game minutes since campaign start
var _total_minutes_elapsed: int = 0

# -------- Derived / compatibility fields (kept, but driven from _total_minutes_elapsed) --------
var in_game_minutes := 23 * 60
var time_accumulator := 0.0
var total_minutes_elapsed: int = 0 # kept for compatibility, mirrors _total_minutes_elapsed

var current_minute := 0
var current_hour := 0
var current_day := 1
var current_month := 3
var current_year := 2025
var day_of_week := 0 # 0 = Monday, 6 = Sunday

var is_fast_forwarding := false
var fast_forward_minutes_left := 0

var autosave_hour_counter := 0

var day_names := ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
var month_names := [
	"January","February","March","April","May","June",
	"July","August","September","October","November","December"
]

# -------- Lifecycle --------
func _ready() -> void:
	# Initialize from defaults and compute derived values
	_rebuild_total_minutes_from_defaults()
	_recompute_from_total_minutes()
	time_ticking = false

# -------- Public control API (unchanged names) --------
func start_time() -> void: # kept for compatibility
	time_ticking = true

func stop_time() -> void: # kept for compatibility
	time_ticking = false

func set_time_paused(paused: bool) -> void:
	time_ticking = not paused

func sleep_for(minutes: int) -> void:
	if minutes <= 0:
		return
	is_fast_forwarding = true
	fast_forward_minutes_left = minutes

func on_logout() -> void:
	set_time_paused(true)

# -------- Process loop --------
func _process(delta: float) -> void:
	if not time_ticking:
		return
	if is_fast_forwarding:
		if fast_forward_minutes_left > 0:
			_advance_time(1)
			fast_forward_minutes_left -= 1
		else:
			is_fast_forwarding = false
	else:
 # 1 real second -> 1 in-game minute, unchanged behavior
		time_accumulator += delta
		if time_accumulator >= 1.0:
			time_accumulator -= 1.0
			_advance_time(1)

# -------- Canonical getters (new + compatibility) --------
func get_now_minutes() -> int:
        return _total_minutes_elapsed

# Kept for callers that still use in-game minutes since midnight
func get_time_hms() -> Dictionary:
	return {"hour": current_hour, "minute": current_minute}

func get_formatted_time() -> String:
	var hour_24 := current_hour
	var minute := current_minute
	var hour_12 := hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	var am_pm := "AM"
	if hour_24 >= 12:
		am_pm = "PM"
	return "%s %d:%02d %s" % [day_names[day_of_week], hour_12, minute, am_pm]

func get_formatted_date() -> String:
	return "%s %d/%d/%d" % [day_names[day_of_week], current_day, current_month, current_year]

func get_today() -> Dictionary:
	return {"day": current_day, "month": current_month, "year": current_year}

# -------- Date utilities (unchanged names; bugs fixed to use Dictionary access) --------
func parse_date(date_str: String) -> Dictionary:
	var parts := date_str.split("/")
	if parts.size() != 3:
		return {"day": 1, "month": 1, "year": 2025}
	return {"day": int(parts[0]), "month": int(parts[1]), "year": int(parts[2])}

func date_is_before(date_a: Dictionary, date_b: Dictionary) -> bool:
	var ya := int(date_a.get("year", 0))
	var yb := int(date_b.get("year", 0))
	if ya != yb:
		return ya < yb
	var ma := int(date_a.get("month", 0))
	var mb := int(date_b.get("month", 0))
	if ma != mb:
		return ma < mb
	var da := int(date_a.get("day", 0))
	var db := int(date_b.get("day", 0))
	return da < db

func get_first_weekday_of_month(month: int, year: int) -> int:
	# Zeller’s congruence variant, normalized to 0=Mon
	var m := month
	var y := year
	if m < 3:
		m += 12
		y -= 1
	var q := 1
	var K := y % 100
	var J := y / 100
	var h := (q + int((13 * (m + 1)) / 5) + K + int(K / 4) + int(J / 4) + 5 * J) % 7
	return (h + 5) % 7

func get_weekday_for_date(day: int, month: int, year: int) -> int:
	var m := month
	var y := year
	if m < 3:
		m += 12
		y -= 1
	var K := y % 100
	var J := y / 100
	var h := (day + int((13 * (m + 1)) / 5) + K + int(K / 4) + int(J / 4) + 5 * J) % 7
	return (h + 5) % 7 # 0 = Monday

func get_days_in_month(month: int, year: int) -> int:
	if month == 2:
		if is_leap_year(year):
			return 29
		return 28
	if month in [4, 6, 9, 11]:
		return 30
	if month in [1, 3, 5, 7, 8, 10, 12]:
		return 31
	return 0

func is_leap_year(year: int) -> bool:
	if year % 400 == 0:
		return true
	if year % 100 == 0:
		return false
	return year % 4 == 0

# Historical helper retained (used elsewhere)
func get_total_days_since_start(target_day: int, target_month: int, target_year: int) -> int:
	var start_day := int(default_start_date_time.get("current_day", 1))
	var start_month := int(default_start_date_time.get("current_month", 1))
	var start_year := int(default_start_date_time.get("current_year", 2025))
	var total_days := 0
	# Years
	var y := start_year
	while y < target_year:
		total_days += 365
		if is_leap_year(y):
			total_days += 1
		y += 1
	# Months of final year
	var start_m := start_month
	if start_year != target_year:
		start_m = 1
	var m := start_m
	while m < target_month:
		total_days += get_days_in_month(m, target_year)
		m += 1
	# Remaining days
        total_days += target_day - start_day
        return total_days

func get_total_minutes_played() -> int:
        return _total_minutes_elapsed

# -------- Save / Load (keys preserved) --------
func get_default_save_data() -> Dictionary:
	return default_start_date_time.duplicate()

func get_save_data() -> Dictionary:
	return {
		"in_game_minutes": in_game_minutes,
		"total_minutes_elapsed": _total_minutes_elapsed,
		"current_day": current_day,
		"current_month": current_month,
		"current_year": current_year,
		"day_of_week": day_of_week,
		"is_fast_forwarding": is_fast_forwarding,
		"fast_forward_minutes_left": fast_forward_minutes_left
	}

func load_from_data(data: Dictionary) -> void:
	# Restore canonical minutes if provided; otherwise reconstruct from provided date/time
	var has_total := data.has("total_minutes_elapsed")
	if has_total:
		_total_minutes_elapsed = int(data.get("total_minutes_elapsed", 0))
	else:
		var restored_day := int(data.get("current_day", 1))
		var restored_month := int(data.get("current_month", 1))
		var restored_year := int(data.get("current_year", 2025))
		var minutes_since_midnight := int(data.get("in_game_minutes", 0))
		_total_minutes_elapsed = _days_since_epoch(restored_day, restored_month, restored_year) * 1440 + minutes_since_midnight

	# Restore fast-forward UI state
	is_fast_forwarding = false
	fast_forward_minutes_left = 0
	if bool(data.get("is_fast_forwarding", false)):
		is_fast_forwarding = true
		fast_forward_minutes_left = int(data.get("fast_forward_minutes_left", 0))

	# Recompute and mirror compatibility fields
	_recompute_from_total_minutes()

	autosave_hour_counter = 0
	# Emit signals to let listeners refresh
	emit_signal("minute_passed", in_game_minutes)
	emit_signal("hour_passed", current_hour, _total_minutes_elapsed)
	emit_signal("day_passed", current_day, current_month, current_year)

func reset() -> void:
	_rebuild_total_minutes_from_defaults()
	_recompute_from_total_minutes()
	time_accumulator = 0.0
	is_fast_forwarding = false
	fast_forward_minutes_left = 0
	autosave_hour_counter = 0

# -------- Internal core (driven by _total_minutes_elapsed) --------
func _advance_time(minutes_to_add: int) -> void:
	if minutes_to_add <= 0:
		return
	for _i in range(minutes_to_add):
		var prev_day := current_day
		var prev_month := current_month
		var prev_year := current_year

		_total_minutes_elapsed += 1
		_recompute_from_total_minutes()

		# Minute signal (uses minutes since midnight for back-compat)
		emit_signal("minute_passed", in_game_minutes)

		# Hour crossed when minute hits 0
		if current_minute == 0:
			emit_signal("hour_passed", current_hour, _total_minutes_elapsed)
			autosave_hour_counter += 1
			if autosave_enabled and autosave_hour_counter >= autosave_interval:
				autosave_hour_counter = 0
				SaveManager.save_to_slot(SaveManager.current_slot_id)
				print("Autosaving on slot " + str(SaveManager.current_slot_id))

		# Day rollover detection via date change
		if current_day != prev_day or current_month != prev_month or current_year != prev_year:
			emit_signal("day_passed", current_day, current_month, current_year)

	# Mirror compatibility field after loop
	total_minutes_elapsed = _total_minutes_elapsed

func _rebuild_total_minutes_from_defaults() -> void:
	var start_day := int(default_start_date_time.get("current_day", 1))
	var start_month := int(default_start_date_time.get("current_month", 1))
	var start_year := int(default_start_date_time.get("current_year", 2025))
	var start_minutes := int(default_start_date_time.get("in_game_minutes", 0))
	_total_minutes_elapsed = _days_since_epoch(start_day, start_month, start_year) * 1440 + start_minutes

func _recompute_from_total_minutes() -> void:
	# Compute wall date/time from canonical minutes
	var days_total := _total_minutes_elapsed / 1440
	var minutes_since_midnight := _total_minutes_elapsed % 1440
	current_hour = (minutes_since_midnight / 60) % 24
	current_minute = minutes_since_midnight % 60
	in_game_minutes = minutes_since_midnight

	# Walk forward from epoch date to current date
	var base_day := int(default_start_date_time.get("current_day", 1))
	var base_month := int(default_start_date_time.get("current_month", 1))
	var base_year := int(default_start_date_time.get("current_year", 2025))

	var d := base_day
	var m := base_month
	var y := base_year
	var remaining := days_total
	while remaining > 0:
		var dim := get_days_in_month(m, y)
		if d < dim:
			d += 1
			remaining -= 1
		else:
			d = 1
			if m < 12:
				m += 1
			else:
				m = 1
				y += 1
			remaining -= 1

	current_day = d
	current_month = m
	current_year = y
	day_of_week = get_weekday_for_date(current_day, current_month, current_year)

	# Mirror compatibility
	total_minutes_elapsed = _total_minutes_elapsed

func _days_since_epoch(day: int, month: int, year: int) -> int:
	var sd := int(default_start_date_time.get("current_day", 1))
	var sm := int(default_start_date_time.get("current_month", 1))
	var sy := int(default_start_date_time.get("current_year", 2025))

	var days := 0

	# Years
	var y := sy
	while y < year:
		days += 365
		if is_leap_year(y):
			days += 1
		y += 1

	# Months in the final year
	var start_m := sm
	if sy != year:
		start_m = 1
	var m := start_m
	while m < month:
		days += get_days_in_month(m, year)
		m += 1

	# Remaining days
	days += day - sd
	return days
