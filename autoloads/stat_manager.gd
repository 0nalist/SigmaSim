extends Node
# gdlint: disable=class-definitions-order
## StatManager is the single authority for every gameplay statistic.  All
## systems should use this class to query or modify stats rather than reaching
## into other managers.	 The manager supports permanent base values, upgrade
## effects, and temporary overrides used by buffs or special events.

signal stat_changed(stat: String, value: Variant)

# -- Stored data --------------------------------------------------------------

## Base values loaded from json files and mod overrides
var base_stats: Dictionary = {}

## Final computed stats after applying upgrades
var computed_stats: Dictionary = {}

## Temporary overrides that take precedence over computed values
var temporary_overrides: Dictionary = {}

## Map of stat_name -> Array[Callable] used for per‑stat callbacks
var _stat_signal_map: Dictionary = {}

## Optional dictionary of stat_name -> Callable used to calculate derived stats
var derived_stats: Dictionary = {
	"dime_status": func(stats: Dictionary) -> float: return stats.get("attractiveness", 0.0) / 10.0,
}

## Map of stat name -> Array of upgrade effect dictionaries affecting it
var stat_to_upgrades: Dictionary = {}

## Mapping of derived stat -> Array of dependency stat names
var stat_dependencies: Dictionary = {
	"dime_status": ["attractiveness"],
}

# Internal map of stat -> Array of derived stats that depend on it
var _dependents: Dictionary = {}


func _ready() -> void:
	_load_base_stats()
	_build_upgrade_cache()
	_build_dependents_map()
	UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	if UpgradeManager.has_signal("levels_changed"):
		UpgradeManager.levels_changed.connect(_on_levels_changed)
	recalculate_all_stats_once()


# -- Loading -----------------------------------------------------------------


func _load_base_stats() -> void:
	base_stats.clear()
	_load_stats_file("res://data/stats/base_stats.json")
	_load_stats_file("user://mods/stats/base_stats.json")


func _load_stats_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if typeof(data) == TYPE_DICTIONARY:
		for stat_key in data.keys():
			base_stats[stat_key] = float(data[stat_key])


# -- Public API --------------------------------------------------------------


func get_stat(stat_name: String, default: Variant = 0.0) -> Variant:
	# Temporary overrides always take precedence
	if temporary_overrides.has(stat_name):
		return temporary_overrides[stat_name]
	# Computed stats include all base stats after recalculation
	if computed_stats.has(stat_name):
		return computed_stats[stat_name]

	# Fallback to player-specific data stored in PlayerManager
	return PlayerManager.user_data.get(stat_name, default)


func get_all_stats() -> Dictionary:
	var result := PlayerManager.user_data.duplicate(true)
	for key in computed_stats.keys():
		result[key] = computed_stats[key]
	for key in temporary_overrides.keys():
		result[key] = temporary_overrides[key]
	return result


func get_base_stat(stat_name: String, default: Variant = 0.0) -> Variant:
	if base_stats.has(stat_name):
		return base_stats.get(stat_name, default)
	return PlayerManager.user_data.get(stat_name, default)


func set_base_stat(stat_name: String, value: Variant) -> void:
	# If the stat exists in PlayerManager.user_data but not in base_stats,
	# update the player data directly instead of creating a new base stat.
	if !base_stats.has(stat_name) and PlayerManager.user_data.has(stat_name):
		var previous = PlayerManager.user_data.get(stat_name, NAN)
		PlayerManager.user_data[stat_name] = value
		if previous != value:
			stat_changed.emit(stat_name, value)
			_emit_stat_callbacks(stat_name, value)
		return

	var previous = base_stats.get(stat_name, NAN)
	base_stats[stat_name] = value
	if previous != value:
		_recalculate_stat_and_dependents(stat_name)


func set_override(stat_name: String, value: Variant) -> void:
	var old_value = get_stat(stat_name)
	temporary_overrides[stat_name] = value
	if old_value != value:
		stat_changed.emit(stat_name, value)
		_emit_stat_callbacks(stat_name, value)
		_propagate_stat_changes(stat_name)


