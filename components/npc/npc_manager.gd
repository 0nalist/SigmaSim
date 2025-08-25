extends Node
# Autoload: NPCManager

signal portrait_changed(idx, cfg)
signal affinity_changed(idx, value)
signal exclusivity_core_changed(idx: int, old_core: int, new_core: int)
signal relationship_stage_changed(idx: int, old_stage: int, new_stage: int)
signal cheating_detected(primary_idx: int, other_idx: int)
signal affinity_equilibrium_changed(idx: int, value: float)
signal breakup_occurred(idx: int)

enum RelationshipStage { STRANGER, TALKING, DATING, SERIOUS, ENGAGED, MARRIED, DIVORCED, EX }
enum ExclusivityCore { MONOG, POLY, CHEATING }
enum ExclusivityDescriptor { UNMENTIONED, DATING_AROUND, EXCLUSIVE, MONOGAMOUS, POLYAMOROUS, OPEN, CHEATING }

var encounter_count: int = 0
var encountered_npcs: Array[int] = []
var encountered_npcs_by_app: Dictionary = {}
var active_npcs_by_app: Dictionary = {}

var daterbase_npcs: Array[int] = []

var relationship_status: Dictionary = {}
var persistent_npcs: Dictionary = {}
var npc_overrides: Dictionary = {}
var npcs: Dictionary = {}

var persistent_by_gender: Dictionary = {}
var persistent_by_wealth: Dictionary = {}
var _save_queue: Dictionary = {}
var _save_timer: Timer

func _ready() -> void:
				TimeManager.hour_passed.connect(_on_hour_passed)
				_save_timer = Timer.new()
				_save_timer.wait_time = 0.5
				_save_timer.one_shot = true
				_save_timer.timeout.connect(_flush_save_queue)
				add_child(_save_timer)
				relationship_stage_changed.connect(func(idx, _o, _n): _recheck_daterbase_exclusivity(idx))
				exclusivity_core_changed.connect(func(idx, _o, _n): _recheck_daterbase_exclusivity(idx))
				load_daterbase_cache()

func _queue_save(idx: int) -> void:
		_save_queue[idx] = true
		if _save_timer.is_stopped():
				_save_timer.start()

func _flush_save_queue() -> void:
				for idx in _save_queue.keys():
								DBManager.save_npc(idx, npcs[idx])
				_save_queue.clear()

func load_daterbase_cache() -> void:
				daterbase_npcs.clear()
				var entries: Array = DBManager.get_daterbase_entries()
				for entry in entries:
								daterbase_npcs.append(int(entry.npc_id))

func add_daterbase_npc(idx: int) -> void:
				if not daterbase_npcs.has(idx):
								daterbase_npcs.append(idx)

func get_daterbase_npcs() -> Array[int]:
				return daterbase_npcs

# === MAIN API ===

func get_npc_by_index(idx: int) -> NPC:
	if npcs.has(idx):
		return npcs[idx]

	var npc: NPC

	if DBManager.has_npc(idx, SaveManager.current_slot_id):
		npc = _load_npc_from_db(idx)
	else:
		npc = NPCFactory.create_npc(idx)

	# Apply persistent or override data without clobbering existing fields
	var data: Dictionary = persistent_npcs.get(idx, npc_overrides.get(idx, {}))
	_merge_npc_data(npc, data)

	if npc.portrait_config == null:
		npc.portrait_config = PortraitFactory.ensure_config_for_npc(idx, npc.full_name)


	npcs[idx] = npc
	return npc

func set_npc_field(idx: int, field: String, value) -> void:
	if not npcs.has(idx):
			push_error("Tried to set a field on a non-existent NPC!")
			return
	npcs[idx].set(field, value)

	if field == "relationship_stage":
			npcs[idx].affinity_equilibrium = float(value) * 10.0
			if persistent_npcs.has(idx):
					persistent_npcs[idx]["affinity_equilibrium"] = npcs[idx].affinity_equilibrium
			emit_signal("affinity_equilibrium_changed", idx, npcs[idx].affinity_equilibrium)
	elif field == "affinity_equilibrium":
			emit_signal("affinity_equilibrium_changed", idx, npcs[idx].affinity_equilibrium)

	if persistent_npcs.has(idx):
			persistent_npcs[idx][field] = value
			_queue_save(idx)
	else:
			if not npc_overrides.has(idx):
					npc_overrides[idx] = {}
			npc_overrides[idx][field] = value
			if field == "portrait_config":
					promote_to_persistent(idx)

	if field == "portrait_config":
			emit_signal("portrait_changed", idx, value)
	if field == "affinity":
			emit_signal("affinity_changed", idx, value)



