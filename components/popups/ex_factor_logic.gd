class_name ExFactorLogic
extends Node

signal progress_changed(new_progress: float)
signal stage_gate_reached()
signal stage_changed(new_stage: int)
signal affinity_changed(new_affinity: float)
signal equilibrium_changed(new_equilibrium: float)
signal costs_changed(gift_cost: float, date_cost: float)
signal cooldown_changed(ready_at_minutes: int)
signal exclusivity_changed(new_core: int)
signal blocked_state_changed(is_blocked: bool)
signal request_persist(fields: Dictionary)
signal notify(text: String)

var npc: NPC
var progress_paused: bool = false
var state: SuitorState

var npc_idx: int = -1

const STAGE_THRESHOLDS: Array[float] = [0.0, 0.0, 100.0, 1000.0, 10000.0, 100000.0]
const LN10: float = 2.302585092994046
const DEFAULT_LOVE_AFFINITY_GAIN: float = 5.0
const LOVE_COOLDOWN_MINUTES: int = 24 * 60
const APOLOGIZE_COST: int = 10

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

func get_stop_marks() -> Array[float]:
	if state != null:
		return state.get_stop_marks()
	return []

func setup(npc_instance: NPC, npc_index: int) -> void:
	npc = npc_instance
	npc_idx = npc_index
	progress_paused = false
	_recalc_costs()
	change_state(npc.relationship_stage)
	_emit_blocked()

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
	emit_signal("stage_changed", npc.relationship_stage)
	_emit_blocked()

func process(delta: float) -> void:
	if npc == null:
		return
	if progress_paused:
		return
	if state != null:
		var before: float = npc.relationship_progress
		state.update(delta)
		if npc.relationship_progress != before:
			emit_signal("progress_changed", npc.relationship_progress)
			emit_signal("request_persist", {"relationship_progress": npc.relationship_progress})

# ---------------------------- User actions ----------------------------

func try_gift() -> bool:
	if npc == null:
		return false
	var ok: bool = PortfolioManager.attempt_spend(npc.gift_cost, PortfolioManager.CREDIT_REQUIREMENTS["gift"])
	if not ok:
		return false
	npc.affinity = min(npc.affinity + 5.0, 100.0)
	npc.gift_count += 1
	_recalc_costs()
	emit_signal("affinity_changed", npc.affinity)
	emit_signal("costs_changed", npc.gift_cost, npc.date_cost)
	emit_signal("request_persist", {"affinity": npc.affinity, "gift_count": npc.gift_count})
	return true

func try_date() -> bool:
	if npc == null:
		return false
	var ok: bool = PortfolioManager.attempt_spend(npc.date_cost, PortfolioManager.CREDIT_REQUIREMENTS["date"])
	if not ok:
		return false
	npc.date_count += 1
	_recalc_costs()

	# Progress bump from paying for date (kept same formula).
	var bounds: Vector2 = ExFactorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	var boost: float = npc.date_cost / 10.0
	npc.relationship_progress = min(npc.relationship_progress + boost, bounds.y)

	emit_signal("costs_changed", npc.gift_cost, npc.date_cost)
	emit_signal("progress_changed", npc.relationship_progress)
	emit_signal("request_persist", {
		"relationship_progress": npc.relationship_progress,
		"date_count": npc.date_count
	})

	# Let state machine enforce gates.
	if npc.relationship_stage < NPCManager.RelationshipStage.MARRIED and npc.relationship_progress >= bounds.y:
		progress_paused = true
		emit_signal("stage_gate_reached")

	return true

func can_love(now_minutes: int) -> bool:
	if npc == null:
		return false
	if npc.relationship_stage < NPCManager.RelationshipStage.DATING:
		return false
	return now_minutes >= npc.love_cooldown