func clear_override(stat_name: String) -> void:
	if not temporary_overrides.has(stat_name):
		return
	var old_value = temporary_overrides[stat_name]
	temporary_overrides.erase(stat_name)
	_recalculate_stat(stat_name, false)
	_propagate_stat_changes(stat_name)
	var new_value = get_stat(stat_name)
	if old_value != new_value:
		stat_changed.emit(stat_name, new_value)
		_emit_stat_callbacks(stat_name, new_value)


func apply_temp_override(stat_name: String, value: Variant) -> void:
	set_override(stat_name, value)


func clear_temp_override(stat_name: String) -> void:
	clear_override(stat_name)


func reset() -> void:
	temporary_overrides.clear()
	_load_base_stats()
	_build_upgrade_cache()
	_build_dependents_map()
	recalculate_all_stats_once()


func get_save_data() -> Dictionary:
	return base_stats.duplicate(true)


func load_from_data(data: Dictionary) -> void:
	temporary_overrides.clear()
	_load_base_stats()
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			base_stats[key] = float(data[key])
	_build_upgrade_cache()
	_build_dependents_map()
	recalculate_all_stats_once()


func connect_to_stat(stat: String, target: Object, method: String) -> void:
	if !_stat_signal_map.has(stat):
		_stat_signal_map[stat] = []
	var cb := Callable(target, method)
	for existing in _stat_signal_map[stat]:
		if existing.get_object() == target and existing.get_method() == method:
			return
	_stat_signal_map[stat].append(cb)


func disconnect_from_stat(stat: String, target: Object, method: String) -> void:
	if _stat_signal_map.has(stat):
		_stat_signal_map[stat] = _stat_signal_map[stat].filter(
			func(cb): return cb.get_object() != target or cb.get_method() != method
		)


func register_stat(name: String, default_value: Variant) -> void:
	if base_stats.has(name):
		return
	base_stats[name] = default_value
	_recalculate_stat_and_dependents(name)


func get_upgrade_level(upgrade_id: String) -> int:
	## Convenience wrapper so that external code does not query
	## UpgradeManager directly when displaying upgrade levels.
	return UpgradeManager.get_level(upgrade_id)


# -- Recalculation -----------------------------------------------------------


func _on_upgrade_purchased(id: String, _level: int) -> void:
	var upgrade_data = UpgradeManager.get_upgrade(id)
	if upgrade_data == null:
		return
	for effect in upgrade_data.get("effects", []):
		var target = effect.get("target", "")
		if target != "":
			_recalculate_stat_and_dependents(target)


func _on_levels_changed() -> void:
	_build_upgrade_cache()
	_build_dependents_map()
	recalculate_all_stats_once()


func recalculate_all_stats_once() -> void:
	computed_stats.clear()
	var stats_to_recalc := base_stats.keys()
	for deps in stat_dependencies.values():
		for dep in deps:
			if dep not in stats_to_recalc:
				stats_to_recalc.append(dep)
	for stat_name in stats_to_recalc:
		_recalculate_stat(stat_name, false)
	for stat_name in derived_stats.keys():
		_recalculate_derived_stat(stat_name, false)


func _recalculate_stat_and_dependents(stat_name: String) -> void:
	if temporary_overrides.has(stat_name):
		return
	_recalculate_stat(stat_name)
	_propagate_stat_changes(stat_name)