func promote_to_persistent(idx: int) -> void:
	if not persistent_npcs.has(idx):
		var npc = get_npc_by_index(idx)
		persistent_npcs[idx] = npc_overrides.get(idx, {}).duplicate()
		npc_overrides.erase(idx)
		_index_persistent_npc(idx)
		# Ensure dynamic counts are persisted immediately so they survive reloads
		persistent_npcs[idx]["gift_count"] = npc.gift_count
		persistent_npcs[idx]["date_count"] = npc.date_count
		DBManager.save_npc(idx, npc)

# Returns NPC indices matching a dot product similarity threshold with preferred_gender
func get_npcs_by_gender_dot(app_name: String, preferred_gender: Vector3, min_similarity: float, count: int, exclude: Array[int]=[]) -> Array[int]:
	var matches: Array[int] = []
	for idx in encountered_npcs_by_app.get(app_name, []):
		if exclude.has(idx):
			continue
		var npc = get_npc_by_index(idx)
		var sim = gender_dot_similarity(preferred_gender, npc.gender_vector)
		if sim >= min_similarity:
			matches.append(idx)
	RNGManager.npc_manager.shuffle(matches)
	return matches.slice(0, count)

func gender_dot_similarity(a: Vector3, b: Vector3) -> float:
		if a.length() == 0 or b.length() == 0:
				return 0.0
		return a.dot(b) / (a.length() * b.length()) # [0,1]



func _merge_npc_data(npc: NPC, data: Dictionary) -> void:
		if data.is_empty():
				return
		var exported: Dictionary = {}
		for prop in npc.get_property_list():
				if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
						exported[prop.name] = true
		for key in data.keys():
				if not exported.has(key):
						continue
				var override_val = data[key]
				var existing_val = npc.get(key)
				match typeof(override_val):
						TYPE_ARRAY:
								if typeof(existing_val) == TYPE_ARRAY:
										existing_val.clear()
										for v in override_val:
												existing_val.append(v)
								else:
										npc.set(key, override_val.duplicate())
						TYPE_DICTIONARY:
								if typeof(existing_val) == TYPE_DICTIONARY:
										for sub_key in override_val.keys():
												existing_val[sub_key] = override_val[sub_key]
								else:
										npc.set(key, override_val.duplicate())
						TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING:
								npc.set(key, override_val)
						TYPE_OBJECT:
								npc.set(key, override_val)
						_:
								if existing_val == null:
									npc.set(key, override_val)





func _index_persistent_npc(idx: int) -> void:
	var npc = get_npc_by_index(idx)
	# Gender bucket
	var g := "nb"
	if npc.gender_vector.x > 0.5:
		g = "f"
	if npc.gender_vector.y > 0.5:
		g = "m"
	if not persistent_by_gender.has(g):
		persistent_by_gender[g] = []
	persistent_by_gender[g].append(idx)
	# Wealth bucket
	var w := "middle"
	if npc.wealth < 0:
		w = "poor"
	elif npc.wealth > 1_000_000:
		w = "rich"
	if not persistent_by_wealth.has(w):
		persistent_by_wealth[w] = []
	persistent_by_wealth[w].append(idx)

func _load_npc_from_db(idx: int) -> NPC:
	var npc: NPC = DBManager.load_npc(idx)
	if npc == null:
		push_error("Tried to load NPC index %d but not found in DB!" % idx)
		return NPCFactory.create_npc(idx)
	return npc

func _on_hour_passed(_current_hour: int, _total_minutes: int) -> void:
		for npc_idx in daterbase_npcs:
				var npc: NPC = get_npc_by_index(npc_idx)
				var target: float = npc.affinity_equilibrium
				var current: float = npc.affinity
				var rate: float = StatManager.get_stat("affinity_drift_rate", 1.0)
				if current < target:
						set_npc_field(npc_idx, "affinity", min(current + rate, target))
				elif current > target:
						set_npc_field(npc_idx, "affinity", max(current - rate, target))

