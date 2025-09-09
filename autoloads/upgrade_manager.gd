extends Node
## UpgradeManager: loads upgrade definitions from JSON and tracks player upgrade levels.
##
## All upgrades live in `res://upgrades/` (vanilla) and `user://mods/upgrades/`.
## Mod files override vanilla files by id. Each upgrade is a Dictionary with keys:
## - id: String unique identifier
## - name, description: display strings
## - systems: Array of system tags (e.g. "Workforce")
## - dependencies: Array of upgrade ids required before unlocking
## - max_level: -1 for unlimited
## - repeatable: if false, upgrade can only be purchased once
## - cost_per_level: Dictionary or Array of Dictionary[String, float]
## - scale_by_formula: bool
## - cost_formula: String or Dictionary[String, String] evaluated with variables
##               `level`, `base_cost`, and `prev_cost`
## - effects: Array of effect Dictionaries {target, operation, value, scale_with_level?}
##
## UpgradeManager only handles loading, costs and purchasing. Stat application
## is handled by StatManager, which listens to our signals.

signal upgrade_purchased(id: String, new_level: int)
signal levels_changed ## Emitted when levels are loaded or reset

var upgrades: Dictionary = {}            # id -> upgrade data
var player_levels: Dictionary = {}       # id -> purchased count
var cooldowns: Dictionary = {}           # id -> {"start": int, "base": float}
var next_cost_cache: Dictionary = {}     # id -> {"level": int, "cost": Dictionary}

const EXPECTED_KEYS: Array = [
	"id", "name", "description", "effects", "systems", "dependencies",
	"max_level", "repeatable", "cooldown", "cost_per_level", "scale_by_formula", "cost_formula"
]

func _ready() -> void:
	StatManager.register_flex_stat("ex")
	load_all_upgrades()

# --- Helper ---------------------------------------------------------

func _as_float(val: Variant, default_value: float = 0.0) -> float:
	var t: int = typeof(val)
	if t == TYPE_FLOAT:
		return float(val)
	if t == TYPE_INT:
		return float(val)
	if t == TYPE_OBJECT:
		if val == null:
			return default_value
		if val is FlexNumber:
			var fn: FlexNumber = val
			return fn.to_float()
		var obj: Object = val
		if obj.has_method("to_float"):
			var out_val: Variant = obj.call("to_float")
			var ot: int = typeof(out_val)
			if ot == TYPE_FLOAT or ot == TYPE_INT:
				return float(out_val)
		return default_value
	return default_value

## --- Loading -------------------------------------------------------

func load_all_upgrades() -> void:
	upgrades.clear()
	next_cost_cache.clear()
	_load_dir("res://data/upgrades", false)
	_load_dir("user://mods/upgrades", true)
	Events.register_upgrade_signals(upgrades.keys())
	emit_signal("levels_changed")

func reload_upgrades() -> void:
	load_all_upgrades()

func _load_dir(path: String, is_mod: bool) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_warning("UpgradeManager: missing directory %s" % path)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			file_name = dir.get_next()
			continue
		if file_name.get_extension().to_lower() != "json":
			file_name = dir.get_next()
			continue
		var file_path: String = path.path_join(file_name)
		var text: String = FileAccess.get_file_as_string(file_path)
		var data: Variant = JSON.parse_string(text)
		if typeof(data) != TYPE_DICTIONARY:
			push_error("UpgradeManager: invalid JSON in %s" % file_path)
			file_name = dir.get_next()
			continue
		var dict: Dictionary = data
		if not _validate_upgrade(dict, file_path):
			file_name = dir.get_next()
			continue
		var id: String = String(dict["id"])
		if is_mod and upgrades.has(id):
			push_warning("UpgradeManager: mod overwriting upgrade '%s'" % id)
		upgrades[id] = dict
		file_name = dir.get_next()
	dir.list_dir_end()