func _recalculate_stat(stat: String, emit := true) -> void:
	if temporary_overrides.has(stat):
		return
	var previous = computed_stats.get(stat)
	var base_value = get_base_stat(stat, 0.0)
	var value: float = base_value
	var applied := false
	if stat_to_upgrades.has(stat):
		for effect_data in stat_to_upgrades[stat]:
			var upgrade_id = effect_data.get("id")
			var level: int = UpgradeManager.get_level(upgrade_id)
			if level <= 0:
				continue
			var effect: Dictionary = effect_data.get("effect")
			var eff_value: float = float(effect.get("value", 0.0))
			if effect.get("scale_with_level", true):
				eff_value *= level
			var op = effect.get("operation", "add")
			match op:
				"add":
					value += eff_value
					applied = true
				"mul":
					if not applied:
						value = get_base_stat(stat, 1.0)
						applied = true
					value *= eff_value
				"set":
					value = eff_value
					applied = true
				"add_formula":
					var formula: String = effect.get("value_formula", "")
					if formula == "":
						push_warning(
							"StatManager: missing value_formula for add_formula on stat '%s'" % stat
						)
					else:
						var vars: Dictionary = {
							"level": float(level),
							"current_value": value,
						}
						vars["current_%s" % stat] = value
						if stat == "attractiveness":
							vars["current_dime_status"] = value / 10.0
						var names: Array[String] = []
						var vals: Array = []
						for k in vars.keys():
							names.append(k)
							vals.append(vars[k])
						var expr := Expression.new()
						if expr.parse(formula, names) != OK:
							push_warning(
								(
									"StatManager: bad value_formula '%s' for stat '%s'"
									% [formula, stat]
								)
							)
						else:
							var result = expr.execute(vals)
							if typeof(result) in [TYPE_FLOAT, TYPE_INT]:
								value += float(result)
								applied = true
							else:
								push_warning(
									(
										"StatManager: value_formula for stat '%s' did not return number"
										% stat
									)
								)
				_:
					push_warning("StatManager: unknown operation '%s' for stat '%s'" % [op, stat])
	if value != previous:
		computed_stats[stat] = value
		if emit:
			stat_changed.emit(stat, value)
			_emit_stat_callbacks(stat, value)
	else:
		computed_stats[stat] = value


func _recalculate_derived_stat(stat: String, emit := true) -> void:
	if temporary_overrides.has(stat):
		return
	var previous = computed_stats.get(stat)
	var func_callable: Callable = derived_stats.get(stat)
	if func_callable.is_valid():
		var value = float(func_callable.call(computed_stats))
		computed_stats[stat] = value
		if emit and previous != value:
			stat_changed.emit(stat, value)
			_emit_stat_callbacks(stat, value)


func _propagate_stat_changes(stat: String, visited := {}) -> void:
	if visited.has(stat):
		return
	visited[stat] = true
	var deps: Array = _dependents.get(stat, [])
	for d in deps:
		_recalculate_derived_stat(d)
		_propagate_stat_changes(d, visited)


func _build_upgrade_cache() -> void:
	stat_to_upgrades.clear()
	for upgrade_id in UpgradeManager.upgrades.keys():
		var upgrade_data = UpgradeManager.get_upgrade(upgrade_id)
		for effect in upgrade_data.get("effects", []):
			var target = effect.get("target", "")
			if target == "":
				continue
			if !stat_to_upgrades.has(target):
				stat_to_upgrades[target] = []
			stat_to_upgrades[target].append({"id": upgrade_id, "effect": effect})


func _build_dependents_map() -> void:
	_dependents.clear()
	for derived in stat_dependencies.keys():
		var deps: Array = stat_dependencies[derived]
		for dep in deps:
			if !_dependents.has(dep):
				_dependents[dep] = []
			_dependents[dep].append(derived)
			_dependents[dep].append(derived)


func _emit_stat_callbacks(stat: String, value: Variant) -> void:
	if value == null:
		push_warning("StatManager: Tried to emit callback for '%s' with null value" % stat)
		return
	var param = value
	var t := typeof(value)
	if t == TYPE_INT or t == TYPE_FLOAT:
		param = float(value)
	if _stat_signal_map.has(stat):
		var callbacks: Array = _stat_signal_map[stat]
		for cb in callbacks.duplicate():
			if not is_instance_valid(cb.get_object()):
				callbacks.erase(cb)
				continue
			cb.call(param)
