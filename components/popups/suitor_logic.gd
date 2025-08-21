class_name SuitorLogic
extends Node

var npc: NPC
var progress_paused: bool = false

func setup(npc_instance: NPC) -> void:
	npc = npc_instance
	progress_paused = false

func process(delta: float) -> void:
	if npc == null or progress_paused or npc.relationship_stage >= NPC.RelationshipStage.DIVORCED:
		return
	var rate: float = max(npc.affinity, 0.0) * 0.1
	npc.relationship_progress += rate * delta
	apply_stop_points()
	if npc.relationship_progress >= 100.0:
		npc.relationship_progress = 100.0
		progress_paused = true

func apply_stop_points() -> void:
	var stage: int = npc.relationship_stage
	var stops: Array = get_stop_points(stage)
	var progress_fraction: float = npc.relationship_progress / 100.0
	for stop in stops:
		var fraction: float = stop["fraction"]
		var required: int = stop["required"]
		if progress_fraction >= fraction and npc.dates_paid < required:
		npc.relationship_progress = fraction * 100.0
		progress_paused = true
		break

func on_date_paid() -> void:
	npc.dates_paid += 1
	progress_paused = false

func get_stop_marks() -> Array[float]:
	var marks: Array[float] = []
	var stage: int = npc.relationship_stage
	var stops: Array = get_stop_points(stage)
	for stop in stops:
		var fraction: float = stop["fraction"]
		var required: int = stop["required"]
		if npc.dates_paid < required:
		marks.append(fraction)
	return marks

static func get_stop_points(stage: int) -> Array:
	var points: Array = []
	var prev_required: int = (stage - 1) * stage / 2
	for i in range(1, stage + 1):
		var fraction: float = float(i) / float(stage + 1)
		var required: int = prev_required + i
		points.append({"fraction": fraction, "required": required})
	return points