func _validate_upgrade(data: Dictionary, file_path: String) -> bool:
	var id: String = String(data.get("id", ""))
	if id == "":
		push_warning("UpgradeManager: upgrade missing id in %s" % file_path)
		return false
	for key in data.keys():
		if key not in EXPECTED_KEYS:
			push_warning("UpgradeManager: unknown field '%s' in %s" % [key, id])
	if not data.has("cost_per_level"):
		push_warning("UpgradeManager: upgrade '%s' missing cost_per_level" % id)
		data["cost_per_level"] = {}
	var cpl: Variant = data["cost_per_level"]
	if typeof(cpl) == TYPE_ARRAY:
		var arr: Array = cpl
		for i in arr.size():
			if typeof(arr[i]) != TYPE_DICTIONARY:
				push_error("UpgradeManager: cost_per_level entry %d must be Dictionary in %s" % [i, id])
				arr[i] = {}
		data["cost_per_level"] = arr
	elif typeof(cpl) != TYPE_DICTIONARY:
		push_error("UpgradeManager: cost_per_level must be Array or Dictionary in %s" % id)
		data["cost_per_level"] = {}

	if data.get("scale_by_formula", false):
		var formula: Variant = data.get("cost_formula")
		var ft: int = typeof(formula)
		if ft != TYPE_STRING and ft != TYPE_DICTIONARY:
			push_error("UpgradeManager: cost_formula for %s must be String or Dictionary" % id)

		if not data.has("repeatable"):
			data["repeatable"] = true
		if not data.has("cooldown"):
			data["cooldown"] = -1

	return true

## --- Query helpers -------------------------------------------------

func get_upgrade(id: String) -> Dictionary:
	return upgrades.get(id, {})

func get_all_upgrades() -> Array:
	return upgrades.values()

func get_level(id: String) -> int:
	return int(player_levels.get(id, 0))

func is_locked(id: String) -> bool:
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return true
	var deps: Array = upgrade.get("dependencies", [])
	for dep in deps:
		var dep_id: String = String(dep)
		if get_level(dep_id) <= 0:
			return true
	return false

func get_upgrades_for_system(system: String, include_locked: bool = false) -> Array:
	var target: String = system.to_lower()
	var result: Array = []
	for upgrade in upgrades.values():
		var up: Dictionary = upgrade
		var systems: Array = up.get("systems", [])
		for sys in systems:
			if typeof(sys) == TYPE_STRING and String(sys).to_lower() == target:
				var id: String = String(up.get("id", ""))
				if include_locked or not is_locked(id):
					result.append(up)
				break
	return result

func get_upgrade_layers(list: Array) -> Array:
	var remaining: Array = list.duplicate()
	var layers: Array = []
	var placed_ids: Dictionary = {}
	var max_iterations: int = 1000
	while not remaining.is_empty() and max_iterations > 0:
		var current_layer: Array = []
		for upgrade in remaining:
			var up: Dictionary = upgrade
			var deps: Array = up.get("dependencies", [])
			var all_met: bool = true
			for dep in deps:
				var dep_id: String = String(dep)
				if not placed_ids.has(dep_id):
					all_met = false
					break
			if all_met:
				current_layer.append(up)
		if current_layer.is_empty():
			var rem_ids: Array = remaining.map(func(u):
				var d: Dictionary = u
				return d.get("id")
			)
			push_error("UpgradeManager: Cyclical or invalid dependency in upgrade tree! Remaining: %s" % rem_ids)
			break
		layers.append(current_layer)
		for upgrade in current_layer:
			var up2: Dictionary = upgrade
			var uid: String = String(up2.get("id", ""))
			placed_ids[uid] = true
			remaining.erase(up2)
		max_iterations -= 1
	if max_iterations <= 0:
		push_error("UpgradeManager: Hit max iterations in get_upgrade_layers (possible infinite loop)")
	return layers

## --- Costing -------------------------------------------------------

func max_level(id: String) -> int:
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return -1
	if not is_repeatable(id):
		return 1

	var m: Variant = upgrade.get("max_level")
	if m == null:
		return -1

	var mt: int = typeof(m)
	if mt == TYPE_STRING:
		var s: String = String(m).strip_edges()
		if s == "":
			return -1
		var parsed: int = s.to_int()
		if parsed != 0:
			return parsed
		return -1

	if mt == TYPE_INT or mt == TYPE_FLOAT:
		return int(m)

	return -1

func is_repeatable(id: String) -> bool:
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return false
	return bool(upgrade.get("repeatable", true))

