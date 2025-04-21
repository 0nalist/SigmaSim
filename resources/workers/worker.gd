class_name Worker
extends Resource

@export var name: String
@export var contractor: bool
@export var hours_per_day: int
@export var productivity_per_hour: float
@export var day_rate: int
@export var sign_on_bonus: int

# Tick system
@export var productivity_per_tick: float
var assigned_task: WorkerTask = null
var specializations: Dictionary = {}  # e.g., { "gig_nice_beat_bro": 0.12, "app_grinderr": 0.08 }

# Utility
func is_idle() -> bool:
	return assigned_task == null

func apply_productivity():
	if assigned_task != null:
		var multiplier := 1.0 + get_specialization_bonus()
		assigned_task.apply_productivity(productivity_per_tick * multiplier)

func get_specialization_bonus() -> float:
	var id := assigned_task.get_specialization_id()
	return specializations.get(id, 0.0)