# === RELATIONSHIP MANAGEMENT ===

func exclusivity_descriptor_for(stage: int, core: int, had_exclusive_flag: bool) -> int:
	if core == ExclusivityCore.CHEATING:
		return ExclusivityDescriptor.CHEATING
	if stage == RelationshipStage.TALKING or stage == RelationshipStage.STRANGER:
		return ExclusivityDescriptor.UNMENTIONED
	if stage == RelationshipStage.DATING:
		if core == ExclusivityCore.MONOG:
			return ExclusivityDescriptor.EXCLUSIVE
		#if had_exclusive_flag:
		#	return ExclusivityDescriptor.DATING_AROUND
		#return ExclusivityDescriptor.UNMENTIONED
		return ExclusivityDescriptor.DATING_AROUND
	if stage == RelationshipStage.SERIOUS or stage == RelationshipStage.ENGAGED:
		if core == ExclusivityCore.MONOG:
			return ExclusivityDescriptor.MONOGAMOUS
		return ExclusivityDescriptor.POLYAMOROUS
	if stage == RelationshipStage.MARRIED:
		if core == ExclusivityCore.MONOG:
			return ExclusivityDescriptor.MONOGAMOUS
		return ExclusivityDescriptor.OPEN
	return ExclusivityDescriptor.UNMENTIONED

func exclusivity_descriptor_label(npc_idx: int) -> String:
	var npc: NPC = get_npc_by_index(npc_idx)
	var desc: int = exclusivity_descriptor_for(npc.relationship_stage, npc.exclusivity_core, npc.claimed_exclusive_boost)
	match desc:
		ExclusivityDescriptor.UNMENTIONED:
			return "Unmentioned"
		ExclusivityDescriptor.DATING_AROUND:
			return "Dating Around"
		ExclusivityDescriptor.EXCLUSIVE:
			return "Exclusive"
		ExclusivityDescriptor.MONOGAMOUS:
			return "Monogamous"
		ExclusivityDescriptor.POLYAMOROUS:
			return "Polyamorous"
		ExclusivityDescriptor.OPEN:
			return "Open"
		ExclusivityDescriptor.CHEATING:
			return "Cheating"
		_:
			return "Unmentioned"

func set_relationship_stage(npc_idx: int, new_stage: int) -> void:
	var npc: NPC = get_npc_by_index(npc_idx)
	var old_stage: int = npc.relationship_stage
	if old_stage == new_stage:
		return
	var old_core: int = npc.exclusivity_core
	var old_affinity: float = npc.affinity
	var old_equilibrium: float = npc.affinity_equilibrium
	npc.relationship_stage = new_stage
	npc.affinity_equilibrium = float(new_stage) * 10.0
	promote_to_persistent(npc_idx)
	persistent_npcs[npc_idx]["relationship_stage"] = npc.relationship_stage
	persistent_npcs[npc_idx]["affinity_equilibrium"] = npc.affinity_equilibrium
	DBManager.save_npc(npc_idx, npc)
	emit_signal("relationship_stage_changed", npc_idx, old_stage, npc.relationship_stage)
	if old_equilibrium != npc.affinity_equilibrium:
		emit_signal("affinity_equilibrium_changed", npc_idx, npc.affinity_equilibrium)
	print("NPC %d: stage %d -> %d core %d -> %d affinity %.2f -> %.2f eq %.2f -> %.2f" % [npc_idx, old_stage, npc.relationship_stage, old_core, npc.exclusivity_core, old_affinity, npc.affinity, old_equilibrium, npc.affinity_equilibrium])

	if new_stage >= RelationshipStage.DATING and old_stage < RelationshipStage.DATING:
		notify_player_advanced_someone_to_dating(npc_idx)
	print("NPC %d: stage %d -> %d core %d -> %d affinity %.2f -> %.2f eq %.2f -> %.2f" % [npc_idx, old_stage, npc.relationship_stage, old_core, npc.exclusivity_core, old_affinity, npc.affinity, old_equilibrium, npc.affinity_equilibrium])

