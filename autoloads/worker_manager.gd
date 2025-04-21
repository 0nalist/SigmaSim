#autoload name WorkerManager
extends Node

signal worker_tick
signal worker_hired(worker: Worker)
signal worker_assigned(worker: Worker, task: WorkerTask)
signal worker_deactivated(worker: Worker)
signal worker_idle(worker: Worker)
signal worker_selected(worker: Worker)


const TICK_INTERVAL := 1  # seconds
const TICKS_PER_DAY := int(1440 / TICK_INTERVAL)

var workers: Array[Worker] = []
var currently_selected_worker: Worker = null

var available_workers: Array[Worker] = []

func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.day_passed.connect(_on_day_passed)
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
	worker.assigned_task = task
	worker.active = true

	# Set work_start_hour to current time (rounded to the hour)
	var in_game_hour := int(TimeManager.in_game_minutes / 60)
	worker.work_start_hour = in_game_hour

	emit_signal("worker_assigned", worker, task)

func unassign_worker(worker: Worker) -> void:
	worker.assigned_task = null
	emit_signal("worker_idle", worker)

# --- Core Tick Loop ---
func _process_tick() -> void:
	var current_tick = get_current_tick()
	for worker in workers:
		print(worker.name, "active:", worker.active, "assigned:", worker.assigned_task != null)
		var cost_per_tick := float(worker.day_rate) / TICKS_PER_DAY
		var can_be_paid := PortfolioManager.attempt_spend(cost_per_tick)

		worker.update_active_status(current_tick, TICK_INTERVAL, can_be_paid)

		if worker.active:
			print("worker.apply_productivity()")
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

func _generate_random_worker(is_contractor: bool) -> Worker:
	var worker := Worker.new()
	worker.name = "Worker %s" % ["A","B","C","D","E","F","G","H","I","J"].pick_random()
	worker.is_contractor = is_contractor
	worker.hours_per_day = randi_range(4, 10)
	worker.productivity_per_tick = randf_range(0.2, 1.0)
	worker.day_rate = randi_range(30, 120)
	if is_contractor:
		worker.sign_on_bonus = randi_range(0, 20)
	else:
		worker.sign_on_bonus = randi_range(50, 200)
	return worker
