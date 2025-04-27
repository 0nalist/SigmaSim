extends Pane
class_name Grinderr

@export var gig_popup_scene: PackedScene

@onready var tab_container: TabContainer = %TabContainer
@onready var hire_list: VBoxContainer = %HireList
@onready var refresh_countdown_label: Label = %RefreshCountdownLabel

var sort_property: String = "payout_amount"
var sort_descending := true
@onready var high_low_button: Button = %HighLowButton
@onready var sort_dropdown: OptionButton = %SortDropdown


var hire_sort_property: String = "productivity"
var hire_sort_descending := true
@onready var hire_sort_dropdown: OptionButton = %HireSortDropdown
@onready var hire_high_low_button: Button = %HireHighLowButton




func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	WorkerManager.available_workers_updated.connect(_populate_hire_tab)

	#high_low_button.pressed.connect(_on_high_low_button_pressed) #already connected via editor
	sort_dropdown.item_selected.connect(_on_sort_property_changed)
	
	_update_refresh_countdown()
	#app_title = "Grinderr"
	#emit_signal("title_updated", app_title)
	
	_init_dropdown()
	
	_load_or_initialize_gigs()
	_populate_hire_tab()
	_populate_work_tab()
	sort_gigs_by("payout_amount", true)

# --- HIRE TAB --- #

func _populate_hire_tab() -> void:
	for child in hire_list.get_children():
		child.queue_free()
		
	var sorted_workers = sort_workers_by(hire_sort_property, hire_sort_descending)
	
	for worker in sorted_workers:
		var row := _create_hire_row(worker)
		hire_list.add_child(row)

func _create_hire_row(worker: Worker) -> Control:
	var card = preload("res://components/ui/worker_card/worker_card_redux.tscn").instantiate()
	card.show_cost = true
	card.show_status = false
	card.button_label = "Hire"
	card.setup(worker)
	card.action_pressed.connect(func(w):
		var cost = w.sign_on_bonus + w.day_rate
		if PortfolioManager.attempt_spend(cost):
			WorkerManager.hire_worker(w)
			WorkerManager.available_workers.erase(w)
			_populate_hire_tab()
		else:
			print("Not enough funds!")
	)
	return card

# --- WORK TAB --- #

func _load_or_initialize_gigs() -> void:
	var existing_gigs = TaskManager.get_tasks("grinderr")

	if existing_gigs.is_empty():
		var dir := DirAccess.open("res://resources/worker_tasks/grinderr_gigs/")
		if dir == null:
			printerr("Could not open gig directory.")
			return

		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://resources/worker_tasks/grinderr_gigs/" + file_name
				var base_task: WorkerTask = load(path)
				var task := base_task.duplicate(true)
				if task is WorkerTask and task.show_in_grinderr and task.payout_type == "cash":
					TaskManager.register_task("grinderr", task)
			file_name = dir.get_next()
		dir.list_dir_end()

func _populate_work_tab() -> void:
	for child in %GigList.get_children():
		child.queue_free()

	var sorted_gigs = sort_gigs_by(sort_property, sort_descending)
	for gig in sorted_gigs:
		var card = _create_gig_card(gig)
		%GigList.add_child(card)
		card.setup(gig)

func _create_gig_card(gig: WorkerTask) -> Control:
	var card = preload("res://components/ui/gig_card/gig_card.tscn").instantiate()
	card.open_gig.connect(_on_open_gig)
	return card

func _on_open_gig(gig: WorkerTask) -> void:
	var popup = gig_popup_scene.instantiate()
	WindowManager.launch_popup(popup, gig.title)
	popup.setup(gig)


func sort_gigs_by(property: String, descending := true) -> Array[WorkerTask]:
	var gigs = TaskManager.get_tasks("grinderr")
	print("📊 Sorting grinderr gigs by:", property)

	gigs.sort_custom(func(a: WorkerTask, b: WorkerTask) -> bool:
		var a_value = get_sort_value(a, property)
		var b_value = get_sort_value(b, property)

		return a_value > b_value if descending else a_value < b_value
	)

	return gigs

func get_sort_value(task: WorkerTask, property: String) -> float:
	match property:
		"payout_amount": return task.payout_amount
		"productivity_required": return task.productivity_required
		"current_productivity": return task.current_productivity
		"payout_per_productivity":
			return task.payout_amount / max(task.productivity_required, 0.01)
		_: return 0.0


func _init_dropdown():
	
	# WORK sortby init
	%SortDropdown.add_item("Payout Amount", 0)
	%SortDropdown.add_item("Productivity Required", 1)
	%SortDropdown.add_item("Current Productivity", 2)
	%SortDropdown.add_item("Payout / Productivity", 3)
	var popup = %SortDropdown.get_popup()
	popup.add_theme_font_size_override("font_size", 12)
	
	
	# HIRE sortby init
	hire_sort_dropdown.add_item("Productivity", 0)
	hire_sort_dropdown.add_item("Day Rate", 1)
	hire_sort_dropdown.add_item("Productivity / Day Rate", 2)
	hire_sort_dropdown.add_item("Type (Employee/Contractor)", 3)

	var hire_popup = hire_sort_dropdown.get_popup()
	hire_popup.add_theme_font_size_override("font_size", 12)


func _on_sort_property_changed(index: int) -> void:
	match index:
		0: sort_property = "payout_amount"
		1: sort_property = "productivity_required"
		2: sort_property = "current_productivity"
		3: sort_property = "payout_per_productivity"
	_populate_work_tab()

func _on_hire_sort_property_changed(index: int) -> void:
	match index:
		0: hire_sort_property = "productivity"
		1: hire_sort_property = "day_rate"
		2: hire_sort_property = "productivity_per_day_rate"
		3: hire_sort_property = "type"
	_populate_hire_tab()

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
		"day_rate": return worker.day_rate
		"productivity_per_day_rate": return worker.productivity_per_tick / max(worker.day_rate, 0.01)
		"type": return 0.0 if worker.is_contractor else 1.0  # Contractors first if ascending
		_: return 0.0


# --- UTILITY --- #

func _on_minute_passed(_in_game_minutes: int) -> void:
	_update_refresh_countdown()

func _update_refresh_countdown() -> void:
	var minutes_today := TimeManager.in_game_minutes
	var minutes_left := 1440 - minutes_today
	var hours := minutes_left / 60
	var minutes := minutes_left % 60
	refresh_countdown_label.text = "Next refresh in %02d:%02d" % [hours, minutes]


func _on_high_low_button_pressed() -> void:
	sort_descending = !sort_descending
	high_low_button.text = "High → Low" if sort_descending else "Low → High"
	_populate_work_tab()


func _on_hire_high_low_button_pressed() -> void:
	hire_sort_descending = !hire_sort_descending
	hire_high_low_button.text = "High → Low" if hire_sort_descending else "Low → High"
	_populate_hire_tab()