func go_exclusive_during_dating(npc_idx: int) -> void:
	var npc: NPC = get_npc_by_index(npc_idx)
	if npc.relationship_stage != RelationshipStage.DATING:
			return
	if npc.exclusivity_core == ExclusivityCore.MONOG:
			return
	for idx in encountered_npcs:
			var other_idx: int = int(idx)
			if other_idx == npc_idx:
					continue
			var other: NPC = get_npc_by_index(other_idx)
			if other.relationship_stage >= RelationshipStage.DATING and other.relationship_stage <= RelationshipStage.MARRIED:
					_mark_npc_as_cheating(npc_idx, other_idx)
					return
	var old_stage: int = npc.relationship_stage
	var old_core: int = npc.exclusivity_core
	var old_affinity: float = npc.affinity
	var old_equilibrium: float = npc.affinity_equilibrium
	npc.exclusivity_core = ExclusivityCore.MONOG
	npc.affinity = min(npc.affinity * 1.5, 100.0)
	npc.claimed_exclusive_boost = true
	promote_to_persistent(npc_idx)
	persistent_npcs[npc_idx]["exclusivity_core"] = npc.exclusivity_core
	persistent_npcs[npc_idx]["affinity"] = npc.affinity
	persistent_npcs[npc_idx]["claimed_exclusive_boost"] = npc.claimed_exclusive_boost
	DBManager.save_npc(npc_idx, npc)
	if old_core != npc.exclusivity_core:
		emit_signal("exclusivity_core_changed", npc_idx, old_core, npc.exclusivity_core)
	if old_affinity != npc.affinity:
		emit_signal("affinity_changed", npc_idx, npc.affinity)
		print("NPC %d: stage %d -> %d core %d -> %d affinity %.2f -> %.2f eq %.2f -> %.2f" % [npc_idx, old_stage, npc.relationship_stage, old_core, npc.exclusivity_core, old_affinity, npc.affinity, old_equilibrium, npc.affinity_equilibrium])
	notify_player_advanced_someone_to_dating(npc_idx)

func go_poly_during_dating(npc_idx: int) -> void:
	var npc: NPC = get_npc_by_index(npc_idx)
	if npc.relationship_stage != RelationshipStage.DATING:
			return
	if npc.exclusivity_core == ExclusivityCore.POLY:
			return
	var old_stage: int = npc.relationship_stage
	var old_core: int = npc.exclusivity_core
	var old_affinity: float = npc.affinity
	npc.exclusivity_core = ExclusivityCore.POLY
	npc.affinity = npc.affinity * 0.1
	promote_to_persistent(npc_idx)
	persistent_npcs[npc_idx]["exclusivity_core"] = npc.exclusivity_core
	persistent_npcs[npc_idx]["affinity"] = npc.affinity
	DBManager.save_npc(npc_idx, npc)
	emit_signal("exclusivity_core_changed", npc_idx, old_core, npc.exclusivity_core)
	emit_signal("affinity_changed", npc_idx, npc.affinity)
	print("NPC %d: stage %d -> %d core %d -> %d affinity %.2f -> %.2f" % [npc_idx, old_stage, npc.relationship_stage, old_core, npc.exclusivity_core, old_affinity, npc.affinity])

func transition_dating_to_serious_monog(npc_idx: int) -> void:
	var npc: NPC = get_npc_by_index(npc_idx)
	if npc.relationship_stage != RelationshipStage.DATING:
		return
	for idx in encountered_npcs:
		var other_idx: int = int(idx)
		if other_idx == npc_idx:
			continue
		var other: NPC = get_npc_by_index(other_idx)
		if other.relationship_stage >= RelationshipStage.DATING and other.relationship_stage <= RelationshipStage.MARRIED:
			_mark_npc_as_cheating(npc_idx, other_idx)
			return
	var old_stage: int = npc.relationship_stage
	var old_core: int = npc.exclusivity_core
	var old_affinity: float = npc.affinity
	var old_equilibrium: float = npc.affinity_equilibrium
	npc.relationship_stage = RelationshipStage.SERIOUS
	npc.exclusivity_core = ExclusivityCore.MONOG
	if not npc.claimed_serious_monog_boost:
		npc.affinity = npc.affinity + 20.0
		npc.claimed_serious_monog_boost = true
	promote_to_persistent(npc_idx)
	persistent_npcs[npc_idx]["relationship_stage"] = npc.relationship_stage
	persistent_npcs[npc_idx]["exclusivity_core"] = npc.exclusivity_core
	persistent_npcs[npc_idx]["affinity"] = npc.affinity
	persistent_npcs[npc_idx]["claimed_serious_monog_boost"] = npc.claimed_serious_monog_boost
	DBManager.save_npc(npc_idx, npc)
	emit_signal("relationship_stage_changed", npc_idx, old_stage, npc.relationship_stage)
	if old_core != npc.exclusivity_core:
		emit_signal("exclusivity_core_changed", npc_idx, old_core, npc.exclusivity_core)
	if old_affinity != npc.affinity:
		emit_signal("affinity_changed", npc_idx, npc.affinity)
	print("NPC %d: stage %d -> %d core %d -> %d affinity %.2f -> %.2f eq %.2f -> %.2f" % [npc_idx, old_stage, npc.relationship_stage, old_core, npc.exclusivity_core, old_affinity, npc.affinity, old_equilibrium, npc.affinity_equilibrium])
	notify_player_advanced_someone_to_dating(npc_idx)