func apply_love(now_minutes: int) -> void:
	if npc == null:
		return
	if not can_love(now_minutes):
		return
	npc.love_cooldown = now_minutes + LOVE_COOLDOWN_MINUTES
	var gain: float = StatManager.get_stat("love_affinity_gain", DEFAULT_LOVE_AFFINITY_GAIN)
	npc.affinity = min(npc.affinity + gain, 100.0)
	emit_signal("affinity_changed", npc.affinity)
	emit_signal("cooldown_changed", npc.love_cooldown)
	emit_signal("request_persist", {"love_cooldown": npc.love_cooldown, "affinity": npc.affinity})

func preview_breakup_reward() -> float:
	var bounds: Vector2 = ExFactorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	var denom: float = bounds.y - bounds.x
	var fraction: float = 0.0
	if denom > 0.0:
		fraction = (npc.relationship_progress - bounds.x) / denom
	var stage_idx: int = max(1, npc.relationship_stage)
	var base: float
	if npc.relationship_stage < NPCManager.RelationshipStage.MARRIED:
		base = pow(10.0, float(stage_idx - 1))
	else:
		var level: int = get_marriage_level(npc.relationship_progress)
		base = 10000.0 * pow(1.5, float(level - 1))
	return (0.1 + fraction * 0.9) * base

func confirm_breakup() -> void:
	var reward: float = preview_breakup_reward()
	var current_ex: float = StatManager.get_stat("ex", 0.0)
	StatManager.set_base_stat("ex", current_ex + reward)

	if npc.relationship_stage == NPCManager.RelationshipStage.MARRIED:
		npc.relationship_stage = NPCManager.RelationshipStage.DIVORCED
		PortfolioManager.halve_assets()
	else:
		npc.relationship_stage = NPCManager.RelationshipStage.EX

	npc.relationship_progress = 0.0
	npc.affinity *= 0.2

	progress_paused = true
	change_state(npc.relationship_stage)

	emit_signal("affinity_changed", npc.affinity)
	emit_signal("progress_changed", npc.relationship_progress)
	emit_signal("request_persist", {
		"relationship_progress": npc.relationship_progress,
		"affinity": npc.affinity
	})

	if npc_idx != -1:
		NPCManager.set_relationship_stage(npc_idx, npc.relationship_stage)
		NPCManager.player_broke_up_with(npc_idx)

	npc.emit_signal("player_broke_up")

func apologize_try() -> bool:
	var cost: int = APOLOGIZE_COST
	var current_ex: float = StatManager.get_stat("ex", 0.0)
	if current_ex < float(cost):
			return false

	StatManager.set_base_stat("ex", current_ex - float(cost))

	npc.relationship_stage = NPCManager.RelationshipStage.TALKING
	npc.relationship_progress = 0.0
	npc.affinity = 1.0
	npc.gift_count = 0
	npc.date_count = 0
	_recalc_costs()

	progress_paused = false
	change_state(npc.relationship_stage)

	emit_signal("affinity_changed", npc.affinity)
	emit_signal("progress_changed", npc.relationship_progress)
	emit_signal("request_persist", {
			"relationship_progress": npc.relationship_progress,
			"affinity": npc.affinity,
			"gift_count": npc.gift_count,
			"date_count": npc.date_count
	})

	if npc_idx != -1:
		NPCManager.set_relationship_stage(npc_idx, npc.relationship_stage)

	return true

func get_apologize_cost() -> int:
	return APOLOGIZE_COST

func request_next_stage_primary() -> void:
	if npc.relationship_stage == NPCManager.RelationshipStage.DATING:
		_transition_dating_to_serious_monog()
	elif npc.relationship_stage == NPCManager.RelationshipStage.SERIOUS:
		var ok: bool = PortfolioManager.attempt_spend(npc.proposal_cost, PortfolioManager.CREDIT_REQUIREMENTS["proposal"])
		if ok:
			_advance_one_stage()
	else:
		_advance_one_stage()

