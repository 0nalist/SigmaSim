class_name WorkerTask
extends Resource

signal productivity_applied(amount: float, new_total: float)


@export var title: String
@export var productivity_required: float
@export var show_in_grinderr: bool = false
@export var payout_type: String = "cash"  # "cash", "reputation", "product"
@export var payout_amount: float = 0.0
@export var completion_limit: int = -1
@export var current_productivity: float = 0.0

var assigned_workers: Array[Worker] = []
var completions_done: int = 0

func apply_productivity(amount: float) -> void:
	current_productivity += amount
	emit_signal("productivity_applied", amount, current_productivity)
	print("productivity applied: " + str(amount))
	while current_productivity >= productivity_required and not is_complete():
		current_productivity -= productivity_required
		completions_done += 1
		_on_task_completed()


func _on_task_completed():
	match payout_type:
		"cash":
			PortfolioManager.add_cash(payout_amount)
		"reputation":
			# Later: increase influence with a faction
			pass
		"product":
			# Later: produce inventory for a startup
			pass

func is_complete() -> bool:
	return completion_limit > 0 and completions_done >= completion_limit

func get_specialization_id() -> String:
	return "task_" + title.replace(" ", "_").to_lower()

func get_progress_percent() -> float:
	return clamp(current_productivity / productivity_required, 0.0, 1.0)
