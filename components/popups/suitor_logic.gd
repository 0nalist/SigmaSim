class_name SuitorLogic
extends Node

var npc: NPC
var progress_paused: bool = false
var state: SuitorState

const STAGE_THRESHOLDS: Array[float] = [0.0, 0.0, 100.0, 1000.0, 10000.0, 100000.0]
const LN10: float = 2.302585092994046  # natural log of 10
const DEFAULT_LOVE_AFFINITY_GAIN: float = 5.0

static func get_stage_bounds(stage: int, progress: float) -> Vector2:
	if stage < NPCManager.RelationshipStage.MARRIED:
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
	change_state(npc.relationship_stage)

func change_state(stage: int) -> void:
	if state != null:
		state.exit()
	match stage:
		NPCManager.RelationshipStage.STRANGER:
			state = StrangerState.new(self)
		NPCManager.RelationshipStage.TALKING:
			state = TalkingState.new(self)
		NPCManager.RelationshipStage.DATING:
			state = DatingState.new(self)
		NPCManager.RelationshipStage.SERIOUS:
			state = SeriousState.new(self)
		NPCManager.RelationshipStage.ENGAGED:
			state = EngagedState.new(self)
		NPCManager.RelationshipStage.MARRIED:
			state = MarriedState.new(self)
		NPCManager.RelationshipStage.DIVORCED:
			state = DivorcedState.new(self)
		NPCManager.RelationshipStage.EX:
			state = ExState.new(self)
	state.enter()

func process(delta: float) -> void:
	if npc == null or progress_paused:
		return
	if state != null:
		state.update(delta)


func on_date_paid() -> void:
		npc.date_count += 1
		progress_paused = false

func apply_love() -> void:
	var gain: float = StatManager.get_stat("love_affinity_gain", DEFAULT_LOVE_AFFINITY_GAIN)
	npc.affinity = min(npc.affinity + gain, 100.0)


func get_stop_marks() -> Array[float]:
	if state != null:
		return state.get_stop_marks()
	return []

static func get_stop_points(stage: int) -> Array:
	if stage >= NPCManager.RelationshipStage.MARRIED:
		return []
	var points: Array = []
	var prev_required: int = (stage - 1) * stage / 2
	for i in range(1, stage + 1):
		var fraction: float = float(i) / float(stage + 1)
		var required: int = prev_required + i
		points.append({"fraction": fraction, "required": required})
	return points

class SuitorState:
	var machine: SuitorLogic
	var npc: NPC

	func _init(machine: SuitorLogic) -> void:
		self.machine = machine
		npc = machine.npc

	func enter() -> void:
		pass

	func exit() -> void:
		pass

	func update(delta: float) -> void:
		pass

	func get_stop_marks() -> Array[float]:
		return []

class PreMarriageState extends SuitorState:
	var stage: int

	func _init(machine: SuitorLogic, stage_id: int) -> void:
		super._init(machine)
		stage = stage_id

	func update(delta: float) -> void:
		var bounds: Vector2 = SuitorLogic.get_stage_bounds(stage, npc.relationship_progress)
		var rate: float = max(npc.affinity, 0.0) * 0.1
		npc.relationship_progress += rate * delta
		var stage_range: float = bounds.y - bounds.x
		var stops: Array = SuitorLogic.get_stop_points(stage)
		var progress_fraction: float = 0.0
		if stage_range > 0.0:
			progress_fraction = (npc.relationship_progress - bounds.x) / stage_range
		for stop in stops:
			var fraction: float = stop["fraction"]
			var required: int = stop["required"]
			if progress_fraction >= fraction and npc.date_count < required:
				npc.relationship_progress = bounds.x + fraction * stage_range
				machine.progress_paused = true
				break
		if stage < NPCManager.RelationshipStage.MARRIED and npc.relationship_progress >= bounds.y:
			npc.relationship_progress = bounds.y
			machine.progress_paused = true

	func get_stop_marks() -> Array[float]:
		var marks: Array[float] = []
		var stops: Array = SuitorLogic.get_stop_points(stage)
		for stop in stops:
			var fraction: float = stop["fraction"]
			var required: int = stop["required"]
			if npc.date_count < required:
				marks.append(fraction)
		return marks

class StrangerState extends PreMarriageState:
	func _init(machine: SuitorLogic) -> void:
		super._init(machine, NPCManager.RelationshipStage.STRANGER)

class TalkingState extends PreMarriageState:
	func _init(machine: SuitorLogic) -> void:
		super._init(machine, NPCManager.RelationshipStage.TALKING)

class DatingState extends PreMarriageState:
	func _init(machine: SuitorLogic) -> void:
		super._init(machine, NPCManager.RelationshipStage.DATING)

class SeriousState extends PreMarriageState:
	func _init(machine: SuitorLogic) -> void:
		super._init(machine, NPCManager.RelationshipStage.SERIOUS)

class EngagedState extends PreMarriageState:
	func _init(machine: SuitorLogic) -> void:
		super._init(machine, NPCManager.RelationshipStage.ENGAGED)

class MarriedState extends SuitorState:
	func update(delta: float) -> void:
		var rate: float = max(npc.affinity, 0.0) * 0.1
		npc.relationship_progress += rate * delta

class DivorcedState extends SuitorState:
	pass

class ExState extends SuitorState:
	pass
