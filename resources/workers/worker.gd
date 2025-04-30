class_name Worker
extends Resource

@export var name: String
@export var is_contractor: bool
@export var hours_per_day: int = 8
@export var work_start_hour: int = 9  # 24hr format
@export var day_rate: int = 100
@export var sign_on_bonus: int = 0

@export var productivity_per_tick: float = 0.0

var assigned_task: WorkerTask = null
var last_assigned_task: WorkerTask = null
var specializations: Dictionary = {}  # e.g., { "gig_x": 0.12, "app_y": 0.08 }

var active: bool = false  # True only during paid working hours and while assigned
var unpaid: bool = false

# --- Update Active Status (called from WorkerManager) ---
func update_active_status(current_tick_of_day: int, tick_interval: float, can_be_paid: bool) -> void:
	unpaid = not can_be_paid

	if can_be_paid and assigned_task != null:
		active = true
	else:
		active = false

	var ticks_per_hour := 3600.0 / tick_interval
	var start_tick := int(work_start_hour * ticks_per_hour)
	var end_tick := int((work_start_hour + hours_per_day) * ticks_per_hour)

	active = (
		assigned_task != null and
		#current_tick_of_day >= start_tick and
		#current_tick_of_day < end_tick and
		can_be_paid
	)

# --- Stat Getters --- #

func get_day_rate() -> float:
	print("day rate: " + str(EffectManager.get_final_value("worker_day_rate", day_rate)))
	return EffectManager.get_final_value("worker_day_rate", day_rate)
	









# --- State Check ---
func is_idle() -> bool:
	return assigned_task == null

# --- Productivity Output ---
func apply_productivity() -> void:
	if not active or assigned_task == null:
		return
	var final_productivity = EffectManager.get_final_value("worker_productivity_per_tick", productivity_per_tick)
	var output = final_productivity * (1.0 + get_specialization_bonus())
	assigned_task.apply_productivity(output)


func get_specialization_bonus() -> float:
	if assigned_task == null:
		return 0.0
	var id := assigned_task.get_specialization_id()
	return specializations.get(id, 0.0)
