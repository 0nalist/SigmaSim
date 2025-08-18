extends Pane
class_name HirePopup

@onready var hire_list: VBoxContainer = %HireList
@onready var hire_sort_dropdown: OptionButton = %HireSortDropdown
@onready var hire_high_low_button: Button = %HireHighLowButton
@onready var refresh_countdown_label: Label = %RefreshCountdownLabel

var hire_sort_property: String = "productivity"
var hire_sort_descending: bool = true

func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	WorkerManager.available_workers_updated.connect(_populate_hire_tab)
	hire_sort_dropdown.item_selected.connect(_on_hire_sort_property_changed)
	hire_high_low_button.pressed.connect(_on_hire_high_low_button_pressed)

	_init_dropdown()
	_populate_hire_tab()
	_update_refresh_countdown()

# --- HIRE TAB --- #

func _populate_hire_tab() -> void:
	for child in hire_list.get_children():
		child.queue_free()

	var sorted_workers = sort_workers_by(hire_sort_property, hire_sort_descending)

	for worker in sorted_workers:
		var card = preload("res://components/ui/worker_card/worker_card_redux.tscn").instantiate()
		card.show_cost = true
		card.show_status = false
		card.button_label = "Hire"
		card.setup(worker)
		card.action_pressed.connect(func(w):
			var cost = w.get_hire_cost()
			print("worker costs: " + str(cost))
			if PortfolioManager.attempt_spend(cost):
				WorkerManager.hire_worker(w)
				WorkerManager.available_workers.erase(w)
				_populate_hire_tab()
			else:
				print("Not enough funds!")
		)
		hire_list.add_child(card)

func sort_workers_by(property: String, descending := true) -> Array[Worker]:
	var workers = WorkerManager.available_workers.duplicate()

	workers.sort_custom(func(a: Worker, b: Worker) -> bool:
		var a_value = get_worker_sort_value(a, property)
		var b_value = get_worker_sort_value(b, property)
		return a_value > b_value if descending else a_value < b_value
	)

	return workers

func get_worker_sort_value(worker: Worker, property: String) -> float:
	match property:
		"productivity": return worker.productivity_per_tick
		"day_rate": return worker.get_day_rate()
		"productivity_per_day_rate": return worker.productivity_per_tick / max(worker.get_day_rate(), 0.01)
		"type": return 0.0 if worker.is_contractor else 1.0  # Contractors first if ascending
		_: return 0.0

# --- DROPDOWNS / SORT --- #

func _init_dropdown() -> void:
	hire_sort_dropdown.clear()
	hire_sort_dropdown.add_item("Productivity", 0)
	hire_sort_dropdown.add_item("Day Rate", 1)
	hire_sort_dropdown.add_item("Productivity / Day Rate", 2)
	hire_sort_dropdown.add_item("Type (Employee/Contractor)", 3)

	var popup = hire_sort_dropdown.get_popup()
	popup.add_theme_font_size_override("font_size", 12)

func _on_hire_sort_property_changed(index: int) -> void:
	match index:
		0: hire_sort_property = "productivity"
		1: hire_sort_property = "day_rate"
		2: hire_sort_property = "productivity_per_day_rate"
		3: hire_sort_property = "type"
	_populate_hire_tab()

func _on_hire_high_low_button_pressed() -> void:
	hire_sort_descending = !hire_sort_descending
	hire_high_low_button.text = "High → Low" if hire_sort_descending else "Low → High"
	_populate_hire_tab()

# --- REFRESH COUNTER --- #

func _on_minute_passed(_in_game_minutes: int) -> void:
	_update_refresh_countdown()

func _update_refresh_countdown() -> void:
	var minutes_today: int = TimeManager.in_game_minutes
	var minutes_left: int = 1440 - minutes_today
	var hours: int = minutes_left / 60
	var minutes: int = minutes_left % 60
	refresh_countdown_label.text = "Next refresh in %02d:%02d" % [hours, minutes]



func _on_work_force_button_pressed() -> void:
	WindowManager.launch_app_by_name("WorkForce")


func _on_grinderr_button_pressed() -> void:
	WindowManager.launch_app_by_name("Grinderr")
