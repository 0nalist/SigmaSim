extends HBoxContainer
class_name WorkerCard

signal action_pressed(worker: Worker)

@export var show_cost: bool = false
@export var button_label: String = "Select"

var worker: Worker

@onready var name_label: Label = %NameLabel
@onready var type_label: Label = %TypeLabel
@onready var prod_label: Label = %ProdLabel
@onready var status_label: Label = %StatusLabel
@onready var cost_label: Label = %CostLabel
@onready var action_button: Button = %ActionButton
@onready var portrait: TextureRect = %Portrait

func setup(worker_ref: Worker) -> void:
	if not is_inside_tree():
		await ready
	
	worker = worker_ref
	print("worker: " + str(worker))
	name_label.text = worker.name

	if worker.is_contractor:
		type_label.text = "Contractor"
	else:
		type_label.text = "Employee"

	if worker.is_idle():
		status_label.text = "Idle"
	else:
		status_label.text = "Assigned"

	prod_label.text = "Prod/tick: %.2f" % worker.productivity_per_tick

	if show_cost:
		cost_label.visible = true
		cost_label.text = "$%d + $%d" % [worker.sign_on_bonus, worker.day_rate]
	else:
		cost_label.visible = false

	# Placeholder portrait
	portrait.texture = preload("res://assets/worker.png")

	action_button.text = button_label
	action_button.pressed.connect(func():
		emit_signal("action_pressed", worker)
	)
