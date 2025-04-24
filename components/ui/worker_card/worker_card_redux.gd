extends PanelContainer
class_name WorkerCardRedux

signal action_pressed(worker: Worker)

@export var show_cost: bool = false
@export var show_status: bool = true
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
		
	status_label.visible = show_status
	worker = worker_ref
	name_label.text = worker.name

	if worker.is_contractor:
		type_label.text = "Contractor"
	else:
		type_label.text = "Employee"

	if worker.is_idle():
		status_label.text = "Idle"
	else:
		status_label.text = str(worker.assigned_task.title)

	prod_label.text = "Prod/tick: %.2f" % worker.productivity_per_tick

	if show_cost:
		cost_label.visible = true
		cost_label.text = "Acquisition Cost: $%d + $%d per day" % [worker.sign_on_bonus, worker.day_rate]

	else:
		cost_label.visible = false

	# Placeholder portrait
	#portrait.texture = preload("res://assets/prof_pics/worker.png")

	action_button.text = button_label
	action_button.pressed.connect(func():
		emit_signal("action_pressed", worker)
	)
	update_all()

func update_all() -> void:
	update_status()
	update_productivity()
	update_cost()

func update_status() -> void:
	if not show_status:
		return

	if worker.unpaid:
		status_label.text = "Unpaid"
		status_label.modulate = Color.RED
	elif worker.assigned_task != null:
		status_label.text = str(worker.assigned_task.title)
		status_label.modulate = Color.WHITE
	else:
		status_label.text = "Idle"
		status_label.modulate = Color.YELLOW


func update_productivity() -> void:
	prod_label.text = "Prod/tick: %.2f" % worker.productivity_per_tick

func update_cost() -> void:
	if show_cost:
		cost_label.visible = true
		cost_label.text = "Acquisition Cost: $%d + $%d per day" % [worker.sign_on_bonus, worker.day_rate]
	else:
		cost_label.visible = false