func request_next_stage_alt_for_dating() -> void:
	if npc.relationship_stage == NPCManager.RelationshipStage.DATING:
		_transition_dating_to_serious_poly()

func toggle_exclusivity() -> void:
	if npc.exclusivity_core == NPCManager.ExclusivityCore.MONOG:
		if npc_idx != -1:
			if npc.relationship_stage == NPCManager.RelationshipStage.DATING:
				NPCManager.go_poly_during_dating(npc_idx)
			else:
				NPCManager.request_poly_at_serious_or_engaged(npc_idx)
		else:
			npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
			npc.affinity *= 0.1
			emit_signal("affinity_changed", npc.affinity)
	elif npc.exclusivity_core == NPCManager.ExclusivityCore.POLY:
		if npc_idx != -1:
			if npc.relationship_stage == NPCManager.RelationshipStage.DATING:
				NPCManager.go_exclusive_during_dating(npc_idx)
			else:
				NPCManager.return_to_monogamy(npc_idx)
		else:
			var cheating: bool = _player_is_cheating()
			if cheating:
				npc.exclusivity_core = NPCManager.ExclusivityCore.CHEATING
				npc.affinity *= 0.25
				npc.affinity_equilibrium *= 0.5
				NPCManager.notify_player_advanced_someone_to_dating(-1)
				emit_signal("equilibrium_changed", npc.affinity_equilibrium)
			else:
				npc.exclusivity_core = NPCManager.ExclusivityCore.MONOG
				npc.affinity = min(npc.affinity * 1.5, 100.0)
			emit_signal("affinity_changed", npc.affinity)
	elif npc.exclusivity_core == NPCManager.ExclusivityCore.CHEATING:
		if npc_idx != -1:
			NPCManager.come_clean_from_cheating(npc_idx)
		else:
			npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
			npc.affinity = 1.0
			emit_signal("affinity_changed", npc.affinity)

	emit_signal("exclusivity_changed", npc.exclusivity_core)

# ---------------------------- Internal helpers ----------------------------

func _advance_one_stage() -> void:
	npc.relationship_stage += 1
	if npc.relationship_stage >= NPCManager.RelationshipStage.MARRIED:
		npc.affinity_equilibrium = npc.affinity_equilibrium
	else:
		npc.affinity_equilibrium = float(npc.relationship_stage) * 10.0

	if npc_idx != -1:
		NPCManager.set_relationship_stage(npc_idx, npc.relationship_stage)

	progress_paused = false
	change_state(npc.relationship_stage)
	emit_signal("equilibrium_changed", npc.affinity_equilibrium)

func _transition_dating_to_serious_monog() -> void:
	if npc_idx != -1:
		NPCManager.transition_dating_to_serious_monog(npc_idx)
		npc.relationship_stage = NPCManager.RelationshipStage.SERIOUS
	else:
		npc.relationship_stage = NPCManager.RelationshipStage.SERIOUS
		npc.exclusivity_core = NPCManager.ExclusivityCore.MONOG
		if not npc.claimed_serious_monog_boost:
			npc.affinity += 20.0
			npc.claimed_serious_monog_boost = true
		emit_signal("affinity_changed", npc.affinity)

	progress_paused = false
	change_state(npc.relationship_stage)

func _transition_dating_to_serious_poly() -> void:
	if npc_idx != -1:
		NPCManager.transition_dating_to_serious_poly(npc_idx)
		npc.relationship_stage = NPCManager.RelationshipStage.SERIOUS
	else:
		npc.relationship_stage = NPCManager.RelationshipStage.SERIOUS
		npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
		npc.affinity *= 0.1
		npc.affinity_equilibrium *= 0.5
		emit_signal("affinity_changed", npc.affinity)
		emit_signal("equilibrium_changed", npc.affinity_equilibrium)

	progress_paused = false
	change_state(npc.relationship_stage)