func transition_dating_to_serious_poly(npc_idx: int) -> void:
	var npc: NPC = get_npc_by_index(npc_idx)
	if npc.relationship_stage != RelationshipStage.DATING:
		return
	var old_stage: int = npc.relationship_stage
	var old_core: int = npc.exclusivity_core
	var old_affinity: float = npc.affinity
	var old_equilibrium: float = npc.affinity_equilibrium
	npc.relationship_stage = RelationshipStage.SERIOUS
	npc.exclusivity_core = ExclusivityCore.POLY
	npc.affinity = npc.affinity * 0.1
	npc.affinity_equilibrium = npc.affinity_equilibrium * 0.5
	promote_to_persistent(npc_idx)
	persistent_npcs[npc_idx]["relationship_stage"] = npc.relationship_stage
	persistent_npcs[npc_idx]["exclusivity_core"] = npc.exclusivity_core
	persistent_npcs[npc_idx]["affinity"] = npc.affinity
	persistent_npcs[npc_idx]["affinity_equilibrium"] = npc.affinity_equilibrium
	DBManager.save_npc(npc_idx, npc)
	emit_signal("relationship_stage_changed", npc_idx, old_stage, npc.relationship_stage)
	if old_core != npc.exclusivity_core:
		emit_signal("exclusivity_core_changed", npc_idx, old_core, npc.exclusivity_core)
	if old_affinity != npc.affinity:
		emit_signal("affinity_changed", npc_idx, npc.affinity)
	if old_equilibrium != npc.affinity_equilibrium:
		emit_signal("affinity_equilibrium_changed", npc_idx, npc.affinity_equilibrium)
	print("NPC %d: stage %d -> %d core %d -> %d affinity %.2f -> %.2f eq %.2f -> %.2f" % [npc_idx, old_stage, npc.relationship_stage, old_core, npc.exclusivity_core, old_affinity, npc.affinity, old_equilibrium, npc.affinity_equilibrium])

func request_poly_at_serious_or_engaged(npc_idx: int) -> void:
	var npc: NPC = get_npc_by_index(npc_idx)
	if npc.relationship_stage != RelationshipStage.SERIOUS and npc.relationship_stage != RelationshipStage.ENGAGED and npc.relationship_stage != RelationshipStage.MARRIED:
		return
	if npc.exclusivity_core == ExclusivityCore.POLY:
		return
	var old_stage: int = npc.relationship_stage
	var old_core: int = npc.exclusivity_core
	var old_affinity: float = npc.affinity
	var old_equilibrium: float = npc.affinity_equilibrium
	npc.exclusivity_core = ExclusivityCore.POLY
	npc.affinity = npc.affinity * 0.1
	npc.affinity_equilibrium = npc.affinity_equilibrium * 0.5
	promote_to_persistent(npc_idx)
	persistent_npcs[npc_idx]["exclusivity_core"] = npc.exclusivity_core
	persistent_npcs[npc_idx]["affinity"] = npc.affinity
	persistent_npcs[npc_idx]["affinity_equilibrium"] = npc.affinity_equilibrium
	DBManager.save_npc(npc_idx, npc)
	if old_core != npc.exclusivity_core:
		emit_signal("exclusivity_core_changed", npc_idx, old_core, npc.exclusivity_core)
	if old_affinity != npc.affinity:
		emit_signal("affinity_changed", npc_idx, npc.affinity)
	if old_equilibrium != npc.affinity_equilibrium:
		emit_signal("affinity_equilibrium_changed", npc_idx, npc.affinity_equilibrium)
	print("NPC %d: stage %d -> %d core %d -> %d affinity %.2f -> %.2f eq %.2f -> %.2f" % [npc_idx, old_stage, npc.relationship_stage, old_core, npc.exclusivity_core, old_affinity, npc.affinity, old_equilibrium, npc.affinity_equilibrium])