func get_cost_for_next_level(id: String) -> Dictionary:
	var next_level: int = get_level(id) + 1
	var cached: Variant = next_cost_cache.get(id)
	if cached != null:
		var cdict: Dictionary = cached
		if int(cdict.get("level", 0)) == next_level:
			return cdict.get("cost", {})
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return {}
	var cost: Dictionary = _get_cost_for_level(upgrade, next_level)
	next_cost_cache[id] = {"level": next_level, "cost": cost}
	return cost

func _get_cost_for_level(upgrade: Dictionary, level: int) -> Dictionary:
	var base_cost: Dictionary = _get_base_cost(upgrade, level)

	if bool(upgrade.get("scale_by_formula", false)):
		var prev_cost: Dictionary = {}
		if level > 1:
			prev_cost = _get_cost_for_level(upgrade, level - 1)

		var formula: Variant = upgrade.get("cost_formula")
		var ft: int = typeof(formula)
		var result: Dictionary = {}

		if ft == TYPE_DICTIONARY:
			var fdict: Dictionary = formula
			for currency in base_cost.keys():
				var cname: String = String(currency)
				var expr_str: String = str(fdict.get(cname, ""))
				if expr_str == "":
					result[cname] = base_cost.get(cname, 0.0)
					continue
				var expr: Expression = Expression.new()
				if expr.parse(expr_str, ["level", "base_cost", "prev_cost"]) != OK:
					push_error("UpgradeManager: bad cost formula for %s (%s)" % [upgrade.get("id"), cname])
					result[cname] = base_cost.get(cname, 0.0)
					continue
				var val: Variant = expr.execute([level, base_cost, prev_cost])
				if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
					result[cname] = float(val)
				else:
					push_error("UpgradeManager: cost formula for %s (%s) didn't return number" % [upgrade.get("id"), cname])
					result[cname] = base_cost.get(cname, 0.0)
			return result

		if ft == TYPE_STRING:
			var expr2: Expression = Expression.new()
			var fstr: String = String(formula)
			if expr2.parse(fstr, ["level", "base_cost", "prev_cost"]) != OK:
				push_error("UpgradeManager: bad cost formula for %s" % upgrade.get("id"))
				return base_cost
			var val2: Variant = expr2.execute([level, base_cost, prev_cost])
			if typeof(val2) == TYPE_DICTIONARY:
				return val2
			push_error("UpgradeManager: cost formula for %s must return Dictionary" % upgrade.get("id"))
			return base_cost

		push_error("UpgradeManager: cost_formula missing for %s" % upgrade.get("id"))
		return base_cost

	return base_cost

func _get_base_cost(upgrade: Dictionary, level: int) -> Dictionary:
	var cpl: Variant = upgrade.get("cost_per_level", {})
	if typeof(cpl) == TYPE_ARRAY:
		var arr: Array = cpl
		if arr.size() == 0:
			return {}
		if level - 1 < arr.size():
			var entry: Variant = arr[level - 1]
			if typeof(entry) == TYPE_DICTIONARY:
				return entry
			return {}
		var last_entry: Variant = arr[-1]
		if typeof(last_entry) == TYPE_DICTIONARY:
			return last_entry
		return {}
	if typeof(cpl) == TYPE_DICTIONARY:
		return cpl
	return {}

## --- Purchasing ----------------------------------------------------

func _get_currency_amount(currency: String) -> float:
	if currency == "cash":
		return float(PortfolioManager.cash)
	if StatManager.FLEX_STATS.has(currency):
		var val: Variant = StatManager.get_stat(currency)
		return _as_float(val, 0.0)
	return float(PortfolioManager.get_crypto_amount(currency))

func _deduct_currency(currency: String, amount: float, credit_only: bool = false) -> bool:
	if currency == "cash":
		return PortfolioManager.attempt_spend(
			amount,
			PortfolioManager.CREDIT_REQUIREMENTS["upgrades"],
			false,
			credit_only
		)

	if StatManager.FLEX_STATS.has(currency):
		var val: Variant = StatManager.get_stat(currency)
		if typeof(val) == TYPE_OBJECT and val is FlexNumber:
			var fn: FlexNumber = val
			if fn.to_float() < amount:
				return false
			fn.subtract(amount)
			StatManager.set_base_stat(currency, fn)
		else:
			var f: float = _as_float(val, 0.0)
			if f < amount:
				return false
			f -= amount
			StatManager.set_base_stat(currency, f)

		StatpopManager.spawn(
			"-%s %s" % [NumberFormatter.smart_format(amount), currency.to_upper()],
			get_viewport().get_mouse_position(),
			"click",
			Color.YELLOW
		)
		return true

	if PortfolioManager.get_crypto_amount(currency) < amount:
		return false
	PortfolioManager.add_crypto(currency, -amount)
	StatpopManager.spawn(
		"-%s %s" % [NumberFormatter.smart_format(amount), currency],
		get_viewport().get_mouse_position(),
		"click",
		Color.YELLOW
	)
	return true

