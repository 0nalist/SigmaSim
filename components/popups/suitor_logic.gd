class_name SuitorLogic
extends RefCounted

var npc: NPC
var progress_paused: bool = false
var gift_cost: float = 25.0
var date_cost: float = 200.0
var breakup_reward: float = 0.0
var apologize_cost: int = 10
var next_stage_ready: bool = false

func setup(npc_ref: NPC) -> void:
	npc = npc_ref
	progress_paused = false
	gift_cost = 25.0
	date_cost = 200.0
	breakup_reward = 0.0
	apologize_cost = 10
	next_stage_ready = false

func process(delta: float) -> void:
	if npc == null or progress_paused or npc.relationship_stage >= NPC.RelationshipStage.DIVORCED:
		return
	var rate: float = max(npc.affinity, 0.0) * 0.1
	npc.relationship_progress += rate * delta
	_apply_progress_limits()

func _apply_progress_limits() -> void:
	var stage: int = npc.relationship_stage
	for stop_value in get_pending_stop_points():
		if npc.relationship_progress >= stop_value:
			npc.relationship_progress = stop_value
			progress_paused = true
			next_stage_ready = false
			return
	if npc.relationship_progress >= 100.0:
		npc.relationship_progress = 100.0
		progress_paused = true
		next_stage_ready = stage < NPC.RelationshipStage.MARRIED
		return
	progress_paused = false
	next_stage_ready = false

func get_pending_stop_points() -> Array[float]:
	var points: Array[float] = []
	var stage: int = npc.relationship_stage
	if stage <= 0 or stage >= NPC.RelationshipStage.MARRIED:
		return points
	var prev_total: int = stage * (stage - 1) / 2
	for i in range(1, stage + 1):
		var required: int = prev_total + i
		if npc.date_count < required:
			points.append(float(i) * 100.0 / float(stage + 1))
	return points

func handle_gift() -> bool:
	if PortfolioManager.attempt_spend(gift_cost):
		npc.affinity = min(npc.affinity + 5.0, 100.0)
		gift_cost *= 2.0
		return true
	return false

func handle_date() -> bool:
	if not PortfolioManager.attempt_spend(date_cost):
		return false
	npc.date_count += 1
	npc.relationship_progress = min(npc.relationship_progress + 25.0, 100.0)
	date_cost *= 2.0
	progress_paused = false
	_apply_progress_limits()
	return true

func advance_stage() -> void:
	next_stage_ready = false
	progress_paused = false
	if npc.relationship_stage < NPC.RelationshipStage.MARRIED:
		npc.relationship_stage += 1
		npc.relationship_progress = 0.0

func handle_apologize() -> bool:
	if npc == null:
		return false
	var current_ex: float = StatManager.get_stat("ex", 0.0)
	if current_ex < apologize_cost:
		return false
	StatManager.set_base_stat("ex", current_ex - apologize_cost)
	npc.relationship_stage = NPC.RelationshipStage.TALKING
	npc.relationship_progress = 0.0
	npc.affinity = 1.0
	progress_paused = false
	breakup_reward = 0.0
	apologize_cost = int(ceil(float(apologize_cost) * 1.5))
	next_stage_ready = false
	return true

func prepare_breakup_reward() -> float:
	var stage_idx: int = max(1, npc.relationship_stage)
	var base: float = pow(10.0, float(stage_idx - 1))
	breakup_reward = (0.1 + (npc.relationship_progress / 100.0) * 0.9) * base
	return breakup_reward

func confirm_breakup() -> void:
	var current_ex: float = StatManager.get_stat("ex", 0.0)
	StatManager.set_base_stat("ex", current_ex + breakup_reward)
	if npc.relationship_stage == NPC.RelationshipStage.MARRIED:
		npc.relationship_stage = NPC.RelationshipStage.DIVORCED
		PortfolioManager.halve_assets()
	else:
		npc.relationship_stage = NPC.RelationshipStage.EX
	npc.relationship_progress = 0.0
	npc.affinity *= 0.2
	progress_paused = true
	next_stage_ready = false