func return_to_monogamy(npc_idx: int) -> void:
	var npc: NPC = get_npc_by_index(npc_idx)
	if npc.relationship_stage != RelationshipStage.SERIOUS and npc.relationship_stage != RelationshipStage.ENGAGED and npc.relationship_stage != RelationshipStage.MARRIED:
			return
	if npc.exclusivity_core != ExclusivityCore.POLY:
			return
	for idx in encountered_npcs:
		var other_idx: int = int(idx)
		if other_idx == npc_idx:
			continue
		var other: NPC = get_npc_by_index(other_idx)
		if other.relationship_stage >= RelationshipStage.DATING and other.relationship_stage <= RelationshipStage.MARRIED:
			_mark_npc_as_cheating(npc_idx, other_idx)
			return
	var old_stage: int = npc.relationship_stage
	var old_core: int = npc.exclusivity_core
	var old_affinity: float = npc.affinity
	var old_equilibrium: float = npc.affinity_equilibrium
	npc.exclusivity_core = ExclusivityCore.MONOG
	npc.affinity = min(npc.affinity * 1.5, 100.0)
	promote_to_persistent(npc_idx)
	persistent_npcs[npc_idx]["exclusivity_core"] = npc.exclusivity_core
	persistent_npcs[npc_idx]["affinity"] = npc.affinity
	DBManager.save_npc(npc_idx, npc)
	emit_signal("exclusivity_core_changed", npc_idx, old_core, npc.exclusivity_core)
	emit_signal("affinity_changed", npc_idx, npc.affinity)
	print("NPC %d: stage %d -> %d core %d -> %d affinity %.2f -> %.2f eq %.2f -> %.2f" % [npc_idx, old_stage, npc.relationship_stage, old_core, npc.exclusivity_core, old_affinity, npc.affinity, old_equilibrium, npc.affinity_equilibrium])
	notify_player_advanced_someone_to_dating(npc_idx)
	
	

func come_clean_from_cheating(npc_idx: int) -> void:
	var npc: NPC = get_npc_by_index(npc_idx)
	if npc.exclusivity_core != ExclusivityCore.CHEATING:
			return
	var old_core: int = npc.exclusivity_core
	var old_affinity: float = npc.affinity
	npc.exclusivity_core = ExclusivityCore.POLY
	npc.affinity = 1.0
	promote_to_persistent(npc_idx)
	persistent_npcs[npc_idx]["exclusivity_core"] = npc.exclusivity_core
	persistent_npcs[npc_idx]["affinity"] = npc.affinity
	DBManager.save_npc(npc_idx, npc)
	emit_signal("exclusivity_core_changed", npc_idx, old_core, npc.exclusivity_core)
	emit_signal("affinity_changed", npc_idx, npc.affinity)
	print("NPC %d: come clean from cheating core %d -> %d affinity %.2f -> %.2f" % [npc_idx, old_core, npc.exclusivity_core, old_affinity, npc.affinity])

func _mark_npc_as_cheating(npc_idx: int, other_idx: int) -> void:
	var npc: NPC = get_npc_by_index(npc_idx)
	var old_stage: int = npc.relationship_stage
	var old_core: int = npc.exclusivity_core
	var old_affinity: float = npc.affinity
	var old_equilibrium: float = npc.affinity_equilibrium
	npc.exclusivity_core = ExclusivityCore.CHEATING
	npc.affinity = npc.affinity * 0.25
	npc.affinity_equilibrium = npc.affinity_equilibrium * 0.5
	promote_to_persistent(npc_idx)
	persistent_npcs[npc_idx]["exclusivity_core"] = npc.exclusivity_core
	persistent_npcs[npc_idx]["affinity"] = npc.affinity
	persistent_npcs[npc_idx]["affinity_equilibrium"] = npc.affinity_equilibrium
	DBManager.save_npc(npc_idx, npc)
	emit_signal("exclusivity_core_changed", npc_idx, old_core, npc.exclusivity_core)
	emit_signal("affinity_changed", npc_idx, npc.affinity)
	if old_equilibrium != npc.affinity_equilibrium:
			emit_signal("affinity_equilibrium_changed", npc_idx, npc.affinity_equilibrium)
			emit_signal("cheating_detected", npc_idx, other_idx)
			print("NPC %d: stage %d -> %d core %d -> %d affinity %.2f -> %.2f eq %.2f -> %.2f" % [npc_idx, old_stage, npc.relationship_stage, old_core, npc.exclusivity_core, old_affinity, npc.affinity, old_equilibrium, npc.affinity_equilibrium])