func _player_is_cheating() -> bool:
	for idx in NPCManager.encountered_npcs:
		var other_idx: int = int(idx)
		var other: NPC = NPCManager.get_npc_by_index(other_idx)
		if other == null:
			continue
		if other.relationship_stage >= NPCManager.RelationshipStage.DATING and other.relationship_stage <= NPCManager.RelationshipStage.MARRIED:
			return true
	return false

func _recalc_costs() -> void:
	if npc == null:
		return
	npc.gift_cost = (float(npc.attractiveness) / 10.0) * NPC.BASE_GIFT_COST * pow(2.0, npc.gift_count)
	npc.date_cost = (float(npc.attractiveness) / 10.0) * NPC.BASE_DATE_COST * pow(2.0, npc.date_count)
	emit_signal("costs_changed", npc.gift_cost, npc.date_cost)

func _emit_blocked() -> void:
	var blocked: bool = npc.relationship_stage >= NPCManager.RelationshipStage.DIVORCED
	emit_signal("blocked_state_changed", blocked)

# ---------------------------- States ----------------------------

class SuitorState:
	var machine: ExFactorLogic
	var npc: NPC

	func _init(machine_ref: ExFactorLogic) -> void:
		machine = machine_ref
		npc = machine_ref.npc

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

	func _init(machine_ref: ExFactorLogic, stage_id: int) -> void:
		super._init(machine_ref)
		stage = stage_id

	func update(delta: float) -> void:
		var bounds: Vector2 = ExFactorLogic.get_stage_bounds(stage, npc.relationship_progress)
		var rate: float = max(npc.affinity, 0.0) * 0.1
		npc.relationship_progress += rate * delta

		var range_size: float = bounds.y - bounds.x
		var frac: float = 0.0
		if range_size > 0.0:
			frac = (npc.relationship_progress - bounds.x) / range_size

		var stops: Array = ExFactorLogic.get_stop_points(stage)
		for stop in stops:
			var f: float = stop["fraction"]
			var req: int = stop["required"]
			if frac >= f and npc.date_count < req:
				npc.relationship_progress = bounds.x + f * range_size
				machine.progress_paused = true
				machine.emit_signal("stage_gate_reached")
				return

		if stage < NPCManager.RelationshipStage.MARRIED and npc.relationship_progress >= bounds.y:
			npc.relationship_progress = bounds.y
			machine.progress_paused = true
			machine.emit_signal("stage_gate_reached")

	func get_stop_marks() -> Array[float]:
		var marks: Array[float] = []
		var stops: Array = ExFactorLogic.get_stop_points(stage)
		for stop in stops:
			var f2: float = stop["fraction"]
			var req2: int = stop["required"]
			if npc.date_count < req2:
				marks.append(f2)
		return marks

class StrangerState extends PreMarriageState:
	func _init(machine_ref: ExFactorLogic) -> void:
		super._init(machine_ref, NPCManager.RelationshipStage.STRANGER)

class TalkingState extends PreMarriageState:
	func _init(machine_ref: ExFactorLogic) -> void:
		super._init(machine_ref, NPCManager.RelationshipStage.TALKING)

class DatingState extends PreMarriageState:
	func _init(machine_ref: ExFactorLogic) -> void:
		super._init(machine_ref, NPCManager.RelationshipStage.DATING)

class SeriousState extends PreMarriageState:
	func _init(machine_ref: ExFactorLogic) -> void:
		super._init(machine_ref, NPCManager.RelationshipStage.SERIOUS)

class EngagedState extends PreMarriageState:
	func _init(machine_ref: ExFactorLogic) -> void:
		super._init(machine_ref, NPCManager.RelationshipStage.ENGAGED)

class MarriedState extends SuitorState:
	func update(delta: float) -> void:
		var rate: float = max(npc.affinity, 0.0) * 0.1
		npc.relationship_progress += rate * delta

class DivorcedState extends SuitorState:
	pass

class ExState extends SuitorState:
	pass
