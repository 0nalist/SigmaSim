#autoload name WorkerManager
extends Node

signal worker_tick
signal worker_hired(worker: Worker)
signal worker_assigned(worker: Worker, task: WorkerTask)
signal worker_deactivated(worker: Worker)
signal worker_idle(worker: Worker)
signal worker_selected(worker: Worker)


const TICK_INTERVAL := 10.0  # seconds
const TICKS_PER_DAY := int(1440 / TICK_INTERVAL)

var workers: Array[Worker] = []
var currently_selected_worker: Worker = null

func _ready() -> void:
	_start_tick_loop()

func _start_tick_loop() -> void:
	await get_tree().create_timer(TICK_INTERVAL).timeout
	emit_signal("worker_tick")
	_process_tick()
	_start_tick_loop()

# Hiring and Assigning
func hire_worker(worker: Worker) -> void:
	workers.append(worker)
	emit_signal("worker_hired", worker)

func assign_worker(worker: Worker, task: WorkerTask) -> void:
	worker.assigned_task = task
	worker.active = true
	emit_signal("worker_assigned", worker, task)

func unassign_worker(worker: Worker) -> void:
	worker.assigned_task = null
	emit_signal("worker_idle", worker)

# --- Core Tick Loop ---
func _process_tick() -> void:
	var current_tick = get_current_tick()
	for worker in workers:
		var cost_per_tick := float(worker.day_rate) / TICKS_PER_DAY
		var can_be_paid := PortfolioManager.attempt_spend(cost_per_tick)

		worker.update_active_status(current_tick, TICK_INTERVAL, can_be_paid)

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