func player_broke_up_with(npc_idx: int) -> void:
		emit_signal("breakup_occurred", npc_idx)
		_check_cheating_after_breakup()

func _check_cheating_after_breakup() -> void:
		for idx in encountered_npcs:
				var check_idx: int = int(idx)
				var npc: NPC = get_npc_by_index(check_idx)
				if npc.exclusivity_core == ExclusivityCore.CHEATING:
						var still_cheating: bool = false
						for other in encountered_npcs:
								var other_idx: int = int(other)
								if other_idx == check_idx:
										continue
								var other_npc: NPC = get_npc_by_index(other_idx)
								if other_npc.relationship_stage >= RelationshipStage.DATING and other_npc.relationship_stage <= RelationshipStage.MARRIED:
										still_cheating = true
										break
						if not still_cheating:
								come_clean_from_cheating(check_idx)

func _recheck_daterbase_exclusivity(changed_idx: int) -> void:
	var active: Array[int] = []
	for idx in daterbase_npcs:
			var npc = get_npc_by_index(int(idx))
			if npc.relationship_stage >= RelationshipStage.DATING and npc.relationship_stage <= RelationshipStage.MARRIED:
					active.append(int(idx))

	for idx in daterbase_npcs:
			var npc_idx: int = int(idx)
			if npc_idx == changed_idx:
					continue
			var npc: NPC = get_npc_by_index(npc_idx)
			var npc_active: bool = active.has(npc_idx)
			var other_active_count: int = active.size()
			if npc_active:
				other_active_count -= 1

			if npc.exclusivity_core == ExclusivityCore.MONOG and npc_active and other_active_count > 0:
					var other_idx: int = -1
					for ai in active:
							if ai != npc_idx:
									other_idx = int(ai)
									break
					_mark_npc_as_cheating(npc_idx, other_idx)
			elif npc.exclusivity_core == ExclusivityCore.CHEATING and (not npc_active or other_active_count == 0):
					come_clean_from_cheating(npc_idx)

func notify_player_advanced_someone_to_dating(other_idx: int) -> void:
	for idx in daterbase_npcs:
			var npc_idx: int = int(idx)
			if npc_idx == other_idx:
					continue
			var npc: NPC = get_npc_by_index(npc_idx)
			if npc.exclusivity_core != ExclusivityCore.MONOG:
					continue
			if npc.relationship_stage < RelationshipStage.DATING:
					continue
			_mark_npc_as_cheating(npc_idx, other_idx)


func can_show_go_exclusive(npc_idx: int) -> bool:
	var npc: NPC = get_npc_by_index(npc_idx)
	return npc.relationship_stage == RelationshipStage.DATING and npc.exclusivity_core != ExclusivityCore.MONOG

func can_show_get_serious_monog(npc_idx: int) -> bool:
	var npc: NPC = get_npc_by_index(npc_idx)
	return npc.relationship_stage == RelationshipStage.DATING

func can_show_get_serious_poly(npc_idx: int) -> bool:
	var npc: NPC = get_npc_by_index(npc_idx)
	return npc.relationship_stage == RelationshipStage.DATING

func can_show_request_poly_now(npc_idx: int) -> bool:
	var npc: NPC = get_npc_by_index(npc_idx)
	if npc.relationship_stage == RelationshipStage.SERIOUS or npc.relationship_stage == RelationshipStage.ENGAGED or npc.relationship_stage == RelationshipStage.MARRIED:
		return npc.exclusivity_core != ExclusivityCore.POLY
	return false