func can_purchase(id: String) -> bool:
	if is_locked(id):
		return false
	if get_cooldown_remaining(id) > 0.0:
		return false
	var maxv: int = max_level(id)
	if maxv != -1 and get_level(id) >= maxv:
		return false

	var cost: Dictionary = get_cost_for_next_level(id)
	for currency in cost.keys():
		var amount_variant: Variant = cost[currency]
		var amount: float = 0.0
		if typeof(amount_variant) == TYPE_FLOAT or typeof(amount_variant) == TYPE_INT:
			amount = float(amount_variant)
		else:
			continue

		if currency == "cash":
			if PortfolioManager.can_pay_with_cash(amount):
				continue
			var remainder: float = amount - float(PortfolioManager.cash)
			if remainder <= 0.0:
				continue
			var required_score: int = int(PortfolioManager.CREDIT_REQUIREMENTS.get("upgrades", 0))
			if int(PortfolioManager.credit_score) < required_score:
				return false
			if not PortfolioManager.can_pay_with_credit(remainder):
				return false

		elif StatManager.FLEX_STATS.has(currency):
			var val: Variant = StatManager.get_stat(currency)
			if _as_float(val, 0.0) < amount:
				return false

		else:
			if PortfolioManager.get_crypto_amount(currency) < amount:
				return false

	return true

func purchase(id: String, credit_only: bool = false) -> bool:
	if not can_purchase(id):
		return false
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return false
	var cost: Dictionary = get_cost_for_next_level(id)
	for currency in cost.keys():
		var amt_v: Variant = cost[currency]
		var amt_f: float = 0.0
		if typeof(amt_v) == TYPE_FLOAT or typeof(amt_v) == TYPE_INT:
			amt_f = float(amt_v)
		else:
			continue
		if not _deduct_currency(currency, amt_f, credit_only):
			return false

	var level: int = get_level(id) + 1
	player_levels[id] = level

	var cd: float = float(upgrade.get("cooldown", -1))
	if cd > 0.0:
		cooldowns[id] = {"start": TimeManager.total_minutes_elapsed, "base": cd}
	elif cooldowns.has(id):
		cooldowns.erase(id)

	print("UpgradeManager.purchase: emitting upgrade_purchased for", id, "level", level)
	upgrade_purchased.emit(id, level)
	Events.emit_upgrade_purchased(id, level)
	return true

func get_cooldown_remaining(id: String) -> float:
	if not cooldowns.has(id):
		return 0.0
	var data: Dictionary = cooldowns[id]
	var base: float = float(data.get("base", -1))
	if base <= 0.0:
		cooldowns.erase(id)
		return 0.0

	var start: int = int(data.get("start", TimeManager.total_minutes_elapsed))
	var elapsed: int = TimeManager.total_minutes_elapsed - start

	var mult_val: Variant = StatManager.get_stat("upgrade_cooldown_multiplier", 1.0)
	var mult: float = _as_float(mult_val, 1.0)

	var remaining: float = base * mult - float(elapsed)
	if remaining <= 0.0:
		cooldowns.erase(id)
		return 0.0
	return remaining

## --- Save / Load ---------------------------------------------------

func get_save_data() -> Dictionary:
	return {
		"levels": player_levels.duplicate(true),
		"cooldowns": cooldowns.duplicate(true)
	}

func load_from_data(data: Dictionary) -> void:
	if data.has("levels"):
		player_levels = data.get("levels", {}).duplicate(true)
		cooldowns = data.get("cooldowns", {}).duplicate(true)
	else:
		player_levels = data.duplicate(true)
		cooldowns.clear()
	emit_signal("levels_changed")

func reset() -> void:
	player_levels.clear()
	cooldowns.clear()
	emit_signal("levels_changed")
