extends Node
# Autoload name: TaskManager

signal assignment_target_changed(new_target: WorkerTask)

@export var base_tasks: Array[WorkerTask] = []

# Tasks are grouped by category (e.g. "grinderr", "contracting", etc.)
var task_pools: Dictionary = {}  # category -> Array[WorkerTask]
var active_assignment_target: WorkerTask = null
var selected_task: WorkerTask = null # this might be a clearer name for active_assignment_target
#signal selected_task_changed(new_task: WorkerTask)

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

func unregister_task(category: String, task: WorkerTask) -> void:
	if task_pools.has(category):
		task_pools[category].erase(task)

func generate_random_tasks(category: String, count: int) -> Array[WorkerTask]:
	var filtered := base_tasks.filter(func(t): return t.show_in_grinderr and category == "grinderr")
	filtered.shuffle()

	var selected: Array[WorkerTask] = []
	for i in min(count, filtered.size()):
		var task = filtered[i].duplicate(true)
		register_task(category, task)
		selected.append(task)
	return selected


func remove_task(category: String, task: WorkerTask) -> void:
	if task_pools.has(category):
		task_pools[category].erase(task)


func set_assignment_target(target: WorkerTask) -> void:
	active_assignment_target = target
	emit_signal("assignment_target_changed", active_assignment_target)

func find_task_by_title(category: String, title: String) -> WorkerTask:
	var tasks = get_tasks(category)
	for task in tasks:
		if task.title == title:
			return task
	return null


# --- Save/Load  ---
func get_save_data() -> Dictionary:
	var data: Dictionary = {}
	for category in task_pools.keys():
		var task_list := []
		for task: WorkerTask in task_pools[category]:
			task_list.append({
				"title": task.title,
				"current_productivity": task.current_productivity,
				"completion_limit": task.completion_limit,
				"productivity_required": task.productivity_required,
				"assigned_worker_ids": task.get_assigned_worker_ids(),
				"payout_amount": task.payout_amount,
				"payout_type": task.payout_type,
				"completions_done": task.completions_done,
				"show_in_grinderr": task.show_in_grinderr,
			})
		data[category] = task_list
	return data

func load_from_data(data: Dictionary) -> void:
	task_pools.clear()

	var deferred_assignments: Array = []  # 🧠 Store worker-task pairs to assign later

	for category in data.keys():
		task_pools[category] = []
		for entry in data[category]:
			var task := WorkerTask.new()
			task.title = entry.get("title", "")
			task.current_productivity = entry.get("current_productivity", 0.0)
			task.completion_limit = entry.get("completion_limit", -1)
			task.productivity_required = entry.get("productivity_required", 1.0)
			task.payout_amount = entry.get("payout_amount", 0.0)
			task.payout_type = entry.get("payout_type", "cash")
			task.completions_done = entry.get("completions_done", 0)
			task.show_in_grinderr = entry.get("show_in_grinderr", false)

			if entry.has("assigned_worker_ids"):
				var ids = entry["assigned_worker_ids"]
				for id in ids:
					deferred_assignments.append([id, task])

			task_pools[category].append(task)

	# Perform deferred assignments safely
	for pair in deferred_assignments:
		var id = pair[0]
		var task = pair[1]
		var worker = WorkerManager.get_worker_by_id(id)
		if worker:
			call_deferred("_deferred_assign_worker", worker, task)



func _deferred_assign_worker(worker: Worker, task: WorkerTask) -> void:
	if worker and task:
		WorkerManager.assign_worker(worker, task)
		



func clear_tasks(category: String) -> void:
	task_pools[category] = []

func reset() -> void:
	task_pools.clear()
