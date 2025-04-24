extends BaseAppUI
class_name WorkerOverviewUI

@onready var worker_list: VBoxContainer = %WorkerList
@onready var selected_name_label: Label = %SelectedNameLabel

const WorkerCardScene := preload("res://components/ui/worker_card/worker_card_redux.tscn")
const Worker = preload("res://resources/workers/worker.gd")

func _ready() -> void:
	app_title = "WorkForce"
	_populate_worker_list()
	WorkerManager.worker_selected.connect(_on_worker_selected)
	WorkerManager.worker_hired.connect(_on_worker_hired)
	WorkerManager.worker_assigned.connect(_on_worker_assigned)
	WorkerManager.worker_idle.connect(_on_worker_idle)
	WorkerManager.worker_unpaid.connect(_on_worker_unpaid)

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
		var row := _create_worker_row(worker)
		worker_list.add_child(row)

func _create_worker_row(worker: Worker) -> Control:
	var card = WorkerCardScene.instantiate()
	print("Card type:", card.get_class())
	card.show_cost = true
	card.show_status = false
	card.button_label = "Hire"
	card.setup(worker)
	card.action_pressed.connect(func(w):
		WorkerManager.currently_selected_worker = w
		WorkerManager.emit_signal("worker_selected", w)
	)
	return card




func _create_worker_card(worker: Worker) -> Control:
	print("Instantiating card for", worker.name)
	var card = WorkerCardScene.instantiate()

	if card == null:
		push_error("❌ WorkerCardScene.instantiate() returned null!")
		return null  # ← NOT Control.new() — that hides the bug

	print("✅ Card instantiated:", card)
	return card

	
	card.show_cost = false
	card.button_label = "Select"
	#card.setup(worker)
	


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
		if card is WorkerCard and card.worker == worker:
			card.update_all()


func _on_grinderr_button_pressed() -> void:
	WindowManager.launch_app_by_name("Grinderr")