func can_show_return_to_monogamy(npc_idx: int) -> bool:
	var npc: NPC = get_npc_by_index(npc_idx)
	if npc.relationship_stage == RelationshipStage.SERIOUS or npc.relationship_stage == RelationshipStage.ENGAGED or npc.relationship_stage == RelationshipStage.MARRIED:
		return npc.exclusivity_core == ExclusivityCore.POLY
	return false

# === BATCH HELPERS ===

func get_batch_of_new_npc_indices(app_name: String, count: int) -> Array[int]:
	var result: Array[int] = []
	for i in range(count):
		var idx = get_recyclable_npc_index_for_app(app_name)
		if idx == -1:
			idx = encounter_count
			encounter_count += 1
		if not encountered_npcs_by_app.has(app_name):
			encountered_npcs_by_app[app_name] = []
		if not encountered_npcs_by_app[app_name].has(idx):
			encountered_npcs_by_app[app_name].append(idx)
		if not active_npcs_by_app.has(app_name):
			active_npcs_by_app[app_name] = []
		if not active_npcs_by_app[app_name].has(idx):
			active_npcs_by_app[app_name].append(idx)
		if not encountered_npcs.has(idx):
			encountered_npcs.append(idx)
		result.append(idx)
	return result

func get_batch_of_recycled_npc_indices(app_name: String, count: int) -> Array[int]:
	var pool: Array[int] = []
	var encountered = encountered_npcs_by_app.get(app_name, [])
	var active = active_npcs_by_app.get(app_name, [])
	for idx in encountered:
		if not active.has(idx) and not persistent_npcs.has(idx):
			pool.append(idx)
	RNGManager.npc_manager.shuffle(pool)
	var result: Array[int] = []
	for idx in pool.slice(0, count):
		result.append(idx)
	return result

func get_recyclable_npc_index_for_app(app_name: String) -> int:
	var encountered = encountered_npcs_by_app.get(app_name, [])
	var active = active_npcs_by_app.get(app_name, [])
	for idx in encountered:
		if not active.has(idx) and not persistent_npcs.has(idx):
			return idx
	return -1

func mark_npc_inactive_in_app(idx: int, app_name: String) -> void:
	if active_npcs_by_app.has(app_name):
		active_npcs_by_app[app_name].erase(idx)

func set_relationship_status(idx: int, app_name: String, status: FumbleManager.FumbleStatus) -> void:
	if not relationship_status.has(idx):
		relationship_status[idx] = {}
	relationship_status[idx][app_name] = status

	if app_name == "fumble":
		DBManager.save_fumble_relationship(idx, status)


# Returns all NPC indices the player has "liked" in Fumble
func get_fumble_matches() -> Array:
	var matches = []
	var rels = DBManager.get_all_fumble_relationships()
	for idx in rels.keys():
		var status_enum: FumbleManager.FumbleStatus = rels[idx]
		# Show only if currently "liked" or "matched"
		if status_enum == FumbleManager.FumbleStatus.LIKED or status_enum == FumbleManager.FumbleStatus.MATCHED:
			matches.append(int(idx))
	return matches

func get_fumble_matches_with_times() -> Array:
	var out: Array = []
	var rows = DBManager.get_all_fumble_relationship_rows()
	for r in rows:
		var status_enum: FumbleManager.FumbleStatus = FumbleManager.FUMBLE_STATUS_LOOKUP.get(r.status, FumbleManager.FumbleStatus.LIKED)
		if status_enum == FumbleManager.FumbleStatus.LIKED or status_enum == FumbleManager.FumbleStatus.MATCHED:
				out.append({
						"npc_id": int(r.npc_id),
						"created_at": int(r.created_at),
						"updated_at": int(r.updated_at)
				})
	return out



# Returns true if a battle is active with this NPC (FumbleManager sets this flag)
func is_fumble_battle_active(npc_idx: int) -> bool:
		return FumbleManager.has_active_battle(npc_idx)


func restore_encountered_from_db() -> void:
		encountered_npcs.clear()
		for idx in DBManager.get_all_npc_ids():
				var id: int = int(idx)
				if not encountered_npcs.has(id):
						encountered_npcs.append(id)


func reset() -> void:
	encounter_count = 0
	encountered_npcs = []
	encountered_npcs_by_app = {}
	active_npcs_by_app = {}

	relationship_status = {}
	persistent_npcs = {}
	npc_overrides = {}
	npcs = {}

	persistent_by_gender = {}
	persistent_by_wealth = {}
