extends BaseAppUI
class_name Grinderr

@export var gig_popup_scene: PackedScene

@onready var tab_container: TabContainer = %TabContainer
@onready var hire_list: VBoxContainer = %HireList
@onready var refresh_countdown_label: Label = %RefreshCountdownLabel

func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	WorkerManager.available_workers_updated.connect(_populate_hire_tab)

	_update_refresh_countdown()
	app_title = "Grinderr"
	emit_signal("title_updated", app_title)

	_load_or_initialize_gigs()
	_populate_hire_tab()
	_populate_work_tab()

# --- HIRE TAB --- #

func _populate_hire_tab() -> void:
	for child in hire_list.get_children():
		child.queue_free()

	for worker in WorkerManager.available_workers:
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

	var gigs = TaskManager.get_tasks("grinderr")
	for gig in gigs:
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

# --- UTILITY --- #

func _on_minute_passed(_in_game_minutes: int) -> void:
	_update_refresh_countdown()

func _update_refresh_countdown() -> void:
	var minutes_today := TimeManager.in_game_minutes
	var minutes_left := 1440 - minutes_today
	var hours := minutes_left / 60
	var minutes := minutes_left % 60
	refresh_countdown_label.text = "Next refresh in %02d:%02d" % [hours, minutes]
