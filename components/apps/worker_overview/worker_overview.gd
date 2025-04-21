extends BaseAppUI
class_name WorkerOverviewUI

@onready var worker_list: VBoxContainer = %WorkerList
@onready var selected_name_label: Label = %SelectedNameLabel

func _ready() -> void:
	app_title = "Gruntwork"
	_populate_worker_list()
	WorkerManager.worker_selected.connect(_on_worker_selected)

func _populate_worker_list() -> void:
	worker_list.clear()
	for worker in WorkerManager.workers:
		var card = _create_worker_card(worker)
		worker_list.add_child(card)

func _create_worker_card(worker: Worker) -> Control:
	var card = HBoxContainer.new()

	var name_label = Label.new()
	name_label.text = worker.name
	card.add_child(name_label)

	var type_label = Label.new()
	if worker.contractor:
		type_label.text = "Contractor"
	else:
		type_label.text = "Employee"

	card.add_child(type_label)

	var status_label = Label.new()
	if worker.is_idle():
		status_label.text = "Idle"
	else:
		status_label.text = "Assigned"

	card.add_child(status_label)

	var assign_button = Button.new()
	assign_button.text = "Select"
	assign_button.pressed.connect(func():
		WorkerManager.currently_selected_worker = worker
		WorkerManager.emit_signal("worker_selected", worker)
	)
	card.add_child(assign_button)

	return card

func _on_worker_selected(worker: Worker) -> void:
	selected_name_label.text = worker.name
