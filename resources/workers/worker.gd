class_name Worker
extends Resource

@export var id: String = ""
@export var name: String
@export var is_contractor: bool
@export var hours_per_day: int = 8
@export var work_start_hour: int = 9  # 24hr format
@export var day_rate: int = 100
@export var sign_on_bonus: int = 0

@export var productivity_per_tick: float = 0.0

@export var hire_count: int = 0

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
	

func get_hire_cost() -> float:
	var base_cost = sign_on_bonus + day_rate
	var scaled_cost = base_cost * pow(1.25, WorkerManager.total_workers_hired)
	return EffectManager.get_final_value("worker_hire_cost", scaled_cost)








# --- State Check ---
func is_idle() -> bool:
	return assigned_task == null

# --- Productivity  ---
func apply_productivity() -> void:
	if not active:
		print("⏩ Skipping productivity: not active")
		return
	
	if assigned_task == null:
		push_error("❌ Worker has null assigned_task during apply_productivity: " + name)
		return

	if not is_instance_valid(assigned_task):
		push_error("❌ assigned_task is not a valid instance for: " + name)
		return

	var final_productivity = EffectManager.get_final_value("worker_productivity_per_tick", productivity_per_tick)
	var output = final_productivity * (1.0 + get_specialization_bonus())

	#print("👷", name, "applying", output, "to", assigned_task.title)

	# Final check before call
	if assigned_task.has_method("apply_productivity"):
		assigned_task.apply_productivity(output)
	else:
		push_error("❌ assigned_task missing apply_productivity method!")


func get_specialization_bonus() -> float:
	if assigned_task == null:
		return 0.0
	var id := assigned_task.get_specialization_id()
	return specializations.get(id, 0.0)




## --- Save Load --- ##

func get_save_data() -> Dictionary:
	var last_title := ""
	if last_assigned_task != null:
		last_title = last_assigned_task.title

	return {
		"name": name,
		"id": id,
		"is_contractor": is_contractor,
		"hours_per_day": hours_per_day,
		"work_start_hour": work_start_hour,
		"day_rate": day_rate,
		"sign_on_bonus": sign_on_bonus,
		"productivity_per_tick": productivity_per_tick,
		"unpaid": unpaid,
		"active": active,
		"specializations": specializations,
		"last_assigned_task_title": last_title
	}


func load_from_data(data: Dictionary) -> void:
	name = data.get("name", "")
	id = data.get("id", "")
	is_contractor = data.get("is_contractor", false)
	hours_per_day = data.get("hours_per_day", 8)
	work_start_hour = data.get("work_start_hour", 9)
	day_rate = data.get("day_rate", 100)
	sign_on_bonus = data.get("sign_on_bonus", 0)
	productivity_per_tick = data.get("productivity_per_tick", 0.0)
	unpaid = data.get("unpaid", false)
	active = data.get("active", false)
	specializations = data.get("specializations", {})

	var last_title = data.get("last_assigned_task_title", "")
	if last_title != "":
		last_assigned_task = TaskManager.find_task_by_title("grinderr", last_title)
