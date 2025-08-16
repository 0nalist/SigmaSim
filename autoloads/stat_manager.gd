extends Node
## StatManager is the single authority for every gameplay statistic.  All
## systems should use this class to query or modify stats rather than reaching
## into other managers.  The manager supports permanent base values, upgrade
## effects, and temporary overrides used by buffs or special events.

signal stat_changed(stat: String, value: float)

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
var derived_stats: Dictionary = {}


func _ready() -> void:
		_load_base_stats()
		UpgradeManager.upgrade_purchased.connect(_on_upgrades_changed)
		if UpgradeManager.has_signal("levels_changed"):
				UpgradeManager.levels_changed.connect(_on_upgrades_changed)
		_recalculate_all()


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

func get_stat(stat_name: String, default := 0.0) -> float:
		if temporary_overrides.has(stat_name):
				return temporary_overrides[stat_name]
		return computed_stats.get(stat_name, base_stats.get(stat_name, default))


func get_all_stats() -> Dictionary:
		var result := computed_stats.duplicate(true)
		for key in temporary_overrides.keys():
				result[key] = temporary_overrides[key]
		return result


func get_base_stat(stat_name: String, default := 0.0) -> float:
		return base_stats.get(stat_name, default)


func set_base_stat(stat_name: String, value: float) -> void:
	var previous = base_stats.get(stat_name, NAN)
	base_stats[stat_name] = value
	if previous != value:
			_recalculate_all()


func apply_temp_override(stat_name: String, value: float) -> void:
		var old_value := get_stat(stat_name)
		temporary_overrides[stat_name] = value
		if old_value != value:
				stat_changed.emit(stat_name, value)
				_emit_stat_callbacks(stat_name, value)


func clear_temp_override(stat_name: String) -> void:
	if not temporary_overrides.has(stat_name):
			return
	var old_value = temporary_overrides[stat_name]
	temporary_overrides.erase(stat_name)
	var new_value := get_stat(stat_name)
	if old_value != new_value:
			stat_changed.emit(stat_name, new_value)
			_emit_stat_callbacks(stat_name, new_value)


func reset() -> void:
		temporary_overrides.clear()
		_load_base_stats()
		_recalculate_all()


func connect_to_stat(stat: String, target: Object, method: String) -> void:
		if !_stat_signal_map.has(stat):
				_stat_signal_map[stat] = []
		_stat_signal_map[stat].append(Callable(target, method))


func disconnect_from_stat(stat: String, target: Object, method: String) -> void:
		if _stat_signal_map.has(stat):
				_stat_signal_map[stat] = _stat_signal_map[stat].filter(
						func(cb):
								return cb.get_object() != target or cb.get_method() != method
				)


func register_stat(name: String, default_value: float) -> void:
		if base_stats.has(name):
				return
		base_stats[name] = default_value
		_recalculate_all()


func get_upgrade_level(upgrade_id: String) -> int:
		## Convenience wrapper so that external code does not query
		## UpgradeManager directly when displaying upgrade levels.
		return UpgradeManager.get_level(upgrade_id)


# -- Recalculation -----------------------------------------------------------

func _on_upgrades_changed(_id: String = "", _level: int = 0) -> void:
		_recalculate_all()


func _recalculate_all() -> void:
		var previous_final := get_all_stats()

		computed_stats = base_stats.duplicate(true)

		for upgrade_id in UpgradeManager.player_levels.keys():
				var level: int = UpgradeManager.get_level(upgrade_id)
				if level <= 0:
						continue
				var upgrade_data = UpgradeManager.get_upgrade(upgrade_id)
				if upgrade_data == null:
						continue
				for effect in upgrade_data.get("effects", []):
						_apply_effect(effect, level)

		# Apply derived stat functions last so they can depend on computed_stats
		for stat_name in derived_stats.keys():
				var func_callable: Callable = derived_stats[stat_name]
				if func_callable.is_valid():
						computed_stats[stat_name] = float(func_callable.call(computed_stats))

		var new_final := get_all_stats()
		var keys := previous_final.keys()
		for key in new_final.keys():
				if not keys.has(key):
						keys.append(key)

		for stat_name in keys:
				var old_value = previous_final.get(stat_name)
				var new_value = new_final.get(stat_name)
				if old_value != new_value:
					stat_changed.emit(stat_name, new_value)
					_emit_stat_callbacks(stat_name, new_value)


func _apply_effect(effect: Dictionary, level: int) -> void:
	var target = effect.get("target", "")
	if target == "":
			push_warning("StatManager: effect missing target")
			return

	var value := float(effect.get("value", 0.0))
	if effect.get("scale_with_level", true):
			value *= level

	var operation = effect.get("operation", "add")
	var current = computed_stats.get(target, base_stats.get(target, 0.0))

	match operation:
			"add":
					computed_stats[target] = current + value
			"mul":
					if not computed_stats.has(target):
							current = base_stats.get(target, 1.0)
					computed_stats[target] = current * value
			"set":
					computed_stats[target] = value
			_:
					push_warning("StatManager: unknown operation '%s' for stat '%s'" % [operation, target])


func _emit_stat_callbacks(stat: String, value: Variant) -> void:
	if value == null:
		push_warning("StatManager: Tried to emit callback for '%s' with null value" % stat)
		return
	var as_float := float(value)
	if _stat_signal_map.has(stat):
		for cb in _stat_signal_map[stat]:
			if is_instance_valid(cb.get_object()):
				cb.call(as_float)
