extends Node
# Autoload name: TaskManager

signal assignment_target_changed(new_target)

# Tasks are grouped by category (e.g. "grinderr", "contracting", etc.)
var task_pools: Dictionary = {}  # category -> Array[WorkerTask]
var active_assignment_target: Node = null


func register_task(category: String, task: WorkerTask) -> void:
	if not task_pools.has(category):
		task_pools[category] = []
	if not task_pools[category].has(task):
		task_pools[category].append(task)

func get_tasks(category: String) -> Array[WorkerTask]:
	var tasks: Array[WorkerTask] = []
	if task_pools.has(category):
		for task in task_pools[category]:
			tasks.append(task)
	return tasks


func remove_task(category: String, task: WorkerTask) -> void:
	if task_pools.has(category):
		task_pools[category].erase(task)


func set_assignment_target(target: Node):
	active_assignment_target = target
	emit_signal("assignment_target_changed", target)

# --- Save/Load Support ---
func get_save_data() -> Dictionary:
	var data: Dictionary = {}
	for category in task_pools.keys():
		var task_list := []
		for task: WorkerTask in task_pools[category]:
			task_list.append({
				"title": task.title,
				"progress": task.progress,
				"completion_limit": task.completion_limit,
				"assigned_worker_id": task.assigned_worker_id if "assigned_worker_id" in task else null,
				"payout": task.payout_amount,
				"payout_type": task.payout_type,
				"completed_units": task.completed_units,
				"show_in_grinderr": task.show_in_grinderr,
			})
		data[category] = task_list
	return data

func load_from_data(data: Dictionary) -> void:
	task_pools.clear()
	for category in data.keys():
		task_pools[category] = []
		for entry in data[category]:
			var task := WorkerTask.new()
			task.title = entry.get("title", "")
			task.progress = entry.get("progress", 0.0)
			task.completion_limit = entry.get("completion_limit", -1)
			task.payout = entry.get("payout_amount", 0.0)
			task.payout_type = entry.get("payout_type", "cash")
			task.completed_units = entry.get("completed_units", 0)
			task.show_in_grinderr = entry.get("show_in_grinderr", false)
			if entry.has("assigned_worker_id"):
				task.assigned_worker_id = entry["assigned_worker_id"]
			task_pools[category].append(task)


func clear_tasks(category: String) -> void:
	task_pools[category] = []

func reset() -> void:
	task_pools.clear()
