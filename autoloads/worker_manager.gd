#autoload name WorkerManager
extends Node

signal worker_tick
signal worker_hired(worker: Worker)
signal worker_assigned(worker: Worker, task: WorkerTask)
signal worker_deactivated(worker: Worker)
signal worker_unpaid(worker: Worker)
signal worker_idle(worker: Worker)
signal worker_selected(worker: Worker)
signal available_workers_updated


const TICK_INTERVAL := 1  # seconds
const TICKS_PER_DAY := int(1440 / TICK_INTERVAL)

var workers: Array[Worker] = []
var currently_selected_worker: Worker = null

var available_workers: Array[Worker] = []

func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.day_passed.connect(_on_day_passed)
	await NameGenerator.ready
	generate_available_workers()

func _on_minute_passed(in_game_minutes: int) -> void:
	if in_game_minutes % TICK_INTERVAL != 0:
		return  

	emit_signal("worker_tick")
	_process_tick()


# Hiring and Assigning
func hire_worker(worker: Worker) -> void:
	workers.append(worker)
	emit_signal("worker_hired", worker)

func assign_worker(worker: Worker, task: WorkerTask) -> void:
	# --- New logic: Unassign from old task if necessary ---
	if worker.assigned_task and worker.assigned_task != task:
		# Remove worker from old task's assigned list
		worker.assigned_task.assigned_workers.erase(worker)

	worker.assigned_task = task
	worker.last_assigned_task = task
	worker.active = true

	# Make sure worker is listed in the new task's assigned_workers
	if not task.assigned_workers.has(worker):
		task.assigned_workers.append(worker)

	# Set work_start_hour to current time (rounded to the hour)
	var in_game_hour := int(TimeManager.in_game_minutes / 60)
	worker.work_start_hour = in_game_hour

	emit_signal("worker_assigned", worker, task)
	task.emit_signal("task_updated")

func unassign_worker(worker: Worker) -> void:
	var task := worker.assigned_task
	worker.assigned_task = null
	emit_signal("worker_idle", worker)

	if task and task.assigned_workers.has(worker):
		task.assigned_workers.erase(worker)
		task.emit_signal("task_updated")

# --- Core Tick Loop ---
func _process_tick() -> void:
	var current_tick = get_current_tick()

	for worker in workers:
		var cost_per_tick: float = float(worker.day_rate) / TICKS_PER_DAY
		var can_be_paid: bool = PortfolioManager.attempt_spend(cost_per_tick)

		# Track payment status
		if not can_be_paid:
			if not worker.unpaid:
				worker.unpaid = true
				worker.active = false
				emit_signal("worker_unpaid", worker)
		else:
			if worker.unpaid:
				worker.unpaid = false
				# Resume if there was a previously assigned task
				if worker.last_assigned_task != null:
					assign_worker(worker, worker.last_assigned_task)

		# Update activity status
		worker.update_active_status(current_tick, TICK_INTERVAL, can_be_paid)

		# Do work or idle behavior
		if worker.active:
			worker.apply_productivity()
			_gain_specialization(worker)
		elif not can_be_paid:
			emit_signal("worker_deactivated", worker)
		else:
			_handle_idle_decay(worker)
	

func get_current_tick() -> int:
	return int(TimeManager.in_game_minutes * 60 / TICK_INTERVAL) % TICKS_PER_DAY

# --- Specialization Logic ---

func _gain_specialization(worker: Worker) -> void:
	if worker.assigned_task == null:
		return
	var id := worker.assigned_task.get_specialization_id()
	var current = worker.specializations.get(id, 0.0)
	worker.specializations[id] = clamp(current + 0.0005, 0.0, 1.0)  # Tune curve

func _handle_idle_decay(worker: Worker) -> void:
	for key in worker.specializations.keys():
		worker.specializations[key] = max(0.0, worker.specializations[key] - 0.0002)


## Worker generation ---

func _on_day_passed(_day, _month, _year):
	generate_available_workers()

func generate_available_workers() -> void:
	available_workers.clear()
	for i in 5:
		available_workers.append(_generate_random_worker(true))  # Contractor
		available_workers.append(_generate_random_worker(false))  # Employee
	emit_signal("available_workers_updated")

func _generate_random_worker(is_contractor: bool) -> Worker:
	var worker = Worker.new()
	
	''' Gender generator
	var fem = randi_range(0, 1)
	var masc = randi_range(0, 1)
	var andro = randi_range(0, 1) if randi_range(0, 1) == 1 else 0

	worker.name = NameGenerator.get_random_name(fem, masc, andro)
	'''
	worker.name = NameGenerator.get_random_name()
	worker.is_contractor = is_contractor
	worker.hours_per_day = randi_range(4, 10)
	worker.productivity_per_tick = randf_range(0.2, 1.0)
	worker.day_rate = randi_range(30, 120)
	if is_contractor:
		worker.sign_on_bonus = randi_range(0, 20)
	else:
		worker.sign_on_bonus = randi_range(50, 200)
	return worker



## -- SAVE LOAD --- ##

func get_save_data() -> Dictionary:
	var out := {
		"workers": [],
	}
	for w in workers:
		out["workers"].append(w.get_save_data())
	return out



func load_from_data(data: Dictionary) -> void:
	workers.clear()
	if not data.has("workers") or typeof(data["workers"]) != TYPE_ARRAY:
		push_error("WorkerManager.load_from_data expected 'workers' as Array.")
		return

	for worker_dict in data["workers"]:
		var worker := Worker.new()
		worker.load_from_data(worker_dict)
		workers.append(worker)

		var last_title = worker_dict.get("last_assigned_task_title", "")
		if last_title != "":
			var task = TaskManager.find_task_by_title("grinderr", last_title)
			if task:
				worker.assigned_task = task
				task.assigned_workers.append(worker)
