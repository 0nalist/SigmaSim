extends BaseAppUI
class_name WorkerForce

@onready var worker_list: VBoxContainer = %WorkerList
@onready var selected_name_label: Label = %SelectedNameLabel
@onready var selected_task_label: Label = %SelectedTaskLabel



func _ready() -> void:
	app_title = "WorkForce"
	_populate_worker_list()
	WorkerManager.worker_selected.connect(_on_worker_selected)
	WorkerManager.worker_hired.connect(_on_worker_hired)
	WorkerManager.worker_assigned.connect(_on_worker_assigned)
	WorkerManager.worker_idle.connect(_on_worker_idle)
	WorkerManager.worker_unpaid.connect(_on_worker_unpaid)
	TaskManager.assignment_target_changed.connect(_on_assignment_target_changed)

func _on_worker_hired(worker: Worker) -> void:
	# Optional: prevent duplicates if list isn’t cleared first
	if not WorkerManager.workers.has(worker):
		return

	# Option 1: Refresh whole list
	_populate_worker_list()

	# Option 2: Just add this one row
	# worker_list.add_child(_create_worker_card(worker))


func _populate_worker_list() -> void:
	for child in worker_list.get_children():
		child.queue_free()
	for worker in WorkerManager.workers:
		var card = _create_worker_card(worker)
		worker_list.add_child(card)
		card.call_deferred("setup", worker)

func _create_worker_card(worker: Worker) -> Control:
	var card = preload("res://components/ui/worker_card/worker_card.tscn").instantiate()
	card.show_cost = false
	card.button_label = "Select"
	card.setup(worker)

	# ✅ Disable the action button if no task is selected
	if card.has_node("%ActionButton"):
		card.get_node("%ActionButton").disabled = (TaskManager.active_assignment_target == null)

	card.action_pressed.connect(func(w):
		WorkerManager.currently_selected_worker = w
		WorkerManager.emit_signal("worker_selected", w)
	)

	return card


func _on_worker_selected(worker: Worker) -> void:
	selected_name_label.text = worker.name

func _on_worker_unpaid(worker: Worker) -> void:
	for card in worker_list.get_children():
		if card.worker == worker:
			card.update_status()


func _on_worker_idle(worker: Worker) -> void:
	_on_worker_updated(worker)

func _on_worker_assigned(worker: Worker, _task) -> void:
	_on_worker_updated(worker)

func _on_worker_updated(worker: Worker) -> void:
	# Find the matching card and update it
	for card in worker_list.get_children():
		#if card is WorkerCardRedux and card.worker == worker:
		if card.worker == worker:
			card.update_all()


func _on_assignment_target_changed(target: Node) -> void:
	if target == null:
		selected_task_label.text = "Selected Task: None"
	else:
		# If the target has a 'gig' or 'title' property, use that
		var task_title := "?"
		if "gig" in target and target.gig != null:
			task_title = target.gig.title
		elif "title" in target:
			task_title = target.title
		selected_task_label.text = "Selected Task: " + task_title

	# Disable or enable buttons on all WorkerCards
	for card in worker_list.get_children():
		if card.has_node("%ActionButton"):
			card.get_node("%ActionButton").disabled = (target == null)



func _on_grinderr_button_pressed() -> void:
	WindowManager.launch_app_by_name("Grinderr")
