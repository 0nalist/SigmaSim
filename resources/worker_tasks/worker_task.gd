class_name WorkerTask
extends Resource

signal productivity_applied(amount: float, new_total: float)
signal task_updated()


@export var title: String
@export var unit_name: String

@export var productivity_required: float
@export var show_in_grinderr: bool = false
@export var payout_type: String = "cash"  # "cash", "reputation", "product"
@export var payout_amount: float = 0.0
@export var completion_limit: int = -1
@export var current_productivity: float = 0.0

var assigned_workers: Array[Worker] = []
var completions_done: int = 0

func apply_productivity(amount: float) -> void:
	print("🛠 Task.apply_productivity called with:", amount)

	current_productivity += amount
	print("📊 New productivity total:", current_productivity, "/", productivity_required)

	emit_signal("productivity_applied", amount, current_productivity)
	if productivity_required <= 0.0:
		push_error("❌ Task has invalid productivity_required = 0.0. Skipping completion loop.")
		return
	while current_productivity >= productivity_required and not is_complete():
		current_productivity -= productivity_required
		completions_done += 1
		print("✅ Completion added. New count:", completions_done)
		_on_task_completed()

	emit_signal("task_updated")


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

func get_assigned_worker_ids() -> Array[String]:
	var ids: Array[String] = []
	for worker in assigned_workers:
		ids.append(worker.id) # Assuming each Worker has a unique `id` string
	return ids
