class_name SuitorLogic
extends Node

var npc: NPC
var progress_paused: bool = false

const STAGE_THRESHOLDS: Array[float] = [0.0, 0.0, 100.0, 1000.0, 10000.0, 100000.0]
const LN10: float = 2.302585092994046  # natural log of 10
const LOVE_AFFINITY_GAIN: float = 5.0

static func get_stage_bounds(stage: int, progress: float) -> Vector2:
	if stage < NPC.RelationshipStage.MARRIED:
		var lower: float = STAGE_THRESHOLDS[stage]
		var upper: float = STAGE_THRESHOLDS[stage + 1]
		return Vector2(lower, upper)
	var level: int = int(floor(log(progress) / LN10 - 4.0))
	if level < 1:
		level = 1
	var lower: float = pow(10.0, float(level + 4))
	var upper: float = pow(10.0, float(level + 5))
	return Vector2(lower, upper)

static func get_marriage_level(progress: float) -> int:
	if progress < 100000.0:
		return 1
	var level: int = int(floor(log(progress) / LN10 - 4.0))
	if level < 1:
		level = 1
	return level

func setup(npc_instance: NPC) -> void:
	npc = npc_instance
	progress_paused = false

func process(delta: float) -> void:
	if npc == null or progress_paused or npc.relationship_stage >= NPC.RelationshipStage.DIVORCED:
		return
	var bounds: Vector2 = get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	var rate: float = max(npc.affinity, 0.0) * 0.1
	npc.relationship_progress += rate * delta
	apply_stop_points()
	if npc.relationship_stage < NPC.RelationshipStage.MARRIED and npc.relationship_progress >= bounds.y:
		npc.relationship_progress = bounds.y
		progress_paused = true

func apply_stop_points() -> void:
	var stage: int = npc.relationship_stage
	var bounds: Vector2 = get_stage_bounds(stage, npc.relationship_progress)
	var stage_range: float = bounds.y - bounds.x
	var stops: Array = get_stop_points(stage)
	var progress_fraction: float = (npc.relationship_progress - bounds.x) / stage_range
	for stop in stops:
		var fraction: float = stop["fraction"]
		var required: int = stop["required"]
		if progress_fraction >= fraction and npc.dates_paid < required:
			npc.relationship_progress = bounds.x + fraction * stage_range
			progress_paused = true
			break

func on_date_paid() -> void:
	npc.dates_paid += 1
	progress_paused = false

func apply_love() -> bool:
	# Love actions should build affinity rather than reduce it.
	# Increase affinity by a fixed amount, clamping at the maximum.
	npc.affinity = min(npc.affinity + LOVE_AFFINITY_GAIN, 100.0)
	var progress_increase: float = npc.relationship_progress * 0.01
	var bounds: Vector2 = get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	npc.relationship_progress = min(npc.relationship_progress + progress_increase, bounds.y)
	var reached_next_stage: bool = false
	if npc.relationship_stage < NPC.RelationshipStage.MARRIED and npc.relationship_progress >= bounds.y:
		progress_paused = true
		reached_next_stage = true
	return reached_next_stage

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
	if stage >= NPC.RelationshipStage.MARRIED:
		return []
	var points: Array = []
	var prev_required: int = (stage - 1) * stage / 2
	for i in range(1, stage + 1):
		var fraction: float = float(i) / float(stage + 1)
		var required: int = prev_required + i
		points.append({"fraction": fraction, "required": required})
	return points
